//
//  PubNub+Subscribable.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// Protocol for types capable of creating references for entities to which the user can subscribe,
/// receiving real-time updates.
public protocol EntityCreator {
  /// Creates a new channel entity the user can subscribe to.
  ///
  /// This method does not create any entity, either locally or remotely; it merely provides
  /// a reference to a channel that can be subscribed to and unsubscribed from
  ///
  /// - Parameters:
  ///   - name: The unique identifier for the channel.
  /// - Returns: A `ChannelRepresentation` object representing the channel.
  func channel(_ name: String) -> ChannelRepresentation

  /// Creates a new channel group entity the user can subscribe to.
  ///
  /// - Parameters:
  ///   - name: The unique identifier for the channel group.
  /// - Returns: A `ChannelGroupRepresentation` object representing the channel group.
  func channelGroup(_ name: String) -> ChannelGroupRepresentation

  /// Creates user metadata entity the user can subscribe to.
  ///
  /// This method does not create any entity, either locally or remotely; it merely provides
  /// a reference to a channel that can be subscribed to and unsubscribed from
  ///
  /// - Parameters:
  ///   - name: The unique identifier for the user metadata.
  /// - Returns: A `UserMetadataRepresentation` object representing the user metadata.
  func userMetadata(_ name: String) -> UserMetadataRepresentation

  /// Creates channel metadata entity the user can subscribe to.
  ///
  /// This method does not create any entity, either locally or remotely; it merely provides
  /// a reference to a channel that can be subscribed to and unsubscribed from
  ///
  /// - Parameters:
  ///   - name: The unique identifier for the channel metadata.
  /// - Returns: A `ChannelMetadataRepresentation` object representing the channel metadata.
  func channelMetadata(_ name: String) -> ChannelMetadataRepresentation
}

public extension EntityCreator {
  /// Creates a `SubscriptionSet` object from the collection of `Subscribable` entites.
  ///
  /// Use this function to set up and manage subscriptions for a collection of `Subscribable` entities.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled
  ///   - entities: A collection of `Subscribable` entities to subscribe to
  ///   - options: Additional options for configuring the subscription
  /// - Returns: A `SubscriptionSet` instance for managing the specified entities.
  func subscription(
    queue: DispatchQueue = .main,
    entities: any Collection<Subscribable>,
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) -> SubscriptionSet {
    SubscriptionSet(
      queue: queue,
      entities: entities,
      options: options
    )
  }
}

// This internal protocol is designed for types capable of receiving an intent
// to Subscribe or Unsubscribe and invoking the PubNub service with computed channels
// and channel groups.
protocol SubscribeReceiver: AnyObject {
  func registerAdapter(_ adapter: BaseSubscriptionListenerAdapter)
  func hasRegisteredAdapter(with uuid: UUID) -> Bool

  func internalSubscribe(
    with channels: [Subscription],
    and groups: [Subscription],
    at timetoken: Timetoken?
  )
  func internalUnsubscribe(
    from channels: [Subscription],
    and groups: [Subscription],
    presenceOnly: Bool
  )
}
