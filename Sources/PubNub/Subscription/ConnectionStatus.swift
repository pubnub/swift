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

  /// If the connection is connected or attempting to connect
  public var isActive: Bool {
    switch self {
    case .connecting, .connected, .reconnecting:
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
