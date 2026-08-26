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
  /// Returns a reference to the channel with the given name.
  ///
  /// This sends no request and changes nothing on the server.
  ///
  /// - Parameter name: The name of the channel
  /// - Returns: A `Channel` for the given name
  func channel(_ name: String) -> Channel {
    Channel(name: name, pubnub: self)
  }

  /// Returns a reference to the channel group with the given name.
  ///
  /// This sends no request and changes nothing on the server: it neither creates the group nor changes
  /// which channels belong to it.
  ///
  /// - Parameter name: The name of the channel group
  /// - Returns: A `ChannelGroup` for the given name
  func channelGroup(_ name: String) -> ChannelGroup {
    ChannelGroup(name: name, pubnub: self)
  }

  /// Returns a reference to the App Context user metadata record with the given identifier.
  ///
  /// This sends no request and changes nothing on the server: it neither creates nor reads the record.
  ///
  /// - Parameter name: The identifier of the user metadata record
  /// - Returns: A `UserMetadata` for the given identifier
  func userMetadata(_ name: String) -> UserMetadata {
    UserMetadata(id: name, pubnub: self)
  }

  /// Returns a reference to the App Context channel metadata record with the given identifier.
  ///
  /// This sends no request and changes nothing on the server: it neither creates nor reads the record.
  ///
  /// - Parameter name: The identifier of the channel metadata record
  /// - Returns: A `ChannelMetadata` for the given identifier
  func channelMetadata(_ name: String) -> ChannelMetadata {
    ChannelMetadata(id: name, pubnub: self)
  }

  /// Creates a `SubscriptionSet` from a collection of `Subscribable` values.
  ///
  /// Use this function to subscribe to several `Subscribable` values at once.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled
  ///   - targets: The values to receive events for
  ///   - options: Additional options for configuring the subscription
  /// - Returns: A `SubscriptionSet` managing the given values
  func subscription(
    queue: DispatchQueue = .main,
    targets: any Collection<Subscribable>,
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) -> SubscriptionSet {
    SubscriptionSet(
      queue: queue,
      targets: targets,
      options: options
    )
  }

  /// Creates a `SubscriptionSet` from existing `Subscription` values.
  ///
  /// Use this function to manage subscriptions you already created as one unit.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled
  ///   - subscriptions: The existing `Subscription` values to manage together
  ///   - options: Additional options for configuring the subscription
  /// - Returns: A `SubscriptionSet` managing the given subscriptions
  func subscription(
    queue: DispatchQueue = .main,
    subscriptions: any Collection<Subscription>,
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) -> SubscriptionSet {
    SubscriptionSet(
      queue: queue,
      subscriptions: subscriptions,
      options: options
    )
  }
}
