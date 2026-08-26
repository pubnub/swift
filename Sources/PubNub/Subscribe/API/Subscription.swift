//
//  PubNubSubscription.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A subscription to a single `Subscribable`.
///
/// Handle events with the closures inherited from `EventListenerInterface`,
/// or register additional listeners with `addEventListener(_:)`.
public final class Subscription: EventListenerInterface, SubscriptionDisposable, EventListenerHandler {
  init(queue: DispatchQueue = .main, target: Subscribable, options: SubscriptionOptions = .empty()) {
    let resolvedOptions = SubscriptionOptions.empty() + options

    self.queue = queue
    self.target = target
    self.options = resolvedOptions
    self.subscriptionTopology = target.subscriptionTopology(includingPresence: resolvedOptions.hasPresenceOption())
  }

  public let queue: DispatchQueue
  /// A unique identifier for `Subscription`
  public let uuid: UUID = UUID()
  /// Attached options
  public let options: SubscriptionOptions
  /// Whether the subscription is disposed
  public private(set) var isDisposed = false

  // The stream this subscription receives events for
  let target: Subscribable
  // The names this subscription contributes to the Subscribe loop
  let subscriptionTopology: SubscriptionTopology

  // Stores the timetoken the user subscribed with
  private(set) var timetoken: Timetoken?
  // Stores additional listeners
  private let listenersContainer: SubscriptionListenersContainer = .init()

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

  // Intercepts messages from the Subscribe loop and forwards them to the current `Subscription`
  lazy var adapter = BaseSubscriptionListenerAdapter(
    receiver: self,
    uuid: uuid,
    queue: queue
  )

  internal var pubnub: PubNub? {
    target.pubnub
  }

  /// Creates an independent copy of this `Subscription` with the same configuration.
  public func clone() -> Subscription {
    let clonedSubscription = Subscription(
      queue: queue,
      target: target,
      options: options
    )
    if pubnub?.hasRegisteredAdapter(with: uuid) ?? false {
      pubnub?.registerAdapter(clonedSubscription.adapter)
    }
    return clonedSubscription
  }

  /// Ends the subscription and releases its resources. A disposed `Subscription` cannot be restarted.
  public func dispose() {
    clearCallbacks()
    unsubscribe()
    removeAllListeners()
    isDisposed = true
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

extension Subscription: SubscribeCapable {
  /// Starts receiving events for the associated target.
  ///
  /// - Parameter timetoken: The timetoken to subscribe from. If `nil`, `0` is used.
  public func subscribe(with timetoken: Timetoken?) {
    guard let pubnub = pubnub, !isDisposed else {
      return
    }
    pubnub.internalSubscribe(with: [self], at: timetoken)
  }

  /// Stops receiving events for the associated target. The subscription can be restarted afterwards.
  ///
  /// Names are deregistered from the Subscribe loop only if no other subscription still contributes them.
  public func unsubscribe() {
    guard let pubnub = pubnub, !isDisposed else {
      return
    }
    pubnub.internalUnsubscribe(from: [self])
  }
}

extension Subscription: Hashable {
  public static func == (lhs: Subscription, rhs: Subscription) -> Bool {
    lhs.uuid == rhs.uuid
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }
}

// MARK: - SubscribeMessagesReceiver

extension Subscription: SubscribeMessagesReceiver {
  @discardableResult func onPayloadsReceived(payloads: [SubscribeMessagePayload]) -> [PubNubEvent] {
    let events = payloads.compactMap { event(from: $0) }
    // Emit events to the current Subscription's closures
    emit(events: events)
    // Emits events to the underlying attached listeners
    listenersContainer.eventListeners.forEach { $0.emit(events: events) }
    // Returns events that were emitted
    return events
  }

  func event(from payload: SubscribeMessagePayload) -> PubNubEvent? {
    guard subscriptionTopology.matches(payload), payload.publishTimetoken.timetoken >= timetoken ?? 0 else {
      return nil
    }

    let event = payload.asPubNubEvent()
    return options.filterCriteriaSatisfied(event: event) ? event : nil
  }
}
