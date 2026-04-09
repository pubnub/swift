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

/// A final class representing a set of subscriptions.
///
/// Use this class to manage multiple subscriptions concurrently.
/// All subscriptions within the set must belong to the same `PubNub` instance.
/// Utilize closures inherited from `EventListenerInterface` for the handling of subscription-related events.
/// You can also create an additional `EventListener` and register it by calling `addEventListener(_:)`.
public final class SubscriptionSet: BaseSubscription {
  let currentSubscriptions: Atomic<[Subscription]>

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
    self.currentSubscriptions = Atomic(entities.map { .init(queue: queue, entity: $0, options: options) })
    super.init(queue: queue, options: SubscriptionOptions.empty() + options)

    assert(
      Self.belongToSamePubNub(currentSubscriptions.lockedRead { $0 }),
      "All entities in a SubscriptionSet must belong to the same PubNub instance"
    )
  }

  /// Initializes `SubscriptionSet` object with the specified parameters.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled
  ///   - subscriptions: A collection of existing subscriptions to include in the Subscribe loop
  ///   - options: Additional subscription options
  public init(
    queue: DispatchQueue = .main,
    subscriptions: [Subscription] = [],
    options: SubscriptionOptions = .empty()
  ) {
    self.currentSubscriptions = Atomic(subscriptions)
    super.init(queue: queue, options: options)

    assert(
      Self.belongToSamePubNub(subscriptions),
      "All subscriptions in a SubscriptionSet must belong to the same PubNub instance"
    )
  }

  var pubnub: PubNub? {
    currentSubscriptions.lockedRead { $0.first?.pubnub }
  }

  /// Adds a subscription to the existing set of subscriptions.
  ///
  /// - Parameters:
  /// Adds a child subscription to the set if it is not already present and is compatible with the existing subscriptions.
  /// Performs the addition in a thread-safe manner; if a subscription with the same `uuid` already exists or the subscription is not compatible with the current PubNub instance, the call is a no-op.
  /// - Parameter subscription: The `Subscription` to add; ignored when a subscription with the same `uuid` exists or when it would violate the single-PubNub-instance constraint.
  public func add(subscription: Subscription) {
    currentSubscriptions.lockedWrite {
      guard !$0.contains(where: { $0.uuid == subscription.uuid }) else { return }
      guard Self.canAdd(subscription, to: $0) else { return }
      $0.append(subscription)
    }
  }

  /// Adds a collection of subscriptions to the existing set.
  ///
  /// - Parameters:
  /// Adds the given subscriptions to this set, ignoring duplicates and any subscriptions that cannot be added.
  /// - Parameters:
  ///   - subscriptions: An array of subscriptions to add. Subscriptions with a UUID already present in the set are ignored; subscriptions that would violate the "same PubNub instance" constraint are also skipped.
  public func add(subscriptions: [Subscription]) {
    currentSubscriptions.lockedWrite { current in
      for subscription in subscriptions {
        guard !current.contains(where: { $0.uuid == subscription.uuid }) else { continue }
        guard Self.canAdd(subscription, to: current) else { continue }
        current.append(subscription)
      }
    }
  }

  /// Removes a subscription from the existing set of subscriptions.
  ///
  /// - Parameters:
  /// Removes any child subscriptions that have the same `uuid` as the provided subscription.
  /// - Parameter subscription: The subscription whose `uuid` is used to identify and remove matching children; no changes occur if no match is found.
  public func remove(subscription: Subscription) {
    currentSubscriptions.lockedWrite {
      $0.removeAll(where: { $0.uuid == subscription.uuid })
    }
  }

  /// Removes a collection of subscriptions from the existing set.
  ///
  /// - Parameters:
  /// Removes child subscriptions whose UUIDs match any in the provided array.
  /// - Parameters:
  ///   - subscriptions: Subscriptions to remove; any child with a matching `uuid` will be removed. The removal is performed with a thread-safe write to the internal storage.
  public func remove(subscriptions: [Subscription]) {
    currentSubscriptions.lockedWrite { current in
      let uuidsToRemove = Set(subscriptions.map { $0.uuid })
      current.removeAll(where: { uuidsToRemove.contains($0.uuid) })
    }
  }

  /// Performs cleanup when the subscription set is disposed by unsubscribing from the service and disposing each child subscription.
  /// 
  /// This method is invoked as part of the disposal lifecycle to cancel active subscriptions and release child resources.
  override func onDispose() {
    unsubscribe()
    currentSubscriptions.lockedRead { $0 }.forEach { $0.dispose() }
  }

  /// Check whether the given subscriptions reference at most one PubNub instance.
  /// - Parameter subscriptions: The subscriptions to inspect; subscriptions with no associated `pubnub` are ignored.
  /// - Returns: `true` if zero or one distinct `pubnub.instanceID` is found among the subscriptions, `false` otherwise.

  private static func belongToSamePubNub(_ subscriptions: [Subscription]) -> Bool {
    Set(subscriptions.compactMap { $0.pubnub?.instanceID }).count <= 1
  }

  /// Determine whether a subscription may be added to an existing collection by ensuring PubNub instance consistency.
  /// - Parameters:
  ///   - subscription: The subscription proposed for addition.
  ///   - existing: The current list of subscriptions to compare against.
  /// - Returns: `true` if either side lacks a `PubNub` reference or both subscriptions belong to the same `PubNub` instance; `false` otherwise. When `false`, an assertionFailure is triggered.
  private static func canAdd(_ subscription: Subscription, to existing: [Subscription]) -> Bool {
    guard let existingPubNub = existing.first?.pubnub, let newPubNub = subscription.pubnub else {
      return true
    }
    if existingPubNub.instanceID != newPubNub.instanceID {
      assertionFailure("All subscriptions in a SubscriptionSet must belong to the same PubNub instance")
      return false
    }
    return true
  }
}

// MARK: - SubscriptionInterface

extension SubscriptionSet: SubscriptionInterface {
  public var channelNames: [String] {
    currentSubscriptions.lockedRead { $0 }.flatMap { $0.channelNames }
  }

  public var channelGroupNames: [String] {
    currentSubscriptions.lockedRead { $0 }.flatMap { $0.channelGroupNames }
  }

  /// Creates a clone of the current instance of `SubscriptionSet`.
  ///
  /// Use this method to create a new instance with the same configuration as the current `SubscriptionSet`.
  /// Creates a copy of the subscription set with cloned child subscriptions.
  /// - Returns: A new `SubscriptionSet` containing clones of the current children. If the original set is registered with a `PubNub` instance, the cloned set will be registered with that same instance.
  public func clone() -> SubscriptionSet {
    let clonedChildren = currentSubscriptions.lockedRead { $0 }.map { $0.clone() }

    let clonedSubscriptionSet = SubscriptionSet(
      queue: queue,
      subscriptions: clonedChildren,
      options: options
    )

    if let pubnub = pubnub, pubnub.hasRegisteredSubscription(with: uuid) {
      pubnub.registerSubscription(clonedSubscriptionSet)
    }
    return clonedSubscriptionSet
  }

  /// Subscribes to all entities within the current `SubscriptionSet` with the specified timetoken.
  ///
  /// Use this method to initiate or resume subscriptions for all entities within the set.
  /// If a timetoken is provided, it represents the starting point for the subscription.
  /// Otherwise, the `0` timetoken is used.
  ///
  /// Subscribes this subscription set with its associated PubNub instance using the given timetoken.
  /// 
  /// If there is no associated `PubNub` instance or this subscription set has been disposed, this method does nothing.
  /// - Parameter timetoken: The timetoken to use when subscribing; pass `nil` to subscribe without providing a timetoken.
  public func subscribe(with timetoken: Timetoken?) {
    guard let pubnub = pubnub, !isDisposed else { return }
    pubnub.internalSubscribe(with: self, at: timetoken)
  }

  /// Unsubscribes from all entities within the current `SubscriptionSet`. If there are no remaining
  /// subscriptions that match the associated entities, the unsubscribe action will be performed,
  /// and the entities will be deregistered from the Subscribe loop.
  ///
  /// Use this method to gracefully end all subscriptions and stop receiving messages for all
  /// Unsubscribes this subscription set from its associated PubNub client.
  /// - Note: If the set is not registered with a PubNub client or has been disposed, this is a no-op.
  public func unsubscribe() {
    guard let pubnub = pubnub, !isDisposed else { return }
    pubnub.internalUnsubscribe(from: self)
  }
}

// MARK: - SubscribeMessagesReceiver

extension SubscriptionSet: SubscribeMessagesReceiver {
  /// Processes incoming subscribe message payloads through each child subscription, filters the resulting events using the subscription set's options, emits the aggregated events to the set's closures and attached listeners, and returns them.
  /// - Parameter payloads: The subscribe message payloads to be dispatched to child subscriptions.
  /// - Returns: An array of `PubNubEvent` produced by child subscriptions after applying the subscription set's filter criteria.
  @discardableResult func onPayloadsReceived(payloads: [SubscribeMessagePayload]) -> [PubNubEvent] {
    let children = currentSubscriptions.lockedRead { $0 }

    let allEvents = children.reduce(into: [PubNubEvent]()) { accumulatedRes, child in
      let childEvents = child.onPayloadsReceived(payloads: payloads)
      let filtered = childEvents.filter { options.filterCriteriaSatisfied(event: $0) }
      accumulatedRes.append(contentsOf: filtered)
    }

    // Emit events to the current SubscriptionSet's closures
    emit(events: allEvents)
    // Emit events to the underlying attached listeners
    listenersContainer.eventListeners.forEach { $0.emit(events: allEvents) }
    return allEvents
  }
}
