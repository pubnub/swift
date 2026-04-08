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
  ///   - subscription: Subscription to add
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
  ///   - subscriptions: List of subscriptions to add
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
  ///   - subscription: Subscription to remove
  public func remove(subscription: Subscription) {
    currentSubscriptions.lockedWrite {
      $0.removeAll(where: { $0.uuid == subscription.uuid })
    }
  }

  /// Removes a collection of subscriptions from the existing set.
  ///
  /// - Parameters:
  ///   - subscriptions: Collection of subscriptions to remove
  public func remove(subscriptions: [Subscription]) {
    currentSubscriptions.lockedWrite { current in
      let uuidsToRemove = Set(subscriptions.map { $0.uuid })
      current.removeAll(where: { uuidsToRemove.contains($0.uuid) })
    }
  }

  override func onDispose() {
    unsubscribe()
    currentSubscriptions.lockedRead { $0 }.forEach { $0.dispose() }
  }

  // MARK: - Validation

  private static func belongToSamePubNub(_ subscriptions: [Subscription]) -> Bool {
    Set(subscriptions.compactMap { $0.pubnub?.instanceID }).count <= 1
  }

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
  /// The clone is a separate instance that can be used independently.
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
  /// - Parameter timetoken: The timetoken to use for the subscriptions
  public func subscribe(with timetoken: Timetoken?) {
    guard let pubnub = pubnub, !isDisposed else { return }
    pubnub.internalSubscribe(with: self, at: timetoken)
  }

  /// Unsubscribes from all entities within the current `SubscriptionSet`. If there are no remaining
  /// subscriptions that match the associated entities, the unsubscribe action will be performed,
  /// and the entities will be deregistered from the Subscribe loop.
  ///
  /// Use this method to gracefully end all subscriptions and stop receiving messages for all
  /// associated entities. After unsubscribing, the subscription set can be restarted if needed.
  public func unsubscribe() {
    guard let pubnub = pubnub, !isDisposed else { return }
    pubnub.internalUnsubscribe(from: self)
  }
}

// MARK: - SubscribeMessagesReceiver

extension SubscriptionSet: SubscribeMessagesReceiver {
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
