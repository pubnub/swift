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
  /// The clone is a separate instance that can be used independently.
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
  /// - Parameter timetoken: The timetoken to use for subscribing. If `nil`, the `0` value is used.
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
  /// can be restarted if needed.
  public func unsubscribe() {
    guard let pubnub = pubnub, !isDisposed else {
      return
    }
    pubnub.internalUnsubscribe(from: self)
  }
}

// MARK: - SubscribeMessagesReceiver

extension Subscription: SubscribeMessagesReceiver {
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
