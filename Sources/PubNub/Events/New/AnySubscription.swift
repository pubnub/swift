//
//  AnySubscription.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A type-erased wrapper for `SubscriptionInterface`
public final class AnySubscription: InternalSubscriptionInterface {
  // The underlying subscription interface that this type erases
  let box: InternalSubscriptionInterface

  /// Creates a type-erased wrapper for any type conforming to `SubscriptionInterface`
  ///
  /// - Parameter subscription: The subscription to wrap
  /// - Returns: A type-erased wrapper for the subscription
  public init<T: SubscriptionInterface>(_ subscription: T) {
    self.box = subscription.eraseToAnySubscription()
  }

  var pubnub: PubNub? { box.pubnub }
  var subscriptionTopology: [SubscribeTargetType: [String]] { box.subscriptionTopology }
  var listenersCache: SubscriptionListenersContainer { box.listenersCache }

  public var queue: DispatchQueue { box.queue }
  public var uuid: UUID { box.uuid }
  public var isDisposed: Bool { box.isDisposed }
  public var eventListeners: [EventListener] { box.eventListeners }
  public var options: SubscriptionOptions { box.options }

  public var onEvent: ((PubNubEvent) -> Void)? {
    get { box.onEvent }
    set { box.onEvent = newValue }
  }

  public var onEvents: (([PubNubEvent]) -> Void)? {
    get { box.onEvents }
    set { box.onEvents = newValue }
  }

  public var onMessage: ((PubNubMessage) -> Void)? {
    get { box.onMessage }
    set { box.onMessage = newValue }
  }

  public var onSignal: ((PubNubMessage) -> Void)? {
    get { box.onSignal }
    set { box.onSignal = newValue }
  }

  public var onPresence: ((PubNubPresenceChange) -> Void)? {
    get { box.onPresence }
    set { box.onPresence = newValue }
  }

  public var onMessageAction: ((PubNubMessageActionEvent) -> Void)? {
    get { box.onMessageAction }
    set { box.onMessageAction = newValue }
  }

  public var onFileEvent: ((PubNubFileChangeEvent) -> Void)? {
    get { box.onFileEvent }
    set { box.onFileEvent = newValue }
  }

  public var onAppContext: ((PubNubAppContextEvent) -> Void)? {
    get { box.onAppContext }
    set { box.onAppContext = newValue }
  }

  public func subscribe(with timetoken: Timetoken?) {
    box.subscribe(with: timetoken)
  }

  public func unsubscribe() {
    box.unsubscribe()
  }

  public func clone() -> AnySubscription {
    box.clone().eraseToAnySubscription()
  }

  public func dispose() {
    box.dispose()
  }

  public func addEventListener(_ listener: EventListener) {
    box.addEventListener(listener)
  }

  public func removeEventListener(_ listener: EventListener) {
    box.removeEventListener(listener)
  }

  public func removeAllListeners() {
    box.removeAllListeners()
  }

  func shouldProcessSubscription(_ subscription: InternalSubscriptionInterface) -> Bool {
    box.shouldProcessSubscription(subscription)
  }

  func onPayloadsReceived(payloads: [SubscribeMessagePayload]) {
    box.onPayloadsReceived(payloads: payloads)
  }
}

// MARK: - Hashable

extension AnySubscription: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }

  public static func == (lhs: AnySubscription, rhs: AnySubscription) -> Bool {
    lhs.uuid == rhs.uuid
  }
}
