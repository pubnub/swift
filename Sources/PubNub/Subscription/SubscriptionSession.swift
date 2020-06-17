//
//  SubscriptionSession.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

// swiftlint:disable:next type_body_length
public class SubscriptionSession {
  var privateListeners: WeakSet<ListenerType> = WeakSet([])

  public let uuid = UUID()
  let longPollingSession: SessionReplaceable
  let configuration: SubscriptionConfiguration
  let sessionStream: SessionListener

  /// PSV2 feature to subscribe with a custom filter expression.
  public var filterExpression: String?

  var messageCache = [SubscribeMessagePayload?].init(repeating: nil, count: 100)
  var presenceTimer: Timer?

  /// Session used for performing request/response REST calls
  let nonSubscribeSession: SessionReplaceable

  // These allow for better tracking of outstanding subscribe loop request status
  var request: RequestReplaceable?

  let responseQueue: DispatchQueue

  var previousTokenResponse: SubscribeCursor?

  public var subscribedChannels: [String] {
    return internalState.lockedRead { $0.subscribedChannels }
  }

  public var subscribedChannelGroups: [String] {
    return internalState.lockedRead { $0.subscribedGroups }
  }

  public var subscriptionCount: Int {
    return internalState.lockedRead { $0.totalSubscribedCount }
  }

  public private(set) var connectionStatus: ConnectionStatus {
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
        notify { $0.emitDidReceiveBatch(subscription: [.connectionStatusChanged(newValue)]) }
      }
    }
  }

  var internalState = Atomic<SubscriptionState>(SubscriptionState())

  internal init(
    configuration: SubscriptionConfiguration,
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

    sessionStream.didRetryRequest = { _ in
      self.connectionStatus = .reconnecting
    }

    sessionStream.sessionDidReceiveChallenge = { _, _ in
      if self.connectionStatus == .reconnecting {
        // Delay time for server to process connection after TLS handshake
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.05) {
          self.connectionStatus = .connected
        }
      }
    }
  }

  deinit {
    PubNub.log.debug("SubscriptionSession Destroyed")
    longPollingSession.invalidateAndCancel()
    nonSubscribeSession.invalidateAndCancel()
    // Poke the session factory to clean up nil values
    SubscribeSessionFactory.shared.sessionDestroyed()
  }

  // MARK: - Subscription Loop

  /// Subscribe to channels and/or channel groups
  ///
  /// - Parameters:
  ///   - to: List of channels to subscribe on
  ///   - and: List of channel groups to subscribe on
  ///   - at: The timetoken to subscribe with
  ///   - withPresence: If true it also subscribes to presence events on the specified channels.
  ///   - setting: The object containing the state for the channel(s).
  public func subscribe(
    to channels: [String],
    and groups: [String] = [],
    at cursor: SubscribeCursor? = nil,
    withPresence: Bool = false
  ) {
    if channels.isEmpty, groups.isEmpty {
      return
    }

    let channelObject = channels.map { PubNubChannel(id: $0, withPresence: withPresence) }
    let groupObjects = groups.map { PubNubChannel(id: $0, withPresence: withPresence) }

    // Don't attempt to start subscription if there are no changes
    let subscribeChange = internalState.lockedWrite { state -> SubscriptionChangeEvent in

      let newChannels = channelObject.filter { state.channels.insert($0) }
      let newGroups = groupObjects.filter { state.groups.insert($0) }

      return .subscribed(channels: newChannels, groups: newGroups)
    }

    if subscribeChange.didChange {
      notify { $0.emitDidReceiveBatch(subscription: [.subscriptionChanged(subscribeChange)]) }
    }

    if subscribeChange.didChange || !connectionStatus.isActive {
      reconnect(at: cursor)
    }
  }

  /// Reconnect a disconnected subscription stream
  /// - parameter timetoken: The timetoken to subscribe with
  public func reconnect(at cursor: SubscribeCursor? = nil) {
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
  public func disconnect() {
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
    let router = SubscribeRouter(.subscribe(channels: channels, groups: groups, timetoken: cursor?.timetoken,
                                            region: cursor?.region.description,
                                            heartbeat: configuration.durationUntilTimeout,
                                            filter: filterExpression),
                                 configuration: configuration)

    // Cancel previous request before starting new one
    stopSubscribeLoop(.longPollingRestart)

    // Will compre this in the error response to see if we need to restart
    let nextSubscribe = longPollingSession
      .request(with: router, requestOperator: configuration.automaticRetry)
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

            listener.emitDidReceiveBatch(subscription: [.subscriptionChanged(
              .responseHeader(channels: pubnubChannels.values.map { $0 }, groups: pubnubGroups.values.map { $0 },
                              previous: cursor, next: response.payload.cursor)
            )])
          }

          // Attempt to detect missed messages due to queue overflow
          if response.payload.messages.count >= 100 {
            self?.notify {
              $0.emitDidReceiveBatch(subscription: [
                .subscribeError(PubNubError(.messageCountExceededMaximum,
                                            router: router,
                                            affected: [.subscribe(response.payload.cursor)]))
              ])
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
            .map { message -> SubscriptionEvent in // Decode and eventify
              switch message.messageType {
              case .message:
                return .messageReceived(PubNubMessageBase(from: message))
              case .signal:
                return .signalReceived(PubNubMessageBase(from: message))
              case .object:
                guard let objectAction = try? message.payload.decode(SubscribeObjectMetadataPayload.self) else {
                  return .messageReceived(PubNubMessageBase(from: message))
                }
                return objectAction.subscribeEvent
              case .messageAction:
                guard let messageAction = PubNubMessageActionBase(from: message),
                  let actionEventString = message.payload[rawValue: "event"] as? String,
                  let actionEvent = SubscribeMessageActionPayload.Action(rawValue: actionEventString)
                else {
                  return .messageReceived(PubNubMessageBase(from: message))
                }

                switch actionEvent {
                case .added:
                  return .messageActionAdded(messageAction)
                case .removed:
                  return .messageActionRemoved(messageAction)
                }
              case .presence:
                guard let presence = PubNubPresenceChangeBase(from: message) else {
                  return .messageReceived(PubNubMessageBase(from: message))
                }

                return .presenceChanged(presence)
              }
            }

          self?.notify { $0.emitDidReceiveBatch(subscription: events) }

          self?.previousTokenResponse = response.payload.cursor

          // Repeat the request
          self?.performSubscribeLoop(at: response.payload.cursor)
        case let .failure(error):
          self?.notify { [unowned self] in
            $0.emitDidReceiveBatch(
              subscription: [.subscribeError(PubNubError.event(error, router: self?.request?.router))]
            )
          }

          if error.pubNubError?.reason == .clientCancelled || error.pubNubError?.reason == .longPollingRestart {
            if self?.subscriptionCount == 0 {
              self?.connectionStatus = .disconnected
            } else if self?.request?.requestID == nextSubscribe.requestID {
              // No new request has been created so we'll reconnect here
              self?.reconnect(at: self?.previousTokenResponse)
            }
          } else if let cursor = error.pubNubError?.affected.findFirst(by: PubNubError.AffectedValue.subscribe) {
            self?.previousTokenResponse = cursor

            // Repeat the request
            self?.performSubscribeLoop(at: cursor)
          } else {
            self?.connectionStatus = .disconnectedUnexpectedly
          }
        }
      }
  }

  // MARK: - Unsubscribe

  /// Unsubscribe from channels and/or channel groups
  ///
  /// - Parameters:
  ///   - from: List of channels to unsubscribe from
  ///   - and: List of channel groups to unsubscribe from
  ///   - presenceOnly: If true, it only unsubscribes from presence events on the specified channels.
  public func unsubscribe(from channels: [String], and groups: [String] = [], presenceOnly: Bool = false) {
    // Update Channel List
    let subscribeChange = internalState.lockedWrite { state -> SubscriptionChangeEvent in
      if presenceOnly {
        let presenceChannelsRemoved = channels.compactMap { state.channels.unsubscribePresence($0) }
        let presenceGroupsRemoved = groups.compactMap { state.groups.unsubscribePresence($0) }

        return .unsubscribed(channels: presenceChannelsRemoved, groups: presenceGroupsRemoved)
      } else {
        let removedChannels = channels.compactMap { state.channels.removeValue(forKey: $0) }
        let removedGroups = groups.compactMap { state.groups.removeValue(forKey: $0) }

        return .unsubscribed(channels: removedChannels, groups: removedGroups)
      }
    }

    if subscribeChange.didChange {
      notify { $0.emitDidReceiveBatch(subscription: [.subscriptionChanged(subscribeChange)]) }
      // Call unsubscribe to cleanup remaining state items
      unsubscribeCleanup(subscribeChange: subscribeChange)
    }
  }

  /// Unsubscribe from all channels and channel groups
  public func unsubscribeAll() {
    // Remove All Channels & Groups
    let subscribeChange = internalState.lockedWrite { mutableState -> SubscriptionChangeEvent in

      let removedChannels = mutableState.channels
      mutableState.channels.removeAll(keepingCapacity: true)

      let removedGroups = mutableState.groups
      mutableState.groups.removeAll(keepingCapacity: true)

      return .unsubscribed(channels: removedChannels.map { $0.value }, groups: removedGroups.map { $0.value })
    }

    if subscribeChange.didChange {
      notify { $0.emitDidReceiveBatch(subscription: [.subscriptionChanged(subscribeChange)]) }
      // Call unsubscribe to cleanup remaining state items
      unsubscribeCleanup(subscribeChange: subscribeChange)
    }
  }

  func unsubscribeCleanup(subscribeChange: SubscriptionChangeEvent) {
    // Call Leave on channels/groups
    if !configuration.supressLeaveEvents {
      switch subscribeChange {
      case let .unsubscribed(channels, groups):
        presenceLeave(for: configuration.uuid,
                      on: channels.map { $0.id },
                      and: groups.map { $0.id }) { [weak self] result in
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
              $0.emitDidReceiveBatch(subscription: [.subscribeError(PubNubError.event(error, router: nil))])
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
}

extension SubscriptionSession: EventStreamEmitter {
  public typealias ListenerType = SubscriptionListener

  public var listeners: [ListenerType] {
    return privateListeners.allObjects
  }

  public func add(_ listener: ListenerType) {
    // Ensure that we cancel the previously attached token
    listener.token?.cancel()

    // Add new token to the listener
    listener.token = ListenerToken { [weak self] in
      self?.privateListeners.remove(listener)
    }
    privateListeners.update(listener)
  }

  public func notify(listeners closure: (ListenerType) -> Void) {
    listeners.forEach { closure($0) }
  }
}

extension SubscriptionSession: Hashable, CustomStringConvertible {
  public static func == (lhs: SubscriptionSession, rhs: SubscriptionSession) -> Bool {
    return lhs.uuid == rhs.uuid
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }

  public var description: String {
    return uuid.uuidString
  }

  // swiftlint:disable:next file_length
}
