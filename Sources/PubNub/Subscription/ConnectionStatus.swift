//
//  ConnectionStatus.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
