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

/// A group of `Subscription` managed as one unit.
///
/// Handle events with the closures inherited from `EventListenerInterface`,
/// or register additional listeners with `addEventListener(_:)`.
public final class SubscriptionSet: EventListenerInterface, SubscriptionDisposable, EventListenerHandler {
  @available(*, deprecated, message: "Use the granular callbacks (onMessage, onSignal, onPresence, etc.) instead")
  public var onEvent: ((PubNubEvent) -> Void)?
  @available(*, deprecated, message: "Use the granular callbacks (onMessage, onSignal, onPresence, etc.) instead")
  public var onEvents: (([PubNubEvent]) -> Void)?
  public var onMessage: ((PubNubMessage) -> Void)?
  public var onSignal: ((PubNubMessage) -> Void)?
  public var onPresence: ((PubNubPresenceChange) -> Void)?
  public var onMessageAction: ((PubNubMessageActionEvent) -> Void)?
  public var onFileEvent: ((PubNubFileChangeEvent) -> Void)?
  public var onAppContext: ((PubNubAppContextEvent) -> Void)?
  public var onDataSync: ((PubNubDataSyncEvent) -> Void)?

  public let queue: DispatchQueue
  /// Additional subscription options
  public let options: SubscriptionOptions
  /// A unique identifier for `SubscriptionSet`
  public let uuid: UUID = UUID()
  /// Whether the set is disposed
  public var isDisposed: Bool { isDisposedContainer.lockedRead { $0 } }

  let isDisposedContainer: Atomic<Bool> = Atomic(false)
  let currentSubscriptions: Atomic<Set<Subscription>>
  let listenersContainer: SubscriptionListenersContainer = .init()

  // Internally intercepts messages from the Subscribe loop
  // and forwards them to the current instance
  lazy var adapter = BaseSubscriptionListenerAdapter(
    receiver: self,
    uuid: uuid,
    queue: queue
  )

  init(queue: DispatchQueue = .main, targets: any Collection<Subscribable> = [], options: SubscriptionOptions = .empty()) {
    self.queue = queue
    self.options = SubscriptionOptions.empty() + options
    self.currentSubscriptions = Atomic(Set(targets.map { Subscription(queue: queue, target: $0, options: options) }))
  }

  init(queue: DispatchQueue = .main, subscriptions: any Collection<Subscription> = [], options: SubscriptionOptions = .empty()) {
    self.queue = queue
    self.options = options
    self.currentSubscriptions = Atomic(Set(subscriptions))
  }

  /// Adds a `Subscription` to the set.
  ///
  /// - Parameter subscription: `Subscription` to add
  public func add(subscription: Subscription) {
    currentSubscriptions.lockedWrite { $0.insert(subscription) }
  }

  /// Adds a collection of `Subscription` to the set.
  ///
  /// - Parameter subscriptions: `Subscription` values to add
  public func add(subscriptions: any Collection<Subscription>) {
    currentSubscriptions.lockedWrite {
      for subscription in subscriptions {
        $0.insert(subscription)
      }
    }
  }

  /// Removes a `Subscription` from the set.
  ///
  /// - Parameter subscription: `Subscription` to remove
  public func remove(subscription: Subscription) {
    currentSubscriptions.lockedWrite { $0.remove(subscription) }
  }

  /// Removes a collection of `Subscription` from the set.
  ///
  /// - Parameter subscriptions: `Subscription` values to remove
  public func remove(subscriptions: any Collection<Subscription>) {
    currentSubscriptions.lockedWrite {
      for subscription in subscriptions {
        $0.remove(subscription)
      }
    }
  }

  /// Creates an independent copy of this `SubscriptionSet` with the same configuration.
  public func clone() -> SubscriptionSet {
    let existingSubscriptions = currentSubscriptions.lockedRead { $0 }

    let clonedSubscriptionSet = SubscriptionSet(
      queue: queue,
      subscriptions: existingSubscriptions.map { $0.clone() },
      options: options
    )

    if let pubnub = existingSubscriptions.first?.pubnub, pubnub.hasRegisteredAdapter(with: uuid) {
      pubnub.registerAdapter(clonedSubscriptionSet.adapter)
    }
    return clonedSubscriptionSet
  }

  /// Ends all subscriptions in the set and releases their resources. A disposed set cannot be restarted.
  public func dispose() {
    clearCallbacks()
    currentSubscriptions.lockedRead { $0 }.forEach { $0.dispose() }
    removeAllListeners()
    isDisposedContainer.lockedWrite { $0 = true }
  }

  /// Adds additional subscription listener
  public func addEventListener(_ listener: EventListener) {
    listenersContainer.storeEventListener(listener)
  }

  /// Removes subscription listener
  public func removeEventListener(_ listener: EventListener) {
    listenersContainer.removeEventListener(listener)
  }

  /// Removes all event listeners
  public func removeAllListeners() {
    listenersContainer.removeAllEventListeners()
  }

  deinit {
    dispose()
  }
}

extension SubscriptionSet: SubscribeCapable {
  /// Starts receiving events for every subscription in the set.
  ///
  /// - Parameter timetoken: The timetoken to subscribe from. If `nil`, `0` is used.
  public func subscribe(with timetoken: Timetoken?) {
    let existingSubscriptions = currentSubscriptions.lockedRead { $0 }

    guard let pubnub = existingSubscriptions.first?.pubnub, !isDisposed else {
      return
    }

    pubnub.registerAdapter(adapter)
    pubnub.internalSubscribe(with: existingSubscriptions.allObjects, at: timetoken)
  }

  /// Stops receiving events for every subscription in the set. The set can be restarted afterwards.
  ///
  /// Names are deregistered from the Subscribe loop only if no other subscription still contributes them.
  public func unsubscribe() {
    let existingSubscriptions = currentSubscriptions.lockedRead { $0 }

    guard let pubnub = existingSubscriptions.first?.pubnub, !isDisposed else {
      return
    }

    pubnub.subscription.remove(adapter)
    pubnub.internalUnsubscribe(from: existingSubscriptions.allObjects)
  }
}

// MARK: - SubscribeMessagesReceiver

extension SubscriptionSet: SubscribeMessagesReceiver {
  var subscriptionTopology: SubscriptionTopology {
    currentSubscriptions.lockedRead { $0 }.reduce(SubscriptionTopology.empty) {
      $0 + $1.subscriptionTopology
    }
  }

  // Processes payloads according to the following rules:
  //
  // 1. Gets a subscription from the associated list of child subscriptions
  // 2. Checks which payloads the currently iterated child subscription can map to events
  // 3. Checks the events result received in the previous step against SubscriptionSet's options
  // 4. Emits filtered events from SubscriptionSet and to additional listeners attached
  @discardableResult func onPayloadsReceived(payloads: [SubscribeMessagePayload]) -> [PubNubEvent] {
    let existingSubscriptions = currentSubscriptions.lockedRead { $0 }

    return existingSubscriptions.reduce(into: [PubNubEvent]()) { accumulatedRes, childSubscription in
      let events = payloads.compactMap { payload in
        childSubscription.event(from: payload)
      }.filter {
        options.filterCriteriaSatisfied(event: $0)
      }
      accumulatedRes.append(contentsOf: events)
      // Emits events to the current SubscriptionSet's closures
      emit(events: events)
      // Emits events to the underlying attached listeners
      listenersContainer.eventListeners.forEach { $0.emit(events: events) }
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
