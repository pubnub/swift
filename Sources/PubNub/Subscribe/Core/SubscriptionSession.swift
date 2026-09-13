//
//  SubscriptionSession.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class SubscriptionSession: EventListenerInterface, StatusListenerInterface {
  // An underlying queue to dispatch events
  let queue: DispatchQueue
  // A unique identifier for subscription session
  var uuid: UUID { strategy.uuid }
  // The `Timetoken` used for the last successful subscription request
  var previousTokenResponse: SubscribeCursor? { strategy.previousTokenResponse }
  // Additional listeners for global subscriptions
  private let listenersContainer: SubscriptionListenersContainer = .init()

  // PSV2 feature to subscribe with a custom filter expression.
  var filterExpression: String? {
    get {
      strategy.filterExpression
    } set {
      strategy.filterExpression = newValue
    }
  }

  var configuration: PubNubConfiguration {
    get {
      strategy.configuration
    } set {
      strategy.configuration = newValue
    }
  }

  var onEvent: ((PubNubEvent) -> Void)?
  var onEvents: (([PubNubEvent]) -> Void)?
  var onMessage: ((PubNubMessage) -> Void)?
  var onSignal: ((PubNubMessage) -> Void)?
  var onPresence: ((PubNubPresenceChange) -> Void)?
  var onMessageAction: ((PubNubMessageActionEvent) -> Void)?
  var onFileEvent: ((PubNubFileChangeEvent) -> Void)?
  var onAppContext: ((PubNubAppContextEvent) -> Void)?
  var onDataSync: ((PubNubDataSyncEvent) -> Void)?
  var onConnectionStateChange: ((ConnectionStatus) -> Void)?

  private lazy var globalEventsListener: BaseSubscriptionListenerAdapter = .init(
    receiver: self,
    uuid: uuid,
    queue: queue
  )

  private lazy var globalStatusListener: BaseSubscriptionListener = {
    // Creates legacy listener under the hood to capture status changes
    let statusListener = SubscriptionListener(queue: queue)
    // Detects status changes and forwards events to the current instance
    // representing the Subscribe loop's status emitter
    statusListener.didReceiveStatus = { [weak self] statusChange in
      if case .success(let newStatus) = statusChange {
        self?.onConnectionStateChange?(newStatus)
        self?.listenersContainer.statusListeners.forEach { listener in
          listener.queue.async { [weak listener] in
            listener?.onConnectionStateChange?(newStatus)
          }
        }
      }
    }
    return statusListener
  }()

  private let globalChannelSubscriptions: Atomic<[String: Subscription]> = Atomic([:])
  private let globalGroupSubscriptions: Atomic<[String: Subscription]> = Atomic([:])
  private let strategy: any SubscriptionSessionStrategy

  init(
    strategy: any SubscriptionSessionStrategy,
    eventsQueue queue: DispatchQueue = .main
  ) {
    self.strategy = strategy
    self.queue = queue
    add(globalEventsListener)
    add(globalStatusListener)
  }

  // Names of all subscribed channels
  //
  // This list includes both regular and presence channel names
  var subscribedChannels: [String] {
    strategy.subscribedChannels
  }

  // List of actively subscribed groups
  var subscribedChannelGroups: [String] {
    strategy.subscribedChannelGroups
  }

  // Combined value of all subscribed channels and groups
  var subscriptionCount: Int {
    strategy.subscriptionCount
  }

  // Current connection status
  var connectionStatus: ConnectionStatus {
    strategy.connectionStatus
  }

  // MARK: - Subscription Loop

  func subscribe(
    to channelSubscriptions: [Subscription],
    and channelGroupSubscriptions: [Subscription] = [],
    at cursor: SubscribeCursor? = nil
  ) {
    let allSubscriptions = channelSubscriptions + channelGroupSubscriptions

    internalSubscribe(
      with: allSubscriptions,
      at: cursor?.timetoken
    )

    var channelSubsToMerge = [String: Subscription]()
    var channelGroupSubsToMerge = [String: Subscription]()

    for subscription in allSubscriptions {
      let topology = subscription.subscriptionTopology

      for name in topology.channels {
        channelSubsToMerge[name] = subscription
      }
      for name in topology.channelGroups {
        channelGroupSubsToMerge[name] = subscription
      }
    }

    globalChannelSubscriptions.lockedWrite {
      $0.merge(channelSubsToMerge) { _, new in new }
    }
    globalGroupSubscriptions.lockedWrite {
      $0.merge(channelGroupSubsToMerge) { _, new in new }
    }
  }

  // MARK: - Reconnect

  func reconnect(at cursor: SubscribeCursor? = nil) {
    strategy.reconnect(at: cursor)
  }

  // MARK: - Disconnect

  func disconnect() {
    strategy.disconnect()
  }

  // MARK: - Unsubscribe

  func unsubscribe(
    from channels: [String],
    and channelGroups: [String] = []
  ) {
    let channelsToUnsubscribe = channels.flatMap { $0.isPresenceChannelName ? [$0] : [$0, $0.presenceChannelName] }
    let channelGroupsToUnsubscribe = channelGroups.flatMap { $0.isPresenceChannelName ? [$0] : [$0, $0.presenceChannelName] }

    let matchingChannelsToUnsubscribe = globalChannelSubscriptions.lockedRead {
      $0.compactMap {
        channelsToUnsubscribe.contains($0.key) ? $0.value : nil
      }
    }
    let matchingChannelGroupsToUnsubscribe = globalGroupSubscriptions.lockedRead {
      $0.compactMap {
        channelGroupsToUnsubscribe.contains($0.key) ? $0.value : nil
      }
    }

    internalUnsubscribe(
      from: matchingChannelsToUnsubscribe + matchingChannelGroupsToUnsubscribe
    )

    globalChannelSubscriptions.lockedWrite { currentContainer in
      channelsToUnsubscribe.forEach {
        currentContainer.removeValue(forKey: $0)
      }
    }

    globalGroupSubscriptions.lockedWrite { currentContainer in
      channelGroupsToUnsubscribe.forEach {
        currentContainer.removeValue(forKey: $0)
      }
    }
  }

  func unsubscribeAll() {
    strategy.unsubscribeAll()
  }
}

extension SubscriptionSession {
  func hasRegisteredAdapter(with uuid: UUID) -> Bool {
    strategy.listeners.contains { $0?.uuid == uuid }
  }

  // Registers a subscription adapter to translate events from a legacy listener
  // into the new Listeners API.
  //
  // The provided adapter is responsible for translating events received from a legacy listener
  // into the new Listeners API, allowing seamless integration with both new and old codebases.
  func registerAdapter(_ adapter: BaseSubscriptionListenerAdapter) {
    add(adapter)
  }

  // Composes final PubNubChannel lists the user should subscribe to
  // according to provided raw input and forwards the result to the underlying Subscription strategy.
  func internalSubscribe(
    with subscriptions: [Subscription],
    at timetoken: Timetoken?
  ) {
    let topology = subscriptions.reduce(SubscriptionTopology.empty) {
      $0 + $1.subscriptionTopology
    }

    if topology.isEmpty {
      return
    }
    for subscription in subscriptions {
      registerAdapter(subscription.adapter)
    }

    strategy.subscribe(
      to: topology.channels,
      and: topology.channelGroups,
      at: SubscribeCursor(timetoken: timetoken)
    )
  }

  func internalUnsubscribe(
    from subscriptions: [Subscription]
  ) {
    let topologyToUnsubscribe = resolveTopologyToUnsubscribe(from: subscriptions)

    for subscription in subscriptions {
      remove(subscription.adapter)
    }

    strategy.unsubscribe(
      from: topologyToUnsubscribe.channels,
      and: topologyToUnsubscribe.channelGroups
    )
  }

  // Returns a boolean indicating whether there are subscription objects that subscribe to at least one name
  // in common with the given subscription
  func hasOverlappingSubscriptions(for subscription: Subscription) -> Bool {
    let remainingSubscriptions = strategy.listeners.allObjects.compactMap {
      $0 as? BaseSubscriptionListenerAdapter
    }.filter {
      // Exclude the subscription being checked and the internal global events listener
      // since the global listener is not a user-triggered subscription
      $0.uuid != subscription.uuid && $0.uuid != globalEventsListener.uuid
    }
    let matchingSubscriptions = remainingSubscriptions.compactMap {
     $0.receiver
    }.filter {
      $0.subscriptionTopology.intersects(subscription.subscriptionTopology)
    }

    return !matchingSubscriptions.isEmpty
  }

  // Returns the names that no longer have any subscription keeping them in the Subscribe loop
  private func resolveTopologyToUnsubscribe(from subscriptions: [Subscription]) -> SubscriptionTopology {
    return subscriptions.reduce(SubscriptionTopology.empty) { accumulatedResult, subscription in
      if hasOverlappingSubscriptions(for: subscription) {
        return accumulatedResult
      } else {
        return accumulatedResult + subscription.subscriptionTopology
      }
    }
  }
}

// MARK: - EventStreamEmitter

extension SubscriptionSession: EventStreamEmitter {
  public typealias ListenerType = BaseSubscriptionListener

  public var listeners: [ListenerType] {
    strategy.listeners.allObjects
  }

  public func notify(listeners closure: (ListenerType) -> Void) {
    listeners.forEach { closure($0) }
  }

  public func add(_ listener: ListenerType) {
    // Ensure that we cancel the previously attached token
    listener.token?.cancel()
    // Add new token to the listener
    listener.token = ListenerToken { [weak self, weak listener] in
      if let listener = listener {
        self?.strategy.listeners.remove(listener)
      }
    }
    strategy.listeners.update(listener)
  }
}

// MARK: - Hashable & CustomStringConvertible

extension SubscriptionSession: Hashable, CustomStringConvertible {
  static func == (lhs: SubscriptionSession, rhs: SubscriptionSession) -> Bool {
    lhs.uuid == rhs.uuid
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }

  var description: String {
    uuid.uuidString
  }
}

// MARK: - SubscribeMessagePayloadReceiver

extension SubscriptionSession: SubscribeMessagesReceiver {
  var subscriptionTopology: SubscriptionTopology {
    SubscriptionTopology(channels: subscribedChannels, channelGroups: subscribedChannelGroups)
  }

  func onPayloadsReceived(payloads: [SubscribeMessagePayload]) -> [PubNubEvent] {
    // Translates payloads into PubNub Subscibe Loop events
    let events = payloads.map { $0.asPubNubEvent() }
    // Emits events from the SubscriptionSession
    emit(events: events)
    // Emits events to the underlying attached listeners
    listenersContainer.eventListeners.forEach { $0.emit(events: events) }
    // Returns events that were processed
    return events
  }
}

extension SubscriptionSession: EventListenerHandler {
  func addEventListener(_ listener: EventListener) {
    listenersContainer.storeEventListener(listener)
  }

  func removeEventListener(_ listener: EventListener) {
    listenersContainer.removeEventListener(listener)
  }

  func removeAllListeners() {
    listenersContainer.removeAllEventListeners()
  }
}

extension SubscriptionSession {
  func addStatusListener(_ listener: StatusListener) {
    listenersContainer.storeStatusListener(listener)
  }

  func removeStatusListener(_ listener: StatusListener) {
    listenersContainer.removeStatusListener(listener)
  }

  func removeAllStatusListeners() {
    listenersContainer.removeAllStatusListeners()
  }
}
