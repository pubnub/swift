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
  let networkSession: SessionReplaceable
  let configuration: SubscriptionConfiguration
  let sessionStream: SessionListener

  var messageCache = [MessageResponse?].init(repeating: nil, count: 100)
  var presenceTimer: Timer?

  let responseQueue: DispatchQueue

  var currentTimetoken: Timetoken = 0
  var previousTokenResponse: TimetokenResponse?

  var subscribedChannels: Set<String> {
    return internalState.lockedRead { $0.nonPresenceChannels }
  }

  public private(set) var connectionStatus: ConnectionStatus {
    get {
      return internalState.lockedRead { $0.state }
    }
    set {
      // Set internal state
      let oldState = internalState.lockedWrite { state -> ConnectionStatus in
        let oldState = state.state
        state.state = newValue
        return oldState
      }

      // Update any listeners if value changed
      if oldState != newValue {
        notify { $0.emitDidReceive(subscription: .connectionStatusChanged(newValue)) }
      }
    }
  }

  var internalState = Atomic<SubscriptionSessionState>(SubscriptionSessionState())

  internal init(configuration: SubscriptionConfiguration, network session: SessionReplaceable) {
    self.configuration = configuration
    networkSession = session
    responseQueue = DispatchQueue(label: "com.pubnub.subscription.response", qos: .default)
    sessionStream = SessionListener(queue: responseQueue)
  }

  deinit {
    self.networkSession.invalidateAndCancel()
  }

  // MARK: - Subscription Loop

  public func subscribe(
    to channels: [String],
    and channelGroups: [String] = [],
    at timetoken: Timetoken = 0,
    withPresence: Bool = false,
    setting presenceState: [String: Codable] = [:]
  ) {
    if channels.isEmpty, channelGroups.isEmpty {
      return
    }

    // Don't attempt to start subscription if there are no changes
    let hasChanges = internalState.lockedWrite { mutableState -> Bool in
      let oldCount = mutableState.totalChannelCount

      mutableState.channels.update(with: channels)
      mutableState.channelGroups.update(with: channelGroups)
      if withPresence {
        mutableState.channels.update(with: channels.map { $0.presenceChannelName })
        mutableState.channelGroups.update(with: channelGroups.map { $0.presenceChannelName })
      }
      return oldCount != mutableState.totalChannelCount
    }

    // Create a mapping of the state to the subscribing groups
    var incomingState: ChannelPresenceState?
    if !presenceState.isEmpty {
      incomingState = ChannelPresenceState()
      channels.forEach { incomingState?[$0] = presenceState }
      channelGroups.forEach { incomingState?[$0] = presenceState }
    }

    if hasChanges || connectionStatus != .connected {
      reconnect(at: timetoken, setting: incomingState)
    }
  }

  public func reconnect(at timetoken: Timetoken, setting incomingState: ChannelPresenceState? = nil) {
    // Start subscription loop
    if !connectionStatus.isActive {
      connectionStatus = .connecting
    }

    // Start subscribe loop
    performSubscribeLoop(at: timetoken, setting: incomingState)

    // Start presence heartbeat
    registerHeartbeatTimer()
  }

  public func disconnect() {
    stopSubscribeLoop()
    stopHeartbeatTimer()

    // Update Connection State and Notify
    connectionStatus = .disconnected
  }

  @discardableResult
  func stopSubscribeLoop() -> Bool {
    // Cancel subscription requests
    networkSession.cancelAllTasks(with: PNError.requestCancelled(.unknown), for: .subscribe)
    return connectionStatus.isActive
  }

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  func performSubscribeLoop(at timetoken: Timetoken?, setting incomingState: ChannelPresenceState? = nil) {
    // Ensure we don't have multiple subscribe loops
    stopSubscribeLoop()

    let (channels, groups, storedState) = internalState
      .lockedWrite { mutableState -> ([String], [String], ChannelPresenceState?) in
        var subscribeState: ChannelPresenceState?

        if let incomingState = incomingState {
          mutableState.mergePresenceState(incomingState, removingEmpty: false, addingChannels: true)
          subscribeState = mutableState.presenceState
        } else if mutableState.presenceState.isEmpty {
          subscribeState = nil
        } else {
          subscribeState = mutableState.presenceState
        }

        return (mutableState.channels.allObjects,
                mutableState.channelGroups.allObjects,
                subscribeState)
      }

    // Don't start subscription if there no channels/groups
    if channels.isEmpty, groups.isEmpty {
      return
    }

    // Create Endpoing
    let router = PubNubRouter(configuration: configuration,
                              endpoint: .subscribe(channels: channels,
                                                   groups: groups,
                                                   timetoken: timetoken,
                                                   region: previousTokenResponse?.region.description,
                                                   state: storedState,
                                                   heartbeat: configuration.durationUntilTimeout,
                                                   filter: configuration.filterExpression))

    networkSession
      .request(with: router, requestOperator: configuration.automaticRetry)
      .validate()
      .response(decoder: SubscribeResponseDecoder()) { [weak self] result in
        switch result {
        case let .success(response):
          guard let strongSelf = self else {
            return
          }

          // Reset heartbeat timer
          self?.registerHeartbeatTimer()

          // Clean up Presence Channel State
          self?.internalState.lockedWrite { $0.cleanPresenceState() }

          // If we were in the process of connecting, notify connected
          if strongSelf.connectionStatus == .connecting {
            self?.connectionStatus = .connected
          }

          if response.payload.messages.count >= 100 {
            self?.notify {
              $0.emitDidReceive(subscription:
                .subscribeError(PNError.messageCountExceededMaximum(router.endpoint)))
            }
          }

          // Emit the event to the observers
          for message in response.payload.messages {
            let message = message

            if let presenceMessage = try? message.payload.decode(PresenceMessageResponse.self) {
              let senderToken = message.originTimetoken?.timetoken ?? message.timetoken

              let presenceEvent = PresenceEventPayload(
                channel: message.channel.trimmingPresenceChannelSuffix,
                subscriptionMatch: message.subscriptionMatch?.trimmingPresenceChannelSuffix,
                senderTimetoken: senderToken,
                presenceTimetoken: message.publishTimetoken.timetoken,
                metadata: message.metadata,
                event: presenceMessage.action,
                occupancy: presenceMessage.occupancy,
                join: presenceMessage.join,
                leave: presenceMessage.leave,
                timeout: presenceMessage.timeout,
                stateChange: presenceMessage.channelState
              )

              // If the state chage is for this user we should update our internal cache
              if presenceMessage.channelState.keys.contains(strongSelf.configuration.uuid) {
                strongSelf.internalState.lockedWrite { $0.mergePresenceState(presenceMessage.channelState) }
              }

              self?.notify { $0.emitDidReceive(subscription: .presenceChanged(presenceEvent)) }
            } else if message.messageType == .object {
              do {
                // Decode upper object payload
                let payload = try message.payload.decode(ObjectSubscribePayload.self)

                // Determine the event type
                switch (payload.type, payload.event) {
                case (.user, .update):
                  let event: UserEvent = try payload.data.decode(UserObject.self)
                  self?.notify { $0.emitDidReceive(subscription: .userUpdated(event)) }
                case (.user, .delete):
                  let event = try payload.data.decode(IdentifierEvent.self)
                  self?.notify { $0.emitDidReceive(subscription: .userDeleted(event)) }
                case (.space, .update):
                  let event: SpaceEvent = try payload.data.decode(SpaceObject.self)
                  self?.notify { $0.emitDidReceive(subscription: .spaceUpdated(event)) }
                case (.space, .delete):
                  let event = try payload.data.decode(IdentifierEvent.self)
                  self?.notify { $0.emitDidReceive(subscription: .spaceDeleted(event)) }
                case (.membership, .add):
                  let event = try payload.data.decode(MembershipEvent.self)
                  self?.notify { $0.emitDidReceive(subscription: .membershipAdded(event)) }
                case (.membership, .update):
                  let event = try payload.data.decode(MembershipEvent.self)
                  self?.notify { $0.emitDidReceive(subscription: .membershipUpdated(event)) }
                case (.membership, .delete):
                  let event: MembershipIdentifiable = try payload.data.decode(MembershipEvent.self)
                  self?.notify { $0.emitDidReceive(subscription: .membershipDeleted(event)) }
                default:
                  break
                }
              } catch {
                let error = PNError.endpointFailure(.malformedResponseBody,
                                                    response.endpoint,
                                                    response.request,
                                                    response.response)
                self?.notify { $0.emitDidReceive(subscription: .subscribeError(error)) }
              }
            } else {
              // Update Cache and notify if not a duplicate message
              if !strongSelf.messageCache.contains(message) {
                switch message.messageType {
                case .message:
                  self?.notify { $0.emitDidReceive(subscription: .messageReceived(message)) }
                case .signal:
                  self?.notify { $0.emitDidReceive(subscription: .signalReceived(message)) }
                default:
                  break
                }

                self?.messageCache.append(message)
              }

              // Remove oldest value if we're at max capacity
              if strongSelf.messageCache.count >= 100 {
                self?.messageCache.remove(at: 0)
              }
            }
          }

          self?.previousTokenResponse = response.payload.token
          self?.currentTimetoken = response.payload.token.timetoken

          // Repeat the request
          self?.performSubscribeLoop(at: strongSelf.currentTimetoken)
        case let .failure(error):
          if error.isCancellationError {
            self?.connectionStatus = .cancelled
          } else if let pubnubError = error.pubNubError {
            self?.connectionStatus = .disconnectedUnexpectedly
            self?.notify { $0.emitDidReceive(subscription: .subscribeError(pubnubError)) }
          } else {
            self?.connectionStatus = .disconnectedUnexpectedly
            self?.notify { $0.emitDidReceive(subscription:
              .subscribeError(PNError.unknownError(error, router.endpoint))) }
          }
        }
      }
  }

  // MARK: - Unsubscribe

  public func unsubscribe(from channels: [String], and channelGroups: [String] = []) {
    let loopStopped = stopSubscribeLoop()

    // Update Channel List
    let newCount = internalState.lockedWrite { mutableState -> Int in
      mutableState.channels.remove(contentsOf: channels)
      mutableState.channelGroups.remove(contentsOf: channelGroups)

      mutableState.channels.remove(contentsOf: channels.map { $0.presenceChannelName })
      mutableState.channelGroups.remove(contentsOf: channelGroups.map { $0.presenceChannelName })

      return mutableState.totalChannelCount
    }

    unsubscribeCleanup(channels: channels, groups: channelGroups, newCount: newCount, restart: loopStopped)
  }

  public func unsubscribeAll() {
    let loopStopped = stopSubscribeLoop()

    // Remove All Channels & Groups
    let (channels, groups) = internalState.lockedWrite { mutableState -> ([String], [String]) in
      let channels = mutableState.removeAllChannels()
      let groups = mutableState.removeAllChannelGroups()

      return (channels, groups)
    }

    // Call unsubscribe to cleanup remaining state items
    unsubscribeCleanup(channels: channels, groups: groups, newCount: 0, restart: loopStopped)
  }

  public func unsubscribeCleanup(channels: [String], groups: [String], newCount: Int, restart: Bool) {
    // Call Leave on channels/groups
    if !configuration.supressLeaveEvents {
      presenceLeave(for: configuration.uuid, on: channels, and: groups) { result in
        PubNub.log.info("Presence Leave: \(result)")
      }
    }

    // Reset all timetokens and regions if we've unsubscribed from all channels/groups
    if newCount == 0 {
      previousTokenResponse = nil
    }

    currentTimetoken = 0
    if restart {
      reconnect(at: 0)
    }
  }
}

extension SubscriptionSession: EventStreamListener {
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
