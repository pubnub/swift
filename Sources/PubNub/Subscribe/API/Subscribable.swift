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

/// The base class for references you can create a `Subscription` from.
public class Subscribable {
  weak var pubnub: PubNub?

  init(pubnub: PubNub?) {
    self.pubnub = pubnub
  }

  // Declares what this value contributes to the Subscribe loop: which names join the channel list, which join the
  // channel group list, and whether they expand to presence names. Subclasses own their identifiers, so each one
  // overrides this, and may contribute several names rather than being limited to one.
  func subscriptionTopology(includingPresence: Bool) -> SubscriptionTopology {
    .empty
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
      target: self,
      options: options
    )
  }
}

//// The names a value contributes to the Subscribe loop, grouped by the list each name joins.
struct SubscriptionTopology: Hashable {
  // Names sent to the Subscribe loop as channels
  var channels: [String] = []
  // Names sent to the Subscribe loop as channel groups
  var channelGroups: [String] = []

  // A topology contributing no names
  static let empty = SubscriptionTopology()

  var isEmpty: Bool {
    channels.isEmpty && channelGroups.isEmpty
  }

  // Whether any name is shared with `other` within the same list
  func intersects(_ other: SubscriptionTopology) -> Bool {
    !Set(channels).isDisjoint(with: other.channels) || !Set(channelGroups).isDisjoint(with: other.channelGroups)
  }

  static func + (lhs: Self, rhs: Self) -> Self {
    Self(
      channels: lhs.channels + rhs.channels,
      channelGroups: lhs.channelGroups + rhs.channelGroups
    )
  }
}

extension SubscriptionTopology {
  // Whether the payload was delivered because of one of the names in this topology.
  //
  // Channel names are matched against the channel the message was published to, while channel
  // group names are matched against the subscription that caused the delivery.
  func matches(_ payload: SubscribeMessagePayload) -> Bool {
    channels.contains {
      Self.isMatching($0, string: payload.channel)
    } || channelGroups.contains {
      Self.isMatching($0, string: payload.subscription ?? payload.channel)
    }
  }

  private static func isMatching(_ name: String, string: String) -> Bool {
    guard name.hasSuffix(".*") else {
      return name.trimmingPresenceChannelSuffix == string
    }
    if let firstIndex = name.lastIndex(of: "."), let secondIndex = string.lastIndex(of: ".") {
      return name.prefix(upTo: firstIndex) == string.prefix(upTo: secondIndex)
    }
    return false
  }
}

/// A typealias representing an interface for PubNub subscriptions.
public typealias SubscriptionInterface = EventListenerInterface & SubscriptionDisposable & SubscribeCapable
