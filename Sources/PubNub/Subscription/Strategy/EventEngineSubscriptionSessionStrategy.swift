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

  var listeners: WeakSet<BaseSubscriptionListener> = WeakSet([])
  var configuration: PubNubConfiguration
  var previousTokenResponse: SubscribeCursor?
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
        listeners: listeners.allObjects
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

  func subscribe(
    to channels: [PubNubChannel],
    and groups: [PubNubChannel],
    at cursor: SubscribeCursor?
  ) {
    let currentChannelsAndGroups = subscribeEngine.state.input
    let insertionResult = currentChannelsAndGroups.adding(channels: channels, and: groups)
    let newChannelsAndGroups = insertionResult.newInput

    if let cursor = cursor, cursor.timetoken != 0 {
      sendSubscribeEvent(event: .subscriptionRestored(
        channels: newChannelsAndGroups.allSubscribedChannelNames,
        groups: newChannelsAndGroups.allSubscribedGroupNames,
        cursor: cursor
      ))
      sendPresenceEvent(event: .joined(
        channels: newChannelsAndGroups.subscribedChannelNames,
        groups: newChannelsAndGroups.subscribedGroupNames
      ))
    } else if newChannelsAndGroups != currentChannelsAndGroups {
      sendSubscribeEvent(event: .subscriptionChanged(
        channels: newChannelsAndGroups.allSubscribedChannelNames,
        groups: newChannelsAndGroups.allSubscribedGroupNames
      ))
      sendPresenceEvent(event: .joined(
        channels: newChannelsAndGroups.subscribedChannelNames,
        groups: newChannelsAndGroups.subscribedGroupNames
      ))
    } else {
      // No unique channels or channel groups were provided.
      // There's no need to alter the Subscribe loop.
    }
    if !insertionResult.insertedChannels.isEmpty || !insertionResult.insertedGroups.isEmpty {
      notify {
        $0.emit(subscribe: .subscriptionChanged(
          .subscribed(
            channels: insertionResult.insertedChannels,
            groups: insertionResult.insertedGroups
          ))
        )
      }
    }
  }

  func unsubscribeFrom(
    mainChannels: [PubNubChannel],
    presenceChannelsOnly: [PubNubChannel],
    mainGroups: [PubNubChannel],
    presenceGroupsOnly: [PubNubChannel]
  ) {
    // Retrieve the current list of subscribed channels and channel groups
    let currentChannelsAndGroups = subscribeEngine.state.input
    // Provides the outcome after updating the list of channels and channel groups
    let removingResult = currentChannelsAndGroups.removing(
      mainChannels: mainChannels, presenceChannelsOnly: presenceChannelsOnly,
      mainGroups: mainGroups, presenceGroupsOnly: presenceGroupsOnly
    )

    // Exits if there are no differences for channels or channel groups
    guard removingResult.newInput != currentChannelsAndGroups else {
      return
    }
    if configuration.maintainPresenceState {
      presenceStateContainer.removeState(forChannels: removingResult.removedChannels.map { $0.id })
    }
    // Dispatch local event first to guarantee the expected order of events.
    // An event indicating unsubscribing from channels and channel groups
    // should be emitted before an event related to disconnecting
    // from the Subscribe loop, assuming you unsubscribed from all channels
    // and channel groups
    notify {
      $0.emit(subscribe: .subscriptionChanged(
        .unsubscribed(
          channels: removingResult.removedChannels,
          groups: removingResult.removedGroups
        ))
      )
    }
    sendSubscribeEvent(event: .subscriptionChanged(
      channels: removingResult.newInput.allSubscribedChannelNames,
      groups: removingResult.newInput.allSubscribedGroupNames
    ))
    sendPresenceEvent(event: .left(
      channels: removingResult.removedChannels.map { $0.id },
      groups: removingResult.removedGroups.map { $0.id }
    ))
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
          channels: currentInput.channels,
          groups: currentInput.groups
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
