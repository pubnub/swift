//
//  LegacySubscriptionSessionStrategy.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// swiftlint:disable:next type_body_length
class LegacySubscriptionSessionStrategy: SubscriptionSessionStrategy {
  let uuid = UUID()
  let longPollingSession: SessionReplaceable
  let sessionStream: SessionListener
  let responseQueue: DispatchQueue

  var configuration: PubNubConfiguration
  var listeners: WeakSet<BaseSubscriptionListener> = WeakSet([])
  var filterExpression: String?
  var messageCache = [SubscribeMessagePayload?].init(repeating: nil, count: 100)
  var presenceTimer: Timer?

  /// Session used for performing request/response REST calls
  let nonSubscribeSession: SessionReplaceable
  // These allow for better tracking of outstanding subscribe loop request status
  var request: RequestReplaceable?
  var previousTokenResponse: SubscribeCursor?

  var subscribedChannels: [String] {
    return internalState.lockedRead { $0.subscribedChannels }
  }

  var subscribedChannelGroups: [String] {
    return internalState.lockedRead { $0.subscribedGroups }
  }

  var subscriptionCount: Int {
    return internalState.lockedRead { $0.totalSubscribedCount }
  }

  private(set) var connectionStatus: ConnectionStatus {
    get {
      return internalState.lockedRead { $0.connectionState }
    }
    set {
      // Set internal state
      let (oldState, didTransition) = internalState.lockedWrite { state -> (ConnectionStatus, Bool) in
        let oldState = state.connectionState
        if oldState.canTransition(to: newValue) {
          state.connectionState = newValue
          return (oldState, true)
        }
        return (oldState, false)
      }

      // Update any listeners if value changed
      if oldState != newValue, didTransition {
        notify {
          $0.emit(subscribe: .connectionChanged(newValue))
        }
      }
    }
  }

  var internalState = Atomic<SubscriptionState>(SubscriptionState())

  internal init(
    configuration: PubNubConfiguration,
    network subscribeSession: SessionReplaceable,
    presenceSession: SessionReplaceable
  ) {
    self.configuration = configuration
    var mutableSession = subscribeSession

    filterExpression = configuration.filterExpression
    nonSubscribeSession = presenceSession

    responseQueue = DispatchQueue(label: "com.pubnub.subscription.response", qos: .default)
    sessionStream = SessionListener(queue: responseQueue)

    // Add listener to session
    mutableSession.sessionStream = sessionStream
    longPollingSession = mutableSession

    sessionStream.didRetryRequest = { [weak self] _ in
      self?.connectionStatus = .reconnecting
    }

    sessionStream.sessionDidReceiveChallenge = { [weak self] _, _ in
      if self?.connectionStatus == .reconnecting {
        // Delay time for server to process connection after TLS handshake
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.05) {
          self?.connectionStatus = .connected
        }
      }
    }
  }

  deinit {
    PubNub.log.debug("SubscriptionSession Destroyed")
    longPollingSession.invalidateAndCancel()
    nonSubscribeSession.invalidateAndCancel()
  }

  // MARK: - Subscription Loop

  func subscribe(
    to channels: [PubNubChannel],
    and groups: [PubNubChannel],
    at cursor: SubscribeCursor?
  ) {
    let subscribeChange = internalState.lockedWrite { state -> SubscriptionChangeEvent in
      .subscribed(
        channels: channels.filter { state.channels.insert($0) },
        groups: groups.filter { state.groups.insert($0) }
      )
    }
    if subscribeChange.didChange {
      notify { $0.emit(subscribe: .subscriptionChanged(subscribeChange)) }
    }
    if subscribeChange.didChange || !connectionStatus.isActive {
      reconnect(at: cursor)
    }
  }

  /// Reconnect a disconnected subscription stream
  /// - parameter timetoken: The timetoken to subscribe with
  func reconnect(at cursor: SubscribeCursor? = nil) {
    if !connectionStatus.isActive {
      connectionStatus = .connecting
      // Start subscribe loop
      performSubscribeLoop(at: cursor)
      // Start presence heartbeat
      registerHeartbeatTimer()
    } else {
      // Start subscribe loop
      performSubscribeLoop(at: cursor)
    }
  }

  /// Disconnect the subscription stream
  func disconnect() {
    stopSubscribeLoop(.clientCancelled)
    stopHeartbeatTimer()
  }

  @discardableResult
  func stopSubscribeLoop(_ reason: PubNubError.Reason) -> Bool {
    // Cancel subscription requests
    request?.cancel(PubNubError(reason, router: request?.router))
    return connectionStatus.isActive
  }

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  func performSubscribeLoop(at cursor: SubscribeCursor?) {
    let (channels, groups) = internalState.lockedWrite { state -> ([String], [String]) in
      (state.allSubscribedChannels, state.allSubscribedGroups)
    }
    // Don't start subscription if there no channels/groups
    if channels.isEmpty, groups.isEmpty {
      return
    }
    // Create Endpoing
    let router = SubscribeRouter(
      .subscribe(
        channels: channels, groups: groups, channelStates: [:],
        timetoken: cursor?.timetoken, region: cursor?.region.description,
        heartbeat: configuration.durationUntilTimeout, filter: filterExpression
      ), configuration: configuration
    )

    // Cancel previous request before starting new one
    stopSubscribeLoop(.longPollingRestart)

    // Will compare this in the error response to see if we need to restart
    let nextSubscribe = longPollingSession.request(
      with: router,
      requestOperator: configuration.automaticRetry?.retryOperator(for: .subscribe)
    )
    let currentSubscribeID = nextSubscribe.requestID

    request = nextSubscribe
    request?
      .validate()
      .response(on: .main, decoder: SubscribeDecoder()) { [weak self] result in
        switch result {
        case let .success(response):
          guard let strongSelf = self else {
            return
          }
          // Reset heartbeat timer
          self?.registerHeartbeatTimer()
          // Ensure that we're connected now the response has been processed
          self?.connectionStatus = .connected

          // Emit the header of the reponse
          self?.notify { listener in
            var pubnubChannels = [String: PubNubChannel]()
            channels.forEach {
              if $0.isPresenceChannelName {
                let channel = PubNubChannel(channel: $0)
                pubnubChannels[channel.id] = channel
              } else if pubnubChannels[$0] == nil {
                pubnubChannels[$0] = PubNubChannel(channel: $0)
              }
            }

            var pubnubGroups = [String: PubNubChannel]()
            groups.forEach {
              if $0.isPresenceChannelName {
                let group = PubNubChannel(channel: $0)
                pubnubGroups[group.id] = group
              } else if pubnubChannels[$0] == nil {
                pubnubGroups[$0] = PubNubChannel(channel: $0)
              }
            }

            listener.emit(subscribe: .responseReceived(
              SubscribeResponseHeader(
                channels: pubnubChannels.values.map { $0 },
                groups: pubnubGroups.values.map { $0 },
                previous: cursor,
                next: response.payload.cursor
              ))
            )
          }

          // Attempt to detect missed messages due to queue overflow
          if response.payload.messages.count >= 100 {
            self?.notify {
              $0.emit(subscribe: .errorReceived(PubNubError(
                .messageCountExceededMaximum,
                router: router,
                affected: [.subscribe(response.payload.cursor)]
              )))
            }
          }

          let events = response.payload.messages
            .filter { message in // Dedupe the message
              // Update Cache and notify if not a duplicate message
              if !strongSelf.messageCache.contains(message) {
                self?.messageCache.append(message)
                // Remove oldest value if we're at max capacity
                if strongSelf.messageCache.count >= 100 {
                  self?.messageCache.remove(at: 0)
                }
                return true
              }
              return false
            }

          self?.notify { $0.emit(batch: events) }
          self?.previousTokenResponse = response.payload.cursor

          // Repeat the request
          self?.performSubscribeLoop(at: response.payload.cursor)
        case let .failure(error):
          self?.notify { [unowned self] in
            $0.emit(subscribe:
                .errorReceived(PubNubError.event(error, router: self?.request?.router))
            )
          }
          if error.pubNubError?.reason == .clientCancelled || error.pubNubError?.reason == .longPollingRestart ||
              error.pubNubError?.reason == .longPollingReset {
            if self?.subscriptionCount == 0 {
              self?.connectionStatus = .disconnected
            } else if self?.request?.requestID == currentSubscribeID {
              // No new request has been created so we'll reconnect here
              self?.reconnect(at: self?.previousTokenResponse)
            }
          } else if let cursor = error.pubNubError?.affected.findFirst(by: PubNubError.AffectedValue.subscribe) {
            self?.previousTokenResponse = cursor
            // Repeat the request
            self?.performSubscribeLoop(at: cursor)
          } else {
            self?.connectionStatus = .disconnectedUnexpectedly(
              error.pubNubError ?? PubNubError(.unknown, underlying: error)
            )
          }
        }
      }
  }

  // MARK: - Unsubscribe

  func unsubscribeFrom(
    mainChannels: [PubNubChannel],
    presenceChannelsOnly: [PubNubChannel],
    mainGroups: [PubNubChannel],
    presenceGroupsOnly: [PubNubChannel]
  ) {
    let subscribeChange = internalState.lockedWrite { state -> SubscriptionChangeEvent in
      .unsubscribed(
        channels: mainChannels.compactMap {
          state.channels.removeValue(forKey: $0.id)
        } + presenceChannelsOnly.compactMap {
          state.channels.unsubscribePresence($0.id)
        },
        groups: mainGroups.compactMap {
          state.groups.removeValue(forKey: $0.id)
        } + presenceGroupsOnly.compactMap {
          state.groups.unsubscribePresence($0.id)
        }
      )
    }
    if subscribeChange.didChange {
      notify {
        $0.emit(subscribe: .subscriptionChanged(subscribeChange))
      }
      // Call unsubscribe to cleanup remaining state items
      unsubscribeCleanup(subscribeChange: subscribeChange)
    }
  }

  /// Unsubscribe from all channels and channel groups
  func unsubscribeAll() {
    // Remove All Channels & Groups
    let subscribeChange = internalState.lockedWrite { mutableState -> SubscriptionChangeEvent in

      let removedChannels = mutableState.channels
      mutableState.channels.removeAll(keepingCapacity: true)

      let removedGroups = mutableState.groups
      mutableState.groups.removeAll(keepingCapacity: true)

      return .unsubscribed(channels: removedChannels.map { $0.value }, groups: removedGroups.map { $0.value })
    }

    if subscribeChange.didChange {
      notify {
        $0.emit(subscribe: .subscriptionChanged(subscribeChange))
      }
      // Cancel previous subscribe request.
      stopSubscribeLoop(.longPollingReset)
      // Call unsubscribe to cleanup remaining state items
      unsubscribeCleanup(subscribeChange: subscribeChange)
    }
  }

  func unsubscribeCleanup(subscribeChange: SubscriptionChangeEvent) {
    // Call Leave on channels/groups
    if !configuration.supressLeaveEvents {
      switch subscribeChange {
      case let .unsubscribed(channels, groups):
        presenceLeave(
          for: configuration.uuid,
          on: channels.map { $0.id },
          and: groups.map { $0.id }
        ) { [weak self] result in
          switch result {
          case .success:
            if !channels.isEmpty {
              PubNub.log.info("Presence Leave Successful on channels \(channels.map { $0.id })")
            }
            if !groups.isEmpty {
              PubNub.log.info("Presence Leave Successful on groups \(groups.map { $0.id })")
            }
          case let .failure(error):
            self?.notify {
              $0.emit(subscribe: .errorReceived(PubNubError.event(error, router: nil)))
            }
          }
        }
      default:
        break
      }
    }

    // Reset all timetokens and regions if we've unsubscribed from all channels/groups
    if internalState.lockedRead({ $0.totalSubscribedCount == 0 }) {
      previousTokenResponse = nil
      disconnect()
    } else {
      reconnect(at: previousTokenResponse)
    }
  }

  private func notify(listeners closure: (BaseSubscriptionListener) -> Void) {
    listeners.allObjects.forEach { closure($0) }
  }
}
