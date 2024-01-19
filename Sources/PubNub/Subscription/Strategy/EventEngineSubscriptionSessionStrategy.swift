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
  let presenceStateContainer: PubNubPresenceStateContainer

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
    presenceStateContainer: PubNubPresenceStateContainer
  ) {
    self.subscribeEngine = subscribeEngine
    self.configuration = configuration
    self.presenceEngine = presenceEngine
    self.presenceStateContainer = presenceStateContainer
    self.filterExpression = configuration.filterExpression
    self.listenForStateUpdates()
  }

  var subscribedChannels: [String] {
    subscribeEngine.state.input.subscribedChannelNames
  }
  
  var subscribedChannelGroups: [String] {
    subscribeEngine.state.input.subscribedGroupNames
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
    let channels = currentState.input.allSubscribedChannelNames
    let groups = currentState.input.allSubscribedGroupNames

    sendSubscribeEvent(event: .subscriptionChanged(channels: channels, groups: groups))
  }

  // MARK: - Subscription Loop

  func subscribe(
    to channels: [String],
    and groups: [String],
    at cursor: SubscribeCursor?,
    withPresence: Bool
  ) {
    let currentInput = subscribeEngine.state.input
    let newChannels = channels.map { PubNubChannel(id: $0, withPresence: withPresence) }
    let newGroups = groups.map { PubNubChannel(id: $0, withPresence: withPresence) }
    let addingResult = currentInput.adding(channels: newChannels, and: newGroups)
    let newInput = addingResult.newInput
    
    if newInput != currentInput {
      if let cursor = cursor, cursor.timetoken != 0 {
        sendSubscribeEvent(event: .subscriptionRestored(
          channels: newInput.allSubscribedChannelNames,
          groups: newInput.allSubscribedGroupNames,
          cursor: cursor
        ))
      } else {
        sendSubscribeEvent(event: .subscriptionChanged(
          channels: newInput.allSubscribedChannelNames,
          groups: newInput.allSubscribedGroupNames
        ))
      }
      sendPresenceEvent(event: .joined(
        channels: newInput.subscribedChannelNames,
        groups: newInput.subscribedGroupNames
      ))
      
      notify {
        $0.emit(subscribe: .subscriptionChanged(
          .subscribed(
            channels: addingResult.insertedChannels,
            groups: addingResult.insertedGroups
          ))
        )
      }
    }
  }

  func reconnect(at cursor: SubscribeCursor?) {
    sendSubscribeEvent(event: .reconnect(cursor: cursor))
  }

  func disconnect() {
    sendSubscribeEvent(event: .disconnect)
    sendPresenceEvent(event: .disconnect)
  }

  // MARK: - Unsubscribe

  func unsubscribe(from channels: [String], and groups: [String], presenceOnly: Bool) {
    let unsubscribedChannels = channels.map { presenceOnly ? $0.presenceChannelName : $0 }
    let unsubscribedGroups = groups.map { presenceOnly ? $0.presenceChannelName : $0 }
    let currentInput = subscribeEngine.state.input
    let removingRes = subscribeEngine.state.input.removing(channels: unsubscribedChannels, and: unsubscribedGroups)
    let newInput = removingRes.newInput
    
    if newInput != currentInput {
      if configuration.maintainPresenceState {
        presenceStateContainer.removeState(forChannels: channels)
      }
      sendSubscribeEvent(event: .subscriptionChanged(
        channels: newInput.allSubscribedChannelNames,
        groups: newInput.allSubscribedGroupNames
      ))
      sendPresenceEvent(event: .left(
        channels: channels,
        groups: groups
      ))
      
      notify {
        $0.emit(subscribe: .subscriptionChanged(
          .unsubscribed(
            channels: removingRes.removedChannels,
            groups: removingRes.removedGroups
          ))
        )
      }
    }
  }

  func unsubscribeAll() {
    let currentInput = subscribeEngine.state.input
    
    sendSubscribeEvent(event: .unsubscribeAll)
    sendPresenceEvent(event: .leftAll)
    
    notify {
      $0.emit(subscribe: .subscriptionChanged(
        .unsubscribed(
          channels: currentInput.channels,
          groups: currentInput.groups
        )
      ))
    }
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
