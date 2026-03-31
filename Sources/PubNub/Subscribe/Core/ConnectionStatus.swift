//
//  ConnectionStatus.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// Status of a connection to a remote system
public enum ConnectionStatus: Equatable {
  /// Successfully connected to a remote system
  case connected
  /// Explicit disconnect from a remote system
  case disconnected
  /// Unexpected disconnect from a remote system
  case disconnectedUnexpectedly(PubNubError)
  /// Unable to establish initial connection. Applies if `enableEventEngine` in `PubNubConfiguration` is true.
  case connectionError(PubNubError)
  /// Indicates that the SDK has subscribed to new channels or channel groups.
  /// This status is triggered each time the channel or channel group mix changes after the initial connection, and it provides all currently subscribed channels and channel groups
  case subscriptionChanged(channels: [String], groups: [String])

  /// If the connection is connected or attempting to connect
  public var isActive: Bool {
    switch self {
    case .connected, .subscriptionChanged:
      return true
    default:
      return false
    }
  }

  /// If the connection is connected
  public var isConnected: Bool {
    if case .connected = self {
      return true
    } else if case .subscriptionChanged = self {
      return true
    } else {
      return false
    }
  }

  public static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
    switch (lhs, rhs) {
    case (.connected, .connected):
      return true
    case (.disconnected, .disconnected):
      return true
    case let (.disconnectedUnexpectedly(lhsError), .disconnectedUnexpectedly(rhsError)):
      return lhsError == rhsError
    case let (.connectionError(lhsError), .connectionError(rhsError)):
      return lhsError == rhsError
    case let (.subscriptionChanged(lhsChannels, lhsGroups), .subscriptionChanged(rhsChannels, rhsGroups)):
      return Set(lhsChannels) == Set(rhsChannels) && Set(lhsGroups) == Set(rhsGroups)
    default:
      return false
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  func canTransition(to state: ConnectionStatus) -> Bool {
    switch (self, state) {
    case (.disconnected, .connected):
      return true
    case (.disconnected, .connectionError):
      return true
    case (.disconnected, .disconnectedUnexpectedly):
      return true
    case (.disconnectedUnexpectedly, .connected):
      return true
    case (.disconnectedUnexpectedly, .disconnected):
      return true
    case (.connected, .subscriptionChanged):
      return true
    case (.connected, .disconnected):
      return true
    case (.connected, .disconnectedUnexpectedly):
      return true
    case (.subscriptionChanged, .disconnectedUnexpectedly):
      return true
    case (.subscriptionChanged, .disconnected):
      return true
    default:
      return false
    }
  }
}
