//
//  ListenersPOC.swift
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

/// A base class for entities that can be subscribed to and unsubscribed from using the PubNub service.
public class Subscribable: Subscriber {
  /// An entity name
  public let name: String
  /// The PubNub client associated with this channel.
  weak var pubnub: PubNub?
  /// An underlying subscription type
  let subscriptionType: SubscribableType

  init(name: String, subscriptionType: SubscribableType, pubnub: PubNub) {
    self.name = name
    self.subscriptionType = subscriptionType
    self.pubnub = pubnub
  }
}

enum SubscribableType {
  case channel
  case channelGroup
}

/// Provides the ability to return a `Subscription` object for the underlying entity
///
/// Subsequent calls to `.subscribe()` on the obtained `Subscription` instance will initiate the subscription.
/// Similarly, a subsequent call to `.unsubscribe()` will attempt to deregister the underlying entity from
/// the Subscribe loop if there are no active subscriptions matching the given entity.
public protocol Subscriber {
  /// Creates a `Subscription` object with the specified queue and options.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled.
  ///   - options: Additional options for configuring the subscription.
  func subscription(queue: DispatchQueue, options: SubscriptionOptions) -> Subscription
}

/// Provides a default subscription object for the conforming entity like `ChannelRepresentation`,
/// `ChannelGroupRepresentation`,`ChannelMetadataRepresentation`, and `UserMetadataRepresentation`
public extension Subscriber where Self: Subscribable {
  /// Creates a `Subscription` object with default options for the conforming entity.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled
  ///   - options: Additional options for configuring the subscription
  func subscription(
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

/// A typealias representing an interface for PubNub subscriptions.
///
/// This alias combines the conformance of `EventListenerInterface` and `SubscribeCapable`.
/// Thus, objects conforming to this type can both emit PubNub events and perform subscription-related actions.
public typealias SubscriptionInterface = EventListenerInterface & SubscriptionDisposable & SubscribeCapable
