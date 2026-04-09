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

/// A final class representing a PubNub subscription.
///
/// Use this class to create and manage subscriptions for a specific `Subscribable` entity.
/// Utilize closures inherited from `EventListenerInterface` for the handling of subscription-related events.
/// You can also create an additional `EventListener` and register it by calling `addEventListener(_:)`.
public final class Subscription: BaseSubscription {
  public let entity: Subscribable

  @AtomicWrapper private var timetoken: Timetoken?

  /// Initializes a `Subscription` object.
  ///
  /// - Parameters:
  ///   - queue: An underlying queue to dispatch events
  ///   - entity: An object that should be added to the Subscribe loop.
  ///   - options: Additional subscription options
  public init(queue: DispatchQueue = .main, entity: Subscribable, options: SubscriptionOptions = .empty()) {
    self.entity = entity
    super.init(queue: queue, options: SubscriptionOptions.empty() + options)
  }

  /// Unsubscribes the subscription when it is disposed.
  override func onDispose() {
    unsubscribe()
  }

  var pubnub: PubNub? {
    entity.pubnub
  }

  var subscriptionNames: [String] {
    let hasPresenceOption = options.hasPresenceOption()
    let name = entity.name

    switch entity {
    case is ChannelRepresentation:
      return hasPresenceOption ? [name, name.presenceChannelName] : [name]
    case is ChannelGroupRepresentation:
      return hasPresenceOption ? [name, name.presenceChannelName] : [name]
    default:
      return [entity.name]
    }
  }
}

// MARK: - SubscriptionInterface

extension Subscription: SubscriptionInterface {
  public var channelNames: [String] {
    entity.subscriptionType == .channel ? subscriptionNames : []
  }

  public var channelGroupNames: [String] {
    entity.subscriptionType == .channelGroup ? subscriptionNames : []
  }

  /// Creates a clone of the current instance of `Subscription`.
  ///
  /// Use this method to create a new instance with the same configuration as the current `Subscription`.
  /// Creates a copy of the subscription preserving its queue, entity, and options.
  ///
  /// If the original subscription is registered with a `PubNub` instance, the cloned subscription will be registered with the same `PubNub`.
  /// - Returns: A new `Subscription` configured with the same `queue`, `entity`, and `options`.
  public func clone() -> Subscription {
    let clonedSubscription = Subscription(
      queue: queue,
      entity: entity,
      options: options
    )
    if let pubnub = pubnub, pubnub.hasRegisteredSubscription(with: uuid) {
      pubnub.registerSubscription(clonedSubscription)
    }
    return clonedSubscription
  }

  /// Subscribes to the associated `entity` with the specified timetoken.
  ///
  /// Starts receiving events for this subscription's entity beginning at the specified timetoken.
  /// If the subscription has been disposed or there is no associated `PubNub` instance, this call has no effect.
  /// - Parameters:
  ///   - timetoken: The timetoken to begin subscribing from. Pass `nil` to let the service determine the starting position.
  public func subscribe(with timetoken: Timetoken?) {
    guard let pubnub = pubnub, !isDisposed else {
      return
    }
    pubnub.internalSubscribe(with: self, at: timetoken)
  }

  /// Unsubscribes from the associated entity, ending the PubNub subscription.
  ///
  /// Use this method to gracefully end the subscription and stop receiving messages for the associated entity.
  /// If there are no remaining subscriptions that match the associated entity, the unsubscribe action will be performed,
  /// and the entity will be deregistered from the Subscribe loop. After unsubscribing, the subscription interface
  /// Cancels this subscription with the associated PubNub client.
  /// 
  /// If the subscription has no associated `PubNub` instance or has already been disposed, this method does nothing.
  public func unsubscribe() {
    guard let pubnub = pubnub, !isDisposed else {
      return
    }
    pubnub.internalUnsubscribe(from: self)
  }
}

// MARK: - SubscribeMessagesReceiver

extension Subscription: SubscribeMessagesReceiver {
  /// Processes incoming subscribe message payloads and emits the resulting events to this subscription and its attached listeners.
  /// - Parameter payloads: The received subscribe message payloads to convert and emit.
  /// - Returns: The array of `PubNubEvent` instances that were emitted.
  @discardableResult
  func onPayloadsReceived(payloads: [SubscribeMessagePayload]) -> [PubNubEvent] {
    let events = payloads.compactMap { event(from: $0) }
    // Emit events to the current Subscription's closures
    emit(events: events)
    // Emits events to the underlying attached listeners
    listenersContainer.eventListeners.forEach { $0.emit(events: events) }
    // Returns events that were emitted
    return events
  }

  /// Converts a received subscribe payload into a `PubNubEvent` when it belongs to this subscription and satisfies timing and filter criteria.
  /// 
  /// The payload is accepted only if its publish timetoken is greater than or equal to the subscription's stored timetoken and the payload's channel/subscription matches this subscription's entity. If accepted, the payload is converted to a `PubNubEvent` and returned only when it satisfies the subscription's filter criteria.
  /// - Returns: The `PubNubEvent` created from `payload` if it matches the subscription and filter criteria, `nil` otherwise.
  private func event(from payload: SubscribeMessagePayload) -> PubNubEvent? {
    let isNewerOrEqualToTimetoken = payload.publishTimetoken.timetoken >= timetoken ?? 0
    let isMatchingEntity: Bool

    if entity.subscriptionType == .channel {
      isMatchingEntity = isMatchingEntityName(entity.name, string: payload.channel)
    } else if entity.subscriptionType == .channelGroup {
      isMatchingEntity = isMatchingEntityName(entity.name, string: payload.subscription ?? payload.channel)
    } else {
      isMatchingEntity = true
    }

    if isMatchingEntity && isNewerOrEqualToTimetoken {
      let event = payload.asPubNubEvent()
      return options.filterCriteriaSatisfied(event: event) ? event : nil
    } else {
      return nil
    }
  }

  /// Determines whether the subscription entity name matches the given string, supporting a trailing `.*` wildcard.
  /// 
  /// If `entityName` does not end with `.*`, compares `entityName` (after trimming any presence-channel suffix) for exact equality with `string`.
  /// If `entityName` ends with `.*`, compares the prefix of both names up to their last `.` and returns `true` when those prefixes are equal.
  /// - Parameters:
  ///   - entityName: The subscription entity name; may end with `.*` to indicate a wildcard match or include a presence-channel suffix.
  ///   - string: The candidate channel or subscription string to match against.
  /// - Returns: `true` when `string` matches `entityName` according to the rules above, `false` otherwise.
  private func isMatchingEntityName(_ entityName: String, string: String) -> Bool {
    guard entityName.hasSuffix(".*") else {
      return entityName.trimmingPresenceChannelSuffix == string
    }
    if let firstIndex = entityName.lastIndex(of: "."), let secondIndex = string.lastIndex(of: ".") {
      return entityName.prefix(upTo: firstIndex) == string.prefix(upTo: secondIndex)
    }
    return false
  }
}
