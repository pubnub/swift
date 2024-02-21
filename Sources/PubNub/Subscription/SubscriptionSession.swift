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

@available(*, deprecated, message: "Subscribe and unsubscribe using methods from a PubNub object")
public class SubscriptionSession: EventEmitter, StatusEmitter {
  /// A unique identifier for subscription session
  public var uuid: UUID {
    strategy.uuid
  }
  
  /// An underlying queue to dispatch events
  public let queue: DispatchQueue
  
  /// PSV2 feature to subscribe with a custom filter expression.
  @available(*, deprecated, message: "Use `subscribeFilterExpression` from a PubNub object")
  public var filterExpression: String? {
    get {
      strategy.filterExpression
    } set {
      strategy.filterExpression = newValue
    }
  }
  
  /// `EventEmitter` conformance
  public var onEvent: ((PubNubEvent) -> Void)?
  public var onEvents: (([PubNubEvent]) -> Void)?
  public var onMessage: ((PubNubMessage) -> Void)?
  public var onSignal: ((PubNubMessage) -> Void)?
  public var onPresence: ((PubNubPresenceChange) -> Void)?
  public var onMessageAction: ((PubNubMessageActionEvent) -> Void)?
  public var onFileEvent: ((PubNubFileChangeEvent) -> Void)?
  public var onAppContext: ((PubNubAppContextEvent) -> Void)?
  
  /// `StatusEmitter` conformance
  public var onConnectionStateChange: ((ConnectionStatus) -> Void)?

  var previousTokenResponse: SubscribeCursor? {
    strategy.previousTokenResponse
  }
  
  var configuration: SubscriptionConfiguration {
    get {
      strategy.configuration
    } set {
      strategy.configuration = newValue
    }
  }
  
  private lazy var globalEventsListener: BaseSubscriptionListenerAdapter = {
    BaseSubscriptionListenerAdapter(
      receiver: self,
      uuid: uuid,
      queue: queue
    )
  }()
  
  private lazy var globalStatusListener: BaseSubscriptionListener = {
    // Creates legacy listener under the hood to capture status changes
    let statusListener = SubscriptionListener(queue: queue)
    // Detects status changes and forwards events to the current instance
    // representing the Subscribe loop's status emitter
    statusListener.didReceiveStatus = { [weak self] statusChange in
      if case .success(let newStatus) = statusChange {
        self?.onConnectionStateChange?(newStatus)
      }
    }
    return statusListener
  }()
  
  private var globalChannelSubscriptions: [String: Subscription] = [:]
  private var globalGroupSubscriptions: [String: Subscription] = [:]
  private let strategy: any SubscriptionSessionStrategy
  
  internal init(
    strategy: any SubscriptionSessionStrategy,
    eventsQueue queue: DispatchQueue = .main
  ) {
    self.strategy = strategy
    self.queue = queue
    self.add(globalEventsListener)
    self.add(globalStatusListener)
  }

  /// Names of all subscribed channels
  ///
  /// This list includes both regular and presence channel names
  public var subscribedChannels: [String] {
    strategy.subscribedChannels
  }
  
  /// List of actively subscribed groups
  public var subscribedChannelGroups: [String] {
    strategy.subscribedChannelGroups
  }

  /// Combined value of all subscribed channels and groups
  public var subscriptionCount: Int {
    strategy.subscriptionCount
  }
  
  /// Current connection status
  public var connectionStatus: ConnectionStatus {
    strategy.connectionStatus
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
    let channelSubscriptions = channels.map {
      channel($0).subscription(
        queue: queue,
        options: withPresence ? ReceivePresenceEvents() : SubscriptionOptions.empty()
      )
    }
    let channelGroupSubscriptions = groups.map {
      channelGroup($0).subscription(
        queue: queue,
        options: withPresence ? ReceivePresenceEvents() : SubscriptionOptions.empty()
      )
    }
    internalSubscribe(
      with: channelSubscriptions,
      and: channelGroupSubscriptions,
      at: cursor?.timetoken
    )
    channelSubscriptions.forEach { subscription in
      subscription.subscriptionNames.flatMap { $0 }.forEach {
        globalChannelSubscriptions[$0] = subscription
      }
    }
    channelGroupSubscriptions.forEach { subscription in
      subscription.subscriptionNames.flatMap { $0 }.forEach {
        globalGroupSubscriptions[$0] = subscription
      }
    }
  }

  /// Reconnect a disconnected subscription stream
  /// - parameter timetoken: The timetoken to subscribe with
  public func reconnect(at cursor: SubscribeCursor? = nil) {
    strategy.reconnect(at: cursor)
  }

  /// Disconnect the subscription stream
  public func disconnect() {
    strategy.disconnect()
  }

  // MARK: - Unsubscribe

  /// Unsubscribe from channels and/or channel groups
  ///
  /// - Parameters:
  ///   - from: List of channels to unsubscribe from
  ///   - and: List of channel groups to unsubscribe from
  ///   - presenceOnly: If true, it only unsubscribes from presence events on the specified channels.
  public func unsubscribe(
    from channels: [String],
    and groups: [String] = [],
    presenceOnly: Bool = false
  ) {
    internalUnsubscribe(
      from: channels.map { Subscription(queue: queue, entity: channel($0)) },
      and: groups.map { Subscription(queue: queue, entity: channelGroup($0)) },
      presenceOnly: presenceOnly
    )
    channels.flatMap {
      presenceOnly ? [$0.presenceChannelName] : [$0, $0.presenceChannelName]
    }.forEach {
      globalChannelSubscriptions.removeValue(forKey: $0)
    }
    groups.flatMap {
      presenceOnly ? [$0.presenceChannelName] : [$0, $0.presenceChannelName]
    }.forEach {
      globalGroupSubscriptions.removeValue(forKey: $0)
    }
  }

  /// Unsubscribe from all channels and channel groups
  public func unsubscribeAll() {
    strategy.unsubscribeAll()
  }
}

// MARK: - SubscribeIntentReceiver

extension SubscriptionSession: SubscribeReceiver {
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
  
  // Maps the raw channel/channel group array to collections of PubNubChannel that should be subscribed to
  // with and without Presence, respectively.
  private typealias SubscribeRetrievalRes = (
    itemsWithPresenceIncluded: [PubNubChannel],
    itemsWithoutPresence: [PubNubChannel]
  )
  // Maps the raw channel/channel group array to collections of `PubNubChannel` that should be unsubscribed to.
  private typealias UnsubscribeRetrievalRes = (
    presenceOnlyItems: [PubNubChannel],
    mainItems: [PubNubChannel]
  )
  
  // Composes final PubNubChannel lists the user should subscribe to
  // according to provided raw input and forwards the result to the underlying Subscription strategy.
  func internalSubscribe(
    with channels: [Subscription],
    and groups: [Subscription],
    at timetoken: Timetoken?
  ) {
    if channels.isEmpty, groups.isEmpty {
      return
    }
    
    let extractingChannelsRes = retrieveItemsToSubscribe(from: channels)
    let extractingGroupsRes = retrieveItemsToSubscribe(from: groups)
    
    channels.forEach { channelSubscription in
      registerAdapter(channelSubscription.adapter)
    }
    groups.forEach { groupSubscription in
      registerAdapter(groupSubscription.adapter)
    }
    strategy.subscribe(
      to: extractingChannelsRes.itemsWithPresenceIncluded + extractingChannelsRes.itemsWithoutPresence,
      and: extractingGroupsRes.itemsWithPresenceIncluded + extractingGroupsRes.itemsWithoutPresence,
      at: SubscribeCursor(timetoken: timetoken)
    )
  }
  
  private func retrieveItemsToSubscribe(from subscriptions: [Subscription]) -> SubscribeRetrievalRes {
    // Detects all Presence channels from provided String array and maps them into PubNubChannel
    // containing the main channel name and the flag indicating the resulting PubNubChannel is subscribed
    // with Presence. Note that Presence channels are supplementary to the main data channels.
    // Therefore, subscribing to a Presence channel alone without its corresponding main channel is not supported.
    let channelsWithPresenceIncluded = Set(subscriptions.flatMap {
      $0.subscriptionNames
    }.filter {
      $0.isPresenceChannelName
    }).map {
      PubNubChannel(channel: $0)
    }
    
    // Detects remaining main channel names without Presence enabled from provided input and ensuring
    // there are no duplicates with the result received from the previous step
    let channelsWithoutPresence = Set(subscriptions.flatMap {
      $0.subscriptionNames
    }.map {
      $0.trimmingPresenceChannelSuffix
    }).symmetricDifference(channelsWithPresenceIncluded.map {
      $0.id
    }).map {
      PubNubChannel(id: $0, withPresence: false)
    }
    
    return SubscribeRetrievalRes(
      itemsWithPresenceIncluded: channelsWithPresenceIncluded,
      itemsWithoutPresence: channelsWithoutPresence
    )
  }
  
  func internalUnsubscribe(
    from channels: [Subscription],
    and channelGroups: [Subscription],
    presenceOnly: Bool
  ) {
    let extractingChannelsRes = extractItemsToUnsubscribe(
      from: channels,
      type: .channel,
      presenceItemsOnly: presenceOnly
    )
    let extractingGroupsRes = extractItemsToUnsubscribe(
      from: channelGroups,
      type: .channelGroup,
      presenceItemsOnly: presenceOnly
    )
    channels.forEach { channelSubscription in
      remove(channelSubscription.adapter)
    }
    channelGroups.forEach { channelGroupSubscription in
      remove(channelGroupSubscription.adapter)
    }
    strategy.unsubscribeFrom(
      mainChannels: extractingChannelsRes.mainItems,
      presenceChannelsOnly: extractingChannelsRes.presenceOnlyItems,
      mainGroups: extractingGroupsRes.mainItems,
      presenceGroupsOnly: extractingGroupsRes.presenceOnlyItems
    )
  }
  
  private func subscriptionCount(for name: String, type: SubscribableType) -> Int {
    subscriptionTopology[type]?.filter { $0 == name }.count ?? 0
  }

  // Creates the final list of Presence channels/channel groups and main channels/channel groups
  // the user should unsubscribe from according to the following rules:
  //
  // 1. Unsubscribes from the main channel happen if:
  //  * There are no references to its Presence equivalent from other subscriptions
  //  * There are no references to the main channel from other subscriptions
  // 2. Unsubscribing from the Presence channel happens if:
  //  * There are no references to it from other subscriptions
  private func extractItemsToUnsubscribe(
    from subscriptions: [Subscription],
    type: SubscribableType,
    presenceItemsOnly: Bool
  ) -> UnsubscribeRetrievalRes {
    let presenceItems = Set(subscriptions.flatMap {
      $0.subscriptionNames
    }).filter {
      $0.isPresenceChannelName
    }.map {
      PubNubChannel(channel: $0)
    }.filter {
      subscriptionCount(for: $0.presenceId, type: type) <= 1
    }
    
    let channels = presenceItemsOnly ? [] : Set(subscriptions.flatMap {
      $0.subscriptionNames
    }).symmetricDifference(presenceItems.map {
      $0.presenceId
    }).map {
      PubNubChannel(id: $0, withPresence: false)
    }.filter {
      subscriptionCount(
        for: $0.presenceId,
        type: type
      ) <= 1 &&
      subscriptionCount(
        for: $0.id,
        type: type
      ) <= 1
    }
    
    return UnsubscribeRetrievalRes(
      presenceOnlyItems: presenceItems,
      mainItems: channels
    )
  }
}

fileprivate extension WeakSet where Element == BaseSubscriptionListener {
  func subscriptions(excluding uuid: UUID? = nil) -> [BaseSubscriptionListenerAdapter] {
    compactMap {
      if let listener = $0 as? BaseSubscriptionListenerAdapter {
        return listener.uuid != uuid ? listener : nil
      } else {
        return nil
      }
    }
  }
}

// MARK: - EntityCreator

extension SubscriptionSession: EntityCreator {
  public func channel(_ name: String) -> ChannelRepresentation {
    ChannelRepresentation(name: name, receiver: self)
  }
  
  public func channelGroup(_ name: String) -> ChannelGroupRepresentation {
    ChannelGroupRepresentation(name: name, receiver: self)
  }
  
  public func userMetadata(_ name: String) -> UserMetadataRepresentation {
    UserMetadataRepresentation(id: name, receiver: self)
  }
  
  public func channelMetadata(_ name: String) -> ChannelMetadataRepresentation {
    ChannelMetadataRepresentation(id: name, receiver: self)
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
  public static func == (lhs: SubscriptionSession, rhs: SubscriptionSession) -> Bool {
    lhs.uuid == rhs.uuid
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }

  public var description: String {
    uuid.uuidString
  }
}

// MARK: - SubscribeMessagePayloadReceiver

extension SubscriptionSession: SubscribeMessagesReceiver {
  var subscriptionTopology: [SubscribableType : [String]] {
    var result: [SubscribableType: [String]] = [:]
    result[.channel] = []
    result[.channelGroup] = []
    
    return strategy.listeners.subscriptions(
      excluding: globalEventsListener.uuid
    ).reduce(into: result) { res, current in
      let currentRes = current.receiver?.subscriptionTopology ?? [:]
      res[.channel]?.append(contentsOf: currentRes[.channel] ?? [])
      res[.channelGroup]?.append(contentsOf: currentRes[.channelGroup] ?? [])
    }
  }
  
  func onPayloadsReceived(payloads: [SubscribeMessagePayload]) -> [PubNubEvent] {
    let events = payloads.map { $0.asPubNubEvent() }
    emit(events: events)
    return events
  }
}
