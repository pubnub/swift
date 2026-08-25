//
//  Subscribable.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A protocol for types capable of initiating subscription-related actions.
public protocol SubscribeCapable {
  /// Subscribes with the specified timetoken.
  ///
  /// - Parameter timetoken: The timetoken to use for subscribing. If `nil`, the `0` timetoken is used.
  func subscribe(with timetoken: Timetoken?)

  /// Unsubscribes from, stopping the subscription.
  func unsubscribe()
}

public extension SubscribeCapable {
  /// Subscribes with the `0` timetoken.
  ///
  /// Convenience method equivalent to calling `subscribe(with:)` with `nil`.
  func subscribe() {
    subscribe(with: nil)
  }
}

/// A base class for the named streams that can be subscribed to and unsubscribed from using the PubNub service.
public class Subscribable {
  /// The name this subscribable contributes to the Subscribe loop
  public let name: String
  /// The PubNub client that created this subscribable
  weak var pubnub: PubNub?
  /// Determines whether ``name`` is sent to the Subscribe loop as a channel or as a channel group
  let subscribeTarget: SubscribeTarget

  init(name: String, subscribeTarget: SubscribeTarget, pubnub: PubNub) {
    self.name = name
    self.subscribeTarget = subscribeTarget
    self.pubnub = pubnub
  }

  /// Creates a `Subscription` object for this value.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled
  ///   - options: Additional options for configuring the subscription
  /// - Returns: A `Subscription` instance for managing this value.
  public func subscription(
    queue: DispatchQueue = .main,
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) -> Subscription {
    Subscription(
      queue: queue,
      entity: self,
      options: options
    )
  }
}

/// The bucket a ``Subscribable`` name occupies in the Subscribe loop.
enum SubscribeTarget {
  /// The name is sent as a channel
  case channel
  /// The name is sent as a channel group
  case channelGroup
}

/// A typealias representing an interface for PubNub subscriptions.
///
/// This alias combines the conformance of `EventListenerInterface` and `SubscribeCapable`.
/// Thus, objects conforming to this type can both emit PubNub events and perform subscription-related actions.
public typealias SubscriptionInterface = EventListenerInterface & SubscriptionDisposable & SubscribeCapable
