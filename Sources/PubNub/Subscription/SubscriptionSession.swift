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
  // Additional listeners for global subscriptions
  let listenersContainer: SubscriptionListenersContainer = .init()

  // A unique identifier for subscription session
  var uuid: UUID {
    strategy.uuid
  }

  // The `Timetoken` used for the last successful subscription request
  var previousTokenResponse: SubscribeCursor? {
    strategy.previousTokenResponse
  }

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

  private let adapterMap: Atomic<[UUID: BaseSubscriptionListenerAdapter]> = Atomic([:])
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

  /// Subscribes to the provided channel and channel-group subscriptions, registers their adapters, and merges them into the session's global subscription tracking.
  /// 
  /// Registers adapters for each subscription, calls the underlying subscription strategy with the combined channel and group names (using `cursor`'s timetoken if provided), and updates the session's global channel/group subscription maps.
  /// - Parameters:
  ///   - channelSubscriptions: Subscriptions for individual channels to subscribe to and register.
  ///   - channelGroupSubscriptions: Subscriptions for channel groups to subscribe to and register.
  ///   - cursor: Optional subscribe cursor whose `timetoken` is used as the starting point for the subscribe call.

  func subscribe(
    to channelSubscriptions: [Subscription],
    and channelGroupSubscriptions: [Subscription] = [],
    at cursor: SubscribeCursor? = nil
  ) {
    // Register adapters for all subscriptions
    let allSubscriptions = channelSubscriptions + channelGroupSubscriptions
    for sub in allSubscriptions {
      registerSubscription(sub)
    }

    // Batch the strategy subscribe call with all channels/groups at once
    let channels = channelSubscriptions.flatMap { $0.channelNames }
    let groups = channelGroupSubscriptions.flatMap { $0.channelGroupNames }

    if !channels.isEmpty || !groups.isEmpty {
      strategy.subscribe(
        to: channels,
        and: groups,
        at: SubscribeCursor(timetoken: cursor?.timetoken)
      )
    }

    let channelSubsToMerge = channelSubscriptions.reduce(
      into: [String: Subscription]()
    ) { accumulatedValue, subscription in
      subscription.subscriptionNames.forEach {
        accumulatedValue[$0] = subscription
      }
    }

    let channelGroupSubsToMerge = channelGroupSubscriptions.reduce(
      into: [String: Subscription]()
    ) { accumulatedValue, subscription in
      subscription.subscriptionNames.forEach {
        accumulatedValue[$0] = subscription
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

  /// Unsubscribes the session from the given channels and channel groups, deregistering any associated subscription adapters and updating internal subscription state.
  /// 
  /// The provided names are expanded to include their presence counterparts when applicable; matching tracked `Subscription` objects are found and each is deregistered. Resolved channel and group names are passed to the underlying `strategy.unsubscribe(...)`, and the corresponding entries are removed from the session's global subscription maps.
  /// - Parameters:
  ///   - channels: Channel names to unsubscribe from. Each name will be expanded to include its presence channel if it is not already a presence name.
  ///   - channelGroups: Channel group names to unsubscribe from. Each name will be expanded to include its presence group if it is not already a presence name.

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

    // Resolve which names to unsubscribe, then deregister and batch unsubscribe
    let allSubscriptions = matchingChannelsToUnsubscribe + matchingChannelGroupsToUnsubscribe
    var resolvedChannels: [String] = []
    var resolvedGroups: [String] = []

    for sub in allSubscriptions {
      resolvedChannels.append(contentsOf: resolveNamesToUnsubscribe(from: sub, type: .channel))
      resolvedGroups.append(contentsOf: resolveNamesToUnsubscribe(from: sub, type: .channelGroup))
      deregisterSubscription(with: sub.uuid)
    }

    if !resolvedChannels.isEmpty || !resolvedGroups.isEmpty {
      strategy.unsubscribe(from: resolvedChannels, and: resolvedGroups)
    }

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
  /// Checks whether a subscription adapter is registered for the given subscription UUID.
  /// - Parameter uuid: The UUID of the subscription to look up.
  /// - Returns: `true` if a subscription adapter with the given UUID is registered, `false` otherwise.

  func hasRegisteredSubscription(with uuid: UUID) -> Bool {
    adapterMap.lockedRead { $0[uuid] != nil }
  }

  /// Registers a subscription's message receiver with the session so incoming subscribe messages are delivered to session listeners.
  /// - Parameter subscription: The subscription to register. If a registration for the subscription's UUID already exists or the subscription does not conform to `SubscribeMessagesReceiver`, this call has no effect.
  func registerSubscription(_ subscription: any SubscriptionInterface) {
    let existingAdapter = adapterMap.lockedRead { $0[subscription.uuid] }
    if existingAdapter != nil { return }

    guard let receiver = subscription as? SubscribeMessagesReceiver else { return }

    let adapter = BaseSubscriptionListenerAdapter(
      receiver: receiver,
      uuid: subscription.uuid,
      queue: subscription.queue
    )
    adapterMap.lockedWrite { $0[subscription.uuid] = adapter }
    add(adapter)
  }

  /// Removes the subscription adapter identified by `uuid` and unregisters it from the session if present.
  /// - Parameter uuid: The UUID of the subscription whose adapter should be removed.
  func deregisterSubscription(with uuid: UUID) {
    if let adapter = adapterMap.lockedWrite({ $0.removeValue(forKey: uuid) }) {
      remove(adapter)
    }
  }

  /// Registers the subscription's listener adapter and subscribes to the subscription's channels and channel groups.
  /// - Parameters:
  ///   - subscription: The subscription whose channel and channel group names will be registered and subscribed to.
  ///   - timetoken: An optional timetoken used to construct the subscribe cursor; if `nil`, subscription starts from the strategy's default cursor.

  func internalSubscribe(
    with subscription: any SubscriptionInterface,
    at timetoken: Timetoken?
  ) {
    registerSubscription(subscription)

    let channels = subscription.channelNames
    let groups = subscription.channelGroupNames

    if channels.isEmpty, groups.isEmpty { return }

    strategy.subscribe(
      to: channels,
      and: groups,
      at: SubscribeCursor(timetoken: timetoken)
    )
  }

  /// Unregisters the given subscription's adapter and requests unsubscribe for the subscription's resolved channel and channel-group names.
  /// - Parameters:
  ///   - subscription: The subscription to remove and unsubscribe.
  func internalUnsubscribe(from subscription: any SubscriptionInterface) {
    let channelsToUnsubscribe = resolveNamesToUnsubscribe(from: subscription, type: .channel)
    let groupsToUnsubscribe = resolveNamesToUnsubscribe(from: subscription, type: .channelGroup)

    deregisterSubscription(with: subscription.uuid)

    strategy.unsubscribe(from: channelsToUnsubscribe, and: groupsToUnsubscribe)
  }

  // Returns a boolean indicating whether there are subscription objects that subscribe to at least one name
  /// Determines whether the given subscription shares any channel or channel-group name with other registered subscriptions.
  /// - Parameters:
  ///   - subscription: The subscription whose channel and channel-group names will be checked for overlap with other registered subscriptions.
  /// - Returns: `true` if at least one other registered subscription shares a channel or channel-group name with `subscription`, `false` otherwise.
  func hasOverlappingSubscriptions(for subscription: any SubscriptionInterface) -> Bool {
    let allNames = Set(subscription.channelNames + subscription.channelGroupNames)

    let remainingAdapters = adapterMap.lockedRead { map in
      map.filter { $0.key != subscription.uuid && $0.key != globalEventsListener.uuid }
    }

    return remainingAdapters.values
      .compactMap { $0.receiver as? (any SubscriptionInterface) }
      .contains { receiver in
        let receiverNames = Set(receiver.channelNames + receiver.channelGroupNames)
        return !receiverNames.isDisjoint(with: allNames)
      }
  }

  /// Selects which channel or channel-group names from a subscription should be unsubscribed.
  /// 
  /// Returns the subscription's names for the specified `type` unless the list is empty or other active subscriptions overlap those names.
  /// - Parameters:
  ///   - subscription: The subscription to evaluate.
  ///   - type: The subscribable type (`.channel` or `.channelGroup`) whose names to resolve.
  /// - Returns: An array of names to unsubscribe for the given `type`; returns an empty array if there are no names of that type or if other subscriptions share those names.
  private func resolveNamesToUnsubscribe(
    from subscription: any SubscriptionInterface,
    type: SubscribableType
  ) -> [String] {
    let names = type == .channel ? subscription.channelNames : subscription.channelGroupNames
    if names.isEmpty { return [] }
    if hasOverlappingSubscriptions(for: subscription) { return [] }
    return names
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
  /// Converts incoming subscribe payloads into `PubNubEvent` objects and dispatches them to the session and its registered listeners.
  /// - Parameters:
  ///   - payloads: The raw subscribe message payloads to process.
  /// - Returns: The array of `PubNubEvent` objects produced from the provided payloads.
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
