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
  weak var receiver: SubscribeReceiver?
  /// An underlying subscription type
  let subscriptionType: SubscribableType

  init(name: String, subscriptionType: SubscribableType, receiver: SubscribeReceiver) {
    self.name = name
    self.subscriptionType = subscriptionType
    self.receiver = receiver
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
/// This alias combines the conformance of `EventEmitter` and `SubscribeCapable`.
/// Thus, objects conforming to this type can both emit PubNub events and perform subscription-related actions.
public typealias SubscriptionInterface = EventEmitter & SubscriptionDisposable & SubscribeCapable

/// A class representing subscription options for PubNub subscriptions.
///
/// Use this class to define various subscription options that can be applied.
public class SubscriptionOptions {
  let allOptions: [SubscriptionOptions]

  init(allOptions: [SubscriptionOptions] = []) {
    self.allOptions = allOptions
  }

  convenience init() {
    self.init(allOptions: [])
  }

  func filterCriteriaSatisfied(event: PubNubEvent) -> Bool {
    allOptions.compactMap {
      $0 as? FilterOption
    }.allSatisfy { filter in
      filter.predicate(event)
    }
  }

  func hasPresenceOption() -> Bool {
    !(allOptions.filter { $0 is ReceivePresenceEvents }.isEmpty)
  }

  /// Provides an instance of `PubNubSubscriptionOptions` with no additional options.
  public static func empty() -> SubscriptionOptions {
    SubscriptionOptions(allOptions: [])
  }

  /// Combines two instances of `PubNubSubscriptionOptions` using the `+` operator.
  ///
  /// - Parameters:
  ///   - lhs: The left-hand side instance.
  ///   - rhs: The right-hand side instance.
  ///
  /// - Returns: A new `SubscriptionOptions` instance combining the options from both instances.
  public static func + (
    lhs: SubscriptionOptions,
    rhs: SubscriptionOptions
  ) -> SubscriptionOptions {
    var lhsOptions: [SubscriptionOptions] = lhs.allOptions
    var rhsOptions: [SubscriptionOptions] = rhs.allOptions

    if lhs.allOptions.isEmpty {
      lhsOptions = [lhs]
    }
    if rhsOptions.isEmpty {
      rhsOptions = [rhs]
    }
    return SubscriptionOptions(allOptions: lhsOptions + rhsOptions)
  }
}

/// A class representing options for receiving presence events in subscriptions.
public class ReceivePresenceEvents: SubscriptionOptions {
  public init() {
    super.init(allOptions: [])
  }
}

/// A class representing a filter with a predicate for subscription options.
public class FilterOption: SubscriptionOptions {
  public let predicate: ((PubNubEvent) -> Bool)

  public init(predicate: @escaping ((PubNubEvent) -> Bool)) {
    self.predicate = predicate
    super.init(allOptions: [])
  }
}
