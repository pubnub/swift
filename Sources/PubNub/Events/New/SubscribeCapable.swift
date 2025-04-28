//
//  SubscribeCapable.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A protocol for types that can initiate and manage subscribe and unsubscribe actions.
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
