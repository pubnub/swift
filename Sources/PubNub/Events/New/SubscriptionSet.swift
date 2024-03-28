//
//  PubNubSubscriptionSet.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A final class representing a set of `Subscription`.
///
/// Use this class to manage multiple `Subscription` concurrently.
public final class SubscriptionSet: EventEmitter, SubscriptionDisposable {
  public var onEvent: ((PubNubEvent) -> Void)?
  public var onEvents: (([PubNubEvent]) -> Void)?
  public var onMessage: ((PubNubMessage) -> Void)?
  public var onSignal: ((PubNubMessage) -> Void)?
  public var onPresence: ((PubNubPresenceChange) -> Void)?
  public var onMessageAction: ((PubNubMessageActionEvent) -> Void)?
  public var onFileEvent: ((PubNubFileChangeEvent) -> Void)?
  public var onAppContext: ((PubNubAppContextEvent) -> Void)?

  public let queue: DispatchQueue
  /// Additional subscription options
  public let options: SubscriptionOptions
  /// A unique identifier for the current `SubscriptionSet`
  public let uuid: UUID = UUID()
  /// Whether current subscription is disposed or not
  public private(set) var isDisposed = false
  // Internally holds a collection of child subscriptions
  private(set) var currentSubscriptions: Set<Subscription>

  // Internally intercepts messages from the Subscribe loop
  // and forwards them to the current `SubscriptionSet`
  lazy var adapter = BaseSubscriptionListenerAdapter(
    receiver: self,
    uuid: uuid,
    queue: queue
  )

  /// Initializes `SubscriptionSet` object with the specified parameters.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled
  ///   - entities: A collection of `Subscribable` entities to include in the Subscribe loop
  ///   - options: Additional subscription options
  public init(
    queue: DispatchQueue = .main,
    entities: any Collection<Subscribable> = [],
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) {
    self.queue = queue
    self.options = SubscriptionOptions.empty() + options
    self.currentSubscriptions = Set(entities.map {
      Subscription(
        queue: queue,
        entity: $0,
        options: options
      )
    })
  }

  /// Initializes `SubscriptionSet` object with the specified parameters.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled
  ///   - subscriptions: A collection of existing `Subscription` instances to include in the Subscribe loop
  ///   - options: Additional subscription options
  public init(
    queue: DispatchQueue = .main,
    subscriptions: any Collection<Subscription> = [],
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) {
    self.queue = queue
    self.options = options
    self.currentSubscriptions = Set(subscriptions)
  }

  /// Adds `Subscription` to the existing set of subscriptions.
  ///
  /// - Parameters:
  ///   - subscription: `Subscription` to add
  public func add(subscription: Subscription) {
    currentSubscriptions.insert(subscription)
  }

  /// Adds a collection of `Subscription` to the existing set of subscriptions.
  ///
  /// - Parameters:
  ///   - subscriptions: List of `Subscription` to add
  public func add(subscriptions: any Collection<Subscription>) {
    subscriptions.forEach {
      currentSubscriptions.insert($0)
    }
  }

  /// Removes `Subscription` from the existing set of subscriptions.
  ///
  /// - Parameters:
  ///   - subscription: `Subscription` to remove
  public func remove(subscription: Subscription) {
    currentSubscriptions.remove(subscription)
  }

  /// Removes a collection of `Subscription` from the existing set of subscriptions.
  ///
  /// - Parameters:
  ///   - subscriptions: Collection of `Subscription` to remove
  public func remove(subscriptions: any Collection<Subscription>) {
    subscriptions.forEach {
      currentSubscriptions.remove($0)
    }
  }

  /// Creates a clone of the current instance of `SubscriptionSet`.
  ///
  /// Use this method to create a new instance with the same configuration as the current `SubscriptionSet`.
  /// The clone is a separate instance that can be used independently.
  public func clone() -> SubscriptionSet {
    let clonedSubscriptionSet = SubscriptionSet(
      queue: queue,
      subscriptions: currentSubscriptions.map { $0.clone() },
      options: options
    )
    if let receiver = currentSubscriptions.first?.receiver, receiver.hasRegisteredAdapter(with: uuid) {
      receiver.registerAdapter(clonedSubscriptionSet.adapter)
    }
    return clonedSubscriptionSet
  }

  /// Disposes of the current instance of `SubscriptionSet`, ending all associated subscriptions.
  ///
  /// Use this method to gracefully end the subscription and release associated resources.
  /// Once disposed, the subscription interface cannot be restarted.
  public func dispose() {
    clearCallbacks()
    currentSubscriptions.forEach { $0.dispose() }
    isDisposed = true
  }

  deinit {
    dispose()
  }
}

extension SubscriptionSet: SubscribeCapable {
  /// Subscribes to all entities within the current `SubscriptionSet` with the specified timetoken.
  ///
  /// Use this method to initiate or resume subscriptions for all entities within the set.
  /// If a timetoken is provided, it represents the starting point for the subscription.
  /// Otherwise, the `0` timetoken is used.
  ///
  /// - Parameter timetoken: The timetoken to use for the subscriptions
  public func subscribe(with timetoken: Timetoken?) {
    guard let receiver = currentSubscriptions.first?.receiver, !isDisposed else {
      return
    }
    receiver.registerAdapter(adapter)
    currentSubscriptions.forEach { receiver.registerAdapter($0.adapter) }

    let channels = currentSubscriptions.filter {
      $0.subscriptionType == .channel
    }.allObjects

    let groups = currentSubscriptions.filter {
      $0.subscriptionType == .channelGroup
    }.allObjects

    receiver.internalSubscribe(
      with: channels,
      and: groups,
      at: timetoken
    )
  }

  /// Unsubscribes from all entities within the current `SubscriptionSet`. If there are no remaining
  /// subscriptions that match the associated entities, the unsubscribe action will be performed,
  /// and the entities will be deregistered from the Subscribe loop.
  ///
  /// Use this method to gracefully end all subscriptions and stop receiving messages for all
  /// associated entities. After unsubscribing, the subscription set can be restarted if needed.
  public func unsubscribe() {
    guard let receiver = currentSubscriptions.first?.receiver, !isDisposed else {
      return
    }
    receiver.internalUnsubscribe(
      from: currentSubscriptions.filter { $0.subscriptionType == .channel },
      and: currentSubscriptions.filter { $0.subscriptionType == .channelGroup },
      presenceOnly: false
    )
  }
}

// MARK: - SubscribeMessagePayloadReceiver

extension SubscriptionSet: SubscribeMessagesReceiver {
  var subscriptionTopology: [SubscribableType: [String]] {
    var result: [SubscribableType: [String]] = [:]
    result[.channel] = []
    result[.channelGroup] = []

    return currentSubscriptions.reduce(into: result, { accumulatedRes, current in
      let currentRes = current.subscriptionTopology
      accumulatedRes[.channel]?.append(contentsOf: currentRes[.channel] ?? [])
      accumulatedRes[.channelGroup]?.append(contentsOf: currentRes[.channelGroup] ?? [])
    })
  }

  // Processes payloads according to the following rules:
  //
  // 1. Gets a subscription from the associated list of child subscriptions
  // 2. Checks which payloads the currently iterated child subscription can map to events
  // 3. Checks the events result received in the previous step against SubscriptionSet's options
  // 4. Emits filtered events from SubscriptionSet
  @discardableResult func onPayloadsReceived(payloads: [SubscribeMessagePayload]) -> [PubNubEvent] {
    currentSubscriptions.reduce(into: [PubNubEvent]()) { accumulatedRes, childSubscription in
      let events = payloads.compactMap { payload in
        childSubscription.event(from: payload)
      }.filter {
        options.filterCriteriaSatisfied(event: $0)
      }
      accumulatedRes.append(contentsOf: events)
      emit(events: events)
    }
  }
}

extension SubscriptionSet: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }

  public static func == (lhs: SubscriptionSet, rhs: SubscriptionSet) -> Bool {
    lhs.uuid == rhs.uuid
  }
}
