//
//  SubscriptionInterface.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

public protocol SubscriptionInterface: SubscribeCapable, EventListenerInterface, EventListenerHandler {
  /// Determines whether current emitter is disposed
  var isDisposed: Bool { get }
  /// Stops listening to incoming events and disposes current emitter
  func dispose()
  /// Creates a clone of the current instance of `Subscription`.
  func clone() -> Self
}

public extension SubscriptionInterface {
  func eraseToAnySubscription() -> AnySubscription {
    AnySubscription(self)
  }
}

protocol SubscriptionInternalInterface: SubscriptionInterface {
  var pubnub: PubNub? { get }
  var subscriptionTopology: [SubscribeTargetType: [String]] { get }
}
