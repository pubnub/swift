//
//  SubscriptionInterface.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

/// A protocol that defines the interface for a subscription.
public protocol SubscriptionInterface: SubscribeCapable, EventListenerInterface, EventListenerHandler {
  /// Determines whether current emitter is disposed
  var isDisposed: Bool { get }
  /// The options for the subscription
  var options: SubscriptionOptions { get }

  /// Stops listening to incoming events and disposes current emitter
  func dispose()
  /// Creates a clone of the current instance of `Subscription`.
  func clone() -> Self
}

/// An extension allowing returning a type-erased subscription
public extension SubscriptionInterface {
  /// Creates a type-erased subscription.
  func eraseToAnySubscription() -> AnySubscription {
    AnySubscription(self)
  }
}

protocol SubscribeMessagesReceiver: AnyObject {
  func onPayloadsReceived(payloads: [SubscribeMessagePayload])
  func shouldProcessSubscription(_ subscription: InternalSubscriptionInterface) -> Bool
}

protocol InternalSubscriptionInterface: SubscriptionInterface, SubscribeMessagesReceiver {
  var pubnub: PubNub? { get }
  var listenersCache: SubscriptionListenersContainer { get }
  var subscriptionTopology: [SubscribeTargetType: [String]] { get }
}

// MARK: - EventListenerHandler conformance

extension InternalSubscriptionInterface {
  public var eventListeners: [EventListener] {
    listenersCache.eventListeners
  }

  public func addEventListener(_ listener: EventListener) {
    listenersCache.storeEventListener(listener)
  }

  public func removeEventListener(_ listener: EventListener) {
    listenersCache.removeEventListener(listener)
  }

  public func removeAllListeners() {
    listenersCache.removeAllEventListeners()
  }
}

// MARK: - SubscribeCapable conformance

extension InternalSubscriptionInterface {
  /// Subscribes with the specified timetoken.
  ///
  /// - Parameter timetoken: The timetoken to use for subscribing. If `nil`, the `0` timetoken is used.
  public func subscribe(with timetoken: Timetoken? = nil) {
    guard let pubnub = pubnub, !isDisposed else { return }
    pubnub.internalSubscribe(subscription: self)
  }

  /// Unsubscribes from, stopping the subscription.
  public func unsubscribe() {
    guard let pubnub = pubnub, !isDisposed else { return }
    pubnub.internalUnsubscribe(subscription: self)
  }
}

// MARK: - SubscribeMessagesReceiver conformance

extension InternalSubscriptionInterface {
  func onPayloadsReceived(payloads: [SubscribeMessagePayload]) {
    let channelEntityNames = subscriptionTopology[.channel] ?? []
    let channelGroupEntityNames = subscriptionTopology[.channelGroup] ?? []

    let events = payloads.filter { payload in
      shouldProcessPayload(
        payload,
        channelNames: channelEntityNames,
        groupNames: channelGroupEntityNames
      )
    }.compactMap {
      $0.asPubNubEvent()
    }

    // Filter events based on the custom provided filter criteria
    let filteredEvents = events.filter { options.filterCriteriaSatisfied(event: $0) }
    // Emit the filtered events
    emit(events: filteredEvents)
    // Emit the filtered events to the event listeners
    eventListeners.forEach { $0.emit(events: filteredEvents) }
  }

  private func shouldProcessPayload(_ payload: SubscribeMessagePayload, channelNames: [String], groupNames: [String]) -> Bool {
    let channel = payload.channel
    let channelGroupIfAny = payload.subscription ?? channel

    let matchesChannel = channelNames.contains { matchesEntityName($0, string: channel) }
    let matchesGroup = groupNames.contains { matchesEntityName($0, string: channelGroupIfAny) }

    return matchesChannel || matchesGroup
  }

  private func matchesEntityName(_ entityName: String, string: String) -> Bool {
    guard entityName.hasSuffix(".*") else {
      return entityName == string
    }
    if let firstIndex = entityName.lastIndex(of: "."), let secondIndex = string.lastIndex(of: ".") {
      return entityName.prefix(upTo: firstIndex) == string.prefix(upTo: secondIndex)
    }
    return false
  }
}
