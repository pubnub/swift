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
  case disconnectedUnexpectedly
  /// Unable to establish initial connection
  case connectionError

  /// If the connection is connected or attempting to connect
  public var isActive: Bool {
    switch self {
    case .connected:
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
  
  func canTransition(to state: ConnectionStatus) -> Bool {
    switch (self, state) {
    case (.connected, .disconnected):
      return true
    case (.disconnected, .connected):
      return true
    case (.connected, .disconnectedUnexpectedly):
      return true
    case (.disconnected, .connectionError):
      return true
    default:
      return false
    }
  }
}
