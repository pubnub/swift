//
//  SubscriptionOptions.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

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
