//
//  Subscribable+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public extension PubNub {
  /// Returns a handle to the channel with the given name.
  ///
  /// This sends no request and changes nothing on the server; it only names the channel that can be
  /// subscribed to and unsubscribed from.
  ///
  /// - Parameters:
  ///   - name: The name identifying the channel.
  /// - Returns: A `Channel` handle for that name.
  func channel(_ name: String) -> Channel {
    Channel(name: name, pubnub: self)
  }

  /// Returns a handle to the channel group with the given name.
  ///
  /// This sends no request and changes nothing on the server: it neither creates the group nor alters
  /// which channels belong to it.
  ///
  /// - Parameters:
  ///   - name: The name identifying the channel group.
  /// - Returns: A `ChannelGroup` handle for that name.
  func channelGroup(_ name: String) -> ChannelGroup {
    ChannelGroup(name: name, pubnub: self)
  }

  /// Returns a handle to the stream of App Context changes made to the given user metadata record.
  ///
  /// This sends no request and changes nothing on the server: it neither creates nor reads the record.
  ///
  /// - Parameters:
  ///   - name: The identifier of the user metadata record whose changes should be delivered.
  /// - Returns: A `UserMetadata` handle for that identifier.
  func userMetadata(_ name: String) -> UserMetadata {
    UserMetadata(id: name, pubnub: self)
  }

  /// Returns a handle to the stream of App Context changes made to the given channel metadata record.
  ///
  /// This sends no request and changes nothing on the server: it neither creates nor reads the record.
  ///
  /// - Parameters:
  ///   - name: The identifier of the channel metadata record whose changes should be delivered.
  /// - Returns: A `ChannelMetadata` handle for that identifier.
  func channelMetadata(_ name: String) -> ChannelMetadata {
    ChannelMetadata(id: name, pubnub: self)
  }

  /// Creates a `SubscriptionSet` object from the collection of `Subscribable` values.
  ///
  /// Use this function to set up and manage subscriptions for several `Subscribable` values at once.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled
  ///   - entities: A collection of `Subscribable` values to subscribe to
  ///   - options: Additional options for configuring the subscription
  /// - Returns: A `SubscriptionSet` instance for managing the specified values.
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
