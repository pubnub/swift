//
//  EventEngineSubscriptionSessionStrategy.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class EventEngineSubscriptionSessionStrategy: SubscriptionSessionStrategy {
  let uuid = UUID()
  let subscribeEngine: SubscribeEngine
  let presenceEngine: PresenceEngine
  let presenceStateContainer: PresenceStateContainer

  var privateListeners: WeakSet<ListenerType> = WeakSet([])
  var configuration: SubscriptionConfiguration
  var previousTokenResponse: SubscribeCursor?
  var filterExpression: String? {
    didSet {
      onFilterExpressionChanged()
    }
  }
  
  internal init(
    configuration: SubscriptionConfiguration,
    subscribeEngine: SubscribeEngine,
    presenceEngine: PresenceEngine,
    presenceStateContainer: PresenceStateContainer
  ) {
    self.subscribeEngine = subscribeEngine
    self.configuration = configuration
    self.presenceEngine = presenceEngine
    self.presenceStateContainer = presenceStateContainer
    self.filterExpression = configuration.filterExpression
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
      if state is Subscribe.ReceivingState && state.hasTimetoken {
        self?.previousTokenResponse = state.cursor
      }
    }
  }
  
  private func updateSubscribeEngineDependencies() {
    subscribeEngine.dependencies = EventEngineDependencies(
      value: Subscribe.Dependencies(
        configuration: configuration,
        listeners: privateListeners.allObjects
      )
    )
  }
  
  private func sendSubscribeEvent(event: Subscribe.Event) {
    updateSubscribeEngineDependencies()
    subscribeEngine.send(event: event)
  }
  
  private func updatePresenceEngineDependencies() {
    presenceEngine.dependencies = EventEngineDependencies(
      value: Presence.Dependencies(
        configuration: configuration
      )
    )
  }
  
  private func sendPresenceEvent(event: Presence.Event) {
    updatePresenceEngineDependencies()
    presenceEngine.send(event: event)
  }
  
  private func onFilterExpressionChanged() {
    let currentState = subscribeEngine.state
    let channels = currentState.input.allSubscribedChannels
    let groups = currentState.input.allSubscribedGroups

    sendSubscribeEvent(event: .subscriptionChanged(channels: channels, groups: groups))
  }

  // MARK: - Subscription Loop

  func subscribe(
    to channels: [String],
    and groups: [String],
    at cursor: SubscribeCursor?,
    withPresence: Bool
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
      channels: newInput.subscribedChannels,
      groups: newInput.subscribedGroups
    ))
  }

  func reconnect(at cursor: SubscribeCursor?) {
    let input = subscribeEngine.state.input
    let channels = input.allSubscribedChannels
    let groups = input.allSubscribedGroups
    
    if let cursor = cursor {
      sendSubscribeEvent(event: .subscriptionRestored(
        channels: channels,
        groups: groups,
        cursor: cursor
      ))
    } else {
      sendSubscribeEvent(event: .reconnect)
    }
  }

  func disconnect() {
    sendSubscribeEvent(event: .disconnect)
    sendPresenceEvent(event: .disconnect)
  }

  // MARK: - Unsubscribe

  func unsubscribe(from channels: [String], and groups: [String], presenceOnly: Bool) {
    let newInput = subscribeEngine.state.input - (
      channels: channels.map { presenceOnly ? $0.presenceChannelName : $0 },
      groups: groups.map { presenceOnly ? $0.presenceChannelName : $0 }
    )
    
    presenceStateContainer.removeState(forChannels: channels)
    presenceStateContainer.removeState(forGroups: groups)
    
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
        self?.updateSubscribeEngineDependencies()
      }
    }
    privateListeners.update(listener)
    updateSubscribeEngineDependencies()
  }

  func notify(listeners closure: (ListenerType) -> Void) {
    listeners.forEach { closure($0) }
  }
}
