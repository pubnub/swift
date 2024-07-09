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
  /// Attempting to connect to a remote system
  @available(*, deprecated, message: "This case will be removed in future versions")
   case connecting
  /// Successfully connected to a remote system
  case connected
  /// Explicit disconnect from a remote system
  case disconnected
  /// Attempting to reconnect to a remote system
  @available(*, deprecated, message: "This case will be removed in future versions")
  case reconnecting
  /// Unexpected disconnect from a remote system
  case disconnectedUnexpectedly(PubNubError)
  /// Unable to establish initial connection. Applies if `enableEventEngine` in `PubNubConfiguration` is true.
  case connectionError(PubNubError)
  /// SDK subscribed with a new mix of channels (fired every time the channel/channel group mix changed)
  /// since the initial connection
  case subscriptionChanged(channels: [String], groups: [String])

  /// If the connection is connected or attempting to connect
  public var isActive: Bool {
    switch self {
    case .connecting, .connected, .reconnecting, .subscriptionChanged:
      return true
    default:
      return false
    }
  }

  /// If the connection is connected
  public var isConnected: Bool {
    if case .connected = self {
      return true
    } else {
      return false
    }
  }

  public static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
    switch (lhs, rhs) {
    case (.connecting, .connecting):
      return true
    case (.reconnecting, .reconnecting):
      return true
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
    case (.connecting, .connected):
      return true
    case (.connecting, .disconnected):
      return true
    case (.connecting, .disconnectedUnexpectedly):
      return true
    case (.connecting, .connectionError):
      return true
    case (.connected, .disconnected):
      return true
    case (.connected, .subscriptionChanged):
      return true
    case (.reconnecting, .connected):
      return true
    case (.reconnecting, .disconnected):
      return true
    case (.reconnecting, .disconnectedUnexpectedly):
      return true
    case (.reconnecting, .connectionError):
      return true
    case (.disconnected, .connecting):
      return true
    case (.disconnectedUnexpectedly, .connecting):
      return true
    case (.connectionError, .connecting):
      return true
    default:
      return false
    }
  }
}
