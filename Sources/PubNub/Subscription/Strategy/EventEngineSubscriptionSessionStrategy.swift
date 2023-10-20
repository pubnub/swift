//
//  EventEngineSubscriptionSessionStrategy.swift
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

class EventEngineSubscriptionSessionStrategy: SubscriptionSessionStrategy {
  let uuid = UUID()
  
  var privateListeners: WeakSet<ListenerType> = WeakSet([])
  var configuration: SubscriptionConfiguration
  var subscribeEngine: SubscribeEngine
  var presenceEngine: PresenceEngine
  var previousTokenResponse: SubscribeCursor?
  
  internal init(
    configuration: SubscriptionConfiguration,
    subscribeEngine: SubscribeEngine,
    presenceEngine: PresenceEngine
  ) {
    self.subscribeEngine = subscribeEngine
    self.configuration = configuration
    self.presenceEngine = presenceEngine
    self.listenForStateUpdates()
  }

  var subscribedChannels: [String] {
    subscribeEngine.state.input.subscribedChannels
  }
  
  var subscribedChannelGroups: [String] {
    subscribeEngine.state.input.subscribedGroups
  }
  
  var subscriptionCount: Int {
    subscribeEngine.state.input.totalSubscribedCount
  }
  
  var connectionStatus: ConnectionStatus {
    subscribeEngine.state.connectionStatus
  }
  
  deinit {
    PubNub.log.debug("SubscriptionSession Destroyed")
    // Poke the session factory to clean up nil values
    SubscribeSessionFactory.shared.sessionDestroyed()
  }
  
  private func listenForStateUpdates() {
    subscribeEngine.onStateUpdated = { [weak self] state in
      if state.hasTimetoken {
        self?.previousTokenResponse = state.cursor
      }
    }
  }
  
  private func updateSubscribeEngineInput() {
    subscribeEngine.customInput = EventEngineCustomInput(
      value: Subscribe.EngineInput(
        configuration: configuration,
        listeners: privateListeners.allObjects
      )
    )
  }
  
  private func sendSubscribeEvent(event: Subscribe.Event) {
    updateSubscribeEngineInput()
    subscribeEngine.send(event: event)
  }
  
  private func updatePresenceEngineInput() {
    presenceEngine.customInput = EventEngineCustomInput(
      value: Presence.EngineInput(
        configuration: configuration
      )
    )
  }
  
  private func sendPresenceEvent(event: Presence.Event) {
    updatePresenceEngineInput()
    presenceEngine.send(event: event)
  }

  // MARK: - Subscription Loop

  func subscribe(
    to channels: [String],
    and groups: [String] = [],
    at cursor: SubscribeCursor? = nil,
    withPresence: Bool = false
  ) {
    let newInput = subscribeEngine.state.input + SubscribeInput(
      channels: channels.map { PubNubChannel(id: $0, withPresence: withPresence) },
      groups: groups.map { PubNubChannel(id: $0, withPresence: withPresence) }
    )
    if let cursor = cursor, cursor.timetoken != 0 {
      sendSubscribeEvent(event: .subscriptionRestored(
        channels: newInput.allSubscribedChannels,
        groups: newInput.allSubscribedGroups,
        cursor: cursor
      ))
    } else {
      sendSubscribeEvent(event: .subscriptionChanged(
        channels: newInput.allSubscribedChannels,
        groups: newInput.allSubscribedGroups
      ))
    }
    sendPresenceEvent(event: .joined(
      channels: newInput.presenceSubscribedChannels,
      groups: newInput.presenceSubscribedGroups
    ))
  }

  func reconnect(at cursor: SubscribeCursor? = nil) {
    let input = subscribeEngine.state.input
    let channels = input.allSubscribedChannels
    let groups = input.allSubscribedGroups
    
    if let cursor = cursor {
      sendSubscribeEvent(event: .subscriptionRestored(channels: channels, groups: groups, cursor: cursor))
    } else {
      sendSubscribeEvent(event: .reconnect)
    }
  }

  func disconnect() {
    sendSubscribeEvent(event: .disconnect)
    sendPresenceEvent(event: .disconnect)
  }

  // MARK: - Unsubscribe

  func unsubscribe(from channels: [String], and groups: [String] = [], presenceOnly: Bool = false) {
    let newInput = subscribeEngine.state.input - (
      channels: channels.map { presenceOnly ? $0.presenceChannelName : $0 },
      groups: groups.map { presenceOnly ? $0.presenceChannelName : $0 }
    )
    sendSubscribeEvent(event: .subscriptionChanged(
      channels: newInput.allSubscribedChannels,
      groups: newInput.allSubscribedGroups
    ))
    sendPresenceEvent(event: .left(
      channels: channels,
      groups: groups
    ))
  }

  func unsubscribeAll() {
    sendSubscribeEvent(event: .unsubscribeAll)
    sendPresenceEvent(event: .leftAll)
  }
}

extension EventEngineSubscriptionSessionStrategy: EventStreamEmitter {
  typealias ListenerType = BaseSubscriptionListener

  var listeners: [ListenerType] {
    privateListeners.allObjects
  }

  func add(_ listener: ListenerType) {
    // Ensure that we cancel the previously attached token
    listener.token?.cancel()
    // Add new token to the listener
    listener.token = ListenerToken { [weak self, weak listener] in
      if let listener = listener {
        self?.privateListeners.remove(listener)
        self?.updateSubscribeEngineInput()
      }
    }
    privateListeners.update(listener)
    updateSubscribeEngineInput()
  }

  func notify(listeners closure: (ListenerType) -> Void) {
    listeners.forEach { closure($0) }
  }
}
