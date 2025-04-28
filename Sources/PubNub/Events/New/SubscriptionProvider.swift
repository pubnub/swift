//
//  SubscriptionProvider.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A protocol that provides the ability to create and manage subscription objects for entities.
///
/// This protocol allows entities to create `Subscription` objects that can be used to:
/// - Initiate subscriptions through subsequent calls to `.subscribe()`
/// - Manage subscription lifecycle through `.unsubscribe()`
/// - Handle subscription events on specified dispatch queues
public protocol SubscriptionProvider {
  /// Creates a `Subscription` object with the specified queue and options.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled.
  ///   - options: Additional options for configuring the subscription.
  func subscription(queue: DispatchQueue, options: SubscriptionOptions) -> any SubscriptionInterface
}
