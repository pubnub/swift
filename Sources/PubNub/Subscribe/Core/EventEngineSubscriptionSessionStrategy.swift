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
  var configuration: PubNubConfiguration
  var previousTokenResponse: SubscribeCursor?

  var listeners: WeakSet<BaseSubscriptionListener> = WeakSet([]) {
    didSet {
      updateSubscribeEngineDependencies()
      updatePresenceEngineDependencies()
    }
  }
  var filterExpression: String? {
    didSet {
      onFilterExpressionChanged()
    }
  }

  internal init(
    configuration: PubNubConfiguration,
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
    subscribeEngine.state.input.channelNames(withPresence: true)
  }

  var subscribedChannelGroups: [String] {
    subscribeEngine.state.input.channelGroupNames(withPresence: true)
  }

  var subscriptionCount: Int {
    subscribeEngine.state.input.totalSubscribedCount
  }

  var connectionStatus: ConnectionStatus {
    subscribeEngine.state.connectionStatus
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
        listeners: listeners
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
    let channels = currentState.input.channelNames(withPresence: true)
    let groups = currentState.input.channelGroupNames(withPresence: true)

    sendSubscribeEvent(event: .subscriptionChanged(channels: channels, groups: groups))
  }

  func subscribe(
    to channels: [String],
    and channelGroups: [String],
    at cursor: SubscribeCursor?
  ) {
    let currentInput = subscribeEngine.state.input
    let newInput = currentInput.adding(channels: Set(channels), and: Set(channelGroups))
    let diff = newInput.difference(from: currentInput)

    if let cursor = cursor, cursor.timetoken != 0 {
      sendSubscribeEvent(event: .subscriptionRestored(
        channels: newInput.channelNames(withPresence: true),
        groups: newInput.channelGroupNames(withPresence: true),
        cursor: cursor
      ))
      sendPresenceEvent(event: .joined(
        channels: newInput.channelNames(withPresence: false),
        groups: newInput.channelGroupNames(withPresence: false)
      ))
    } else if currentInput != newInput {
      sendSubscribeEvent(event: .subscriptionChanged(
        channels: newInput.channelNames(withPresence: true),
        groups: newInput.channelGroupNames(withPresence: true)
      ))
      sendPresenceEvent(event: .joined(
        channels: newInput.channelNames(withPresence: false),
        groups: newInput.channelGroupNames(withPresence: false)
      ))
    } else {
      // No unique channels or channel groups were provided.
      // There's no need to alter the Subscribe loop.
    }

    if !diff.addedChannels.isEmpty || !diff.addedChannelGroups.isEmpty {
      notify {
        $0.emit(subscribe: .subscriptionChanged(
          .subscribed(
            channels: diff.addedChannels.map { PubNubChannel(channel: $0) }.consolidated(),
            groups: diff.removedChannels.map { PubNubChannel(channel: $0) }.consolidated()
          ))
        )
      }
    }
  }

  func unsubscribe(
    from channels: [String],
    and channelGroups: [String]
  ) {
    let currentInput = subscribeEngine.state.input
    let newInput = currentInput.removing(channels: Set(channels), and: Set(channelGroups))

    if currentInput != newInput {

      let diff = newInput.difference(from: currentInput)
      let removedMainChannels = diff.removedChannels.filter { !$0.isPresenceChannelName }.allObjects
      let removedMainChannelGroups = diff.removedChannelGroups.filter { !$0.isPresenceChannelName }.allObjects

      // Dispatch local event first to guarantee the expected order of events.
      // An event indicating unsubscribing from channels and channel groups
      // should be emitted before an event related to disconnecting
      // from the Subscribe loop, assuming you unsubscribed from all channels
      // and channel groups
      notify {
        $0.emit(subscribe: .subscriptionChanged(
          .unsubscribed(
            channels: diff.removedChannels.map { PubNubChannel(channel: $0) }.consolidated(),
            groups: diff.removedChannelGroups.map { PubNubChannel(channel: $0) }.consolidated()
          ))
        )
      }

      if configuration.maintainPresenceState {
        presenceStateContainer.removeState(forChannels: removedMainChannels)
      }

      sendSubscribeEvent(event: .subscriptionChanged(
        channels: newInput.channelNames(withPresence: true),
        groups: newInput.channelGroupNames(withPresence: true)
      ))
      sendPresenceEvent(event: .left(
        channels: removedMainChannels,
        groups: removedMainChannelGroups
      ))
    }
  }

  func reconnect(at cursor: SubscribeCursor?) {
    sendSubscribeEvent(event: .reconnect(cursor: cursor))
  }

  func disconnect() {
    sendSubscribeEvent(event: .disconnect)
    sendPresenceEvent(event: .disconnect)
  }

  func unsubscribeAll() {
    let currentInput = subscribeEngine.state.input

    // Dispatch local event first to guarantee the expected order of events.
    // An event indicating unsubscribing from channels and channel groups
    // should be emitted before an event related to disconnecting
    // from the Subscribe loop, assuming you unsubscribed from all channels
    // and channel groups
    notify {
      $0.emit(subscribe: .subscriptionChanged(
        .unsubscribed(
          channels: currentInput.channelNames(withPresence: true).map { PubNubChannel(channel: $0) }.consolidated(),
          groups: currentInput.channelGroupNames(withPresence: true).map { PubNubChannel(channel: $0) }.consolidated()
        )
      ))
    }

    sendSubscribeEvent(event: .unsubscribeAll)
    sendPresenceEvent(event: .leftAll)
  }

  private func notify(listeners closure: (BaseSubscriptionListener) -> Void) {
    listeners.allObjects.forEach { closure($0) }
  }
}
