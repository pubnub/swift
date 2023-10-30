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
public enum ConnectionStatus {
  /// Attempting to connect to a remote system
  case connecting
  /// Successfully connected to a remote system
  case connected
  /// Attempting to reconnect to a remote system
  case reconnecting
  /// Explicit disconnect from a remote system
  case disconnected
  /// Unexpected disconnect from a remote system
  case disconnectedUnexpectedly

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
    return self == .connected
  }

  func canTransition(to state: ConnectionStatus) -> Bool {
    switch (self, state) {
    case (.connecting, .reconnecting):
      return false
    case (.connecting, _):
      return true
    case (.connected, .connecting):
      return false
    case (.connected, _):
      return true
    case (.reconnecting, .connecting):
      return false
    case (.reconnecting, _):
      return true
    case (.disconnected, .connecting):
      return true
    case (.disconnected, _):
      return false
    case (.disconnectedUnexpectedly, .connecting):
      return true
    case (.disconnectedUnexpectedly, _):
      return false
    }
  }
}
