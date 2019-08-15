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

public class SubscriptionSession {
  struct InternalState {
    var isActive: Bool {
      switch state {
      case .initialized, .disconnected, .disconnectedUnexpectedly, .cancelled:
        return false
      case .connected, .connecting, .reconnected, .reconnecting:
        return true
      }
    }

    var state: ConnectionStatus = .initialized

    var channels: Set<String> = []
    var channelGroups: Set<String> = []

    var nonPresenceChannels: Set<String> {
      return channels.filter { !$0.isPresenceChannelName }
    }

    var nonPresenceChannelGroups: Set<String> {
      return channelGroups.filter { !$0.isPresenceChannelName }
    }

    var totalChannelCount: Int {
      return channels.count + channelGroups.count
    }

    // Nil values will be ignored and empty values will become nil after the next subscription loop/setState call
    private(set) var presenceState: ChannelPresenceState = [:]

    mutating func cleanPresenceState(removeNil _: Bool = true, removeEmpty: Bool = true) {
      presenceState = presenceState.filter { channelState in
        if removeEmpty, channelState.value.isEmpty {
          return false
        }
        return true
      }
    }

    mutating func mergePresenceState(
      _ other: ChannelPresenceState,
      removingEmpty: Bool = true,
      addingChannels: Bool = false
    ) {
      // Clean List before processing
      cleanPresenceState()

      // Get all the empty values and remove them from the existing state list
      other.forEach { channelState in
        if removingEmpty, channelState.value.isEmpty {
          // Remove empty lists from our cached list
          presenceState.removeValue(forKey: channelState.key)
        } else if addingChannels, presenceState[channelState.key] == nil {
          // Only update channels that we're actively subscribed to
          presenceState.updateValue(channelState.value, forKey: channelState.key)
        } else if presenceState[channelState.key] != nil {
          // Update any tracked values
          presenceState.updateValue(channelState.value, forKey: channelState.key)
        }
      }
    }
  }

  // MARK: - Instance Properties

  var privateListeners: WeakSet<ListenerType> = WeakSet([])

  public let uuid = UUID()
  let networkSession: Session
  let configuration: SubscriptionConfiguration
  let sessionStream: SessionListener

  var messageCache = [MessageResponse?].init(repeating: nil, count: 100)
  var presenceTimer: Timer?

  let responseQueue: DispatchQueue

  var currentTimetoken: Timetoken = 0
  var previousTokenResponse: TimetokenResponse?

  var state = Atomic<InternalState>(InternalState())

  internal init(configuration: SubscriptionConfiguration, network session: Session) {
    self.configuration = configuration
    networkSession = session
    responseQueue = DispatchQueue(label: "com.pubnub.subscription.response", qos: .default)
    sessionStream = SessionListener(queue: responseQueue)
  }

  deinit {
    self.networkSession.session.invalidateAndCancel()
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
    let hasChanges = state.lockedWrite { mutableState -> Bool in
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

    if hasChanges, state.lockedRead({ !$0.isActive }) {
      reconnect(at: timetoken, setting: incomingState)
    }
  }

  public func reconnect(at timetoken: Timetoken, setting incomingState: ChannelPresenceState? = nil) {
    // Start subscription loop
    if state.lockedRead({ !$0.isActive }) {
      state.lockedWrite { $0.state = .connecting }
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
    state.lockedWrite { $0.state = .disconnected }
    notify { $0.emitDidReceive(status: .success(.disconnected)) }
  }

  func stopSubscribeLoop() {
    networkSession.cancelAllTasks(with: PNError.requestCancelled(.unknown))
  }

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  func performSubscribeLoop(at timetoken: Timetoken, setting incomingState: ChannelPresenceState? = nil) {
    // Ensure we don't have multiple subscribe loops
    stopSubscribeLoop()

    let (channels, groups, storedState) = state
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

          let shouldNotifyConnected = strongSelf.state.lockedWrite { mutableState -> Bool in
            mutableState.cleanPresenceState()
            if mutableState.state != .connected {
              mutableState.state = .connected
              return true
            }
            return false
          }

          if shouldNotifyConnected {
            self?.notify { $0.emitDidReceive(status: .success(.connected)) }
          }

          if response.payload.messages.count >= 100 {
            self?.notify { $0.emitDidReceive(status: .failure(PNError.messageCountExceededMaximum(router.endpoint))) }
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
                strongSelf.state.lockedWrite { $0.mergePresenceState(presenceMessage.channelState) }
              }

              self?.notify { $0.emitDidRecieve(presence: presenceEvent) }
            } else {
              // Update Cache and notify if not a duplicate message
              if !strongSelf.messageCache.contains(message) {
                self?.notify { $0.emitDidRecieve(message: message) }
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
            self?.notify { $0.emitDidReceive(status: .success(.cancelled)) }
          } else {
            self?.state.lockedWrite { $0.state = .disconnectedUnexpectedly }
            self?.notify { $0.emitDidReceive(status: .success(.disconnectedUnexpectedly)) }
          }
        }
      }
  }

  // MARK: - Unsubscribe

  public func unsubscribe(from channels: [String], and channelGroups: [String] = []) {
    stopSubscribeLoop()

    // Update Channel List
    let newCount = state.lockedWrite { mutableState -> Int in
      mutableState.channels.remove(contentsOf: channels)
      mutableState.channelGroups.remove(contentsOf: channelGroups)

      mutableState.channels.remove(contentsOf: channels.map { $0.presenceChannelName })
      mutableState.channelGroups.remove(contentsOf: channelGroups.map { $0.presenceChannelName })

      return mutableState.totalChannelCount
    }

    // Call Leave on channels/groups
    if !configuration.supressLeaveEvents {
      presenceLeave(for: configuration.uuid, on: channels, and: channelGroups) { _ in
//        notify { $0.emitDidReceive(status: .success()) }
      }
    }

    // Clear state for unsubscribing channels

    // Reset all timetokens and regions if we've unsubscribed from all channels/groups
    if newCount == 0 {
      previousTokenResponse = nil
    }

    currentTimetoken = 0
    reconnect(at: 0)
  }

  public func unsubscribeAll() {
    // Remove All Groups
    state.lockedWrite { mutableState in
      mutableState.channels.removeAll()
      mutableState.channelGroups.removeAll()
    }

    // Remove timetoken and region so we start fresh
    previousTokenResponse = nil
    currentTimetoken = 0

    reconnect(at: 0)
  }
}

extension SubscriptionSession: EventStreamListener {
  public typealias ListenerType = SubscriptionListener

  public var listeners: [ListenerType] {
    return privateListeners.allObjects
  }

  public func add(_ listener: ListenerType) -> ListenerToken {
    privateListeners.update(listener)
    return ListenerToken { [weak self] in
      self?.remove(listener)
    }
  }

  public func remove(_ listener: ListenerType) {
    privateListeners.remove(listener)
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
}
