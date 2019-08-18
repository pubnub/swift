//
//  PresenceChannel.swift
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

public struct PresenceChannel {
  public enum State {
    case initialized
    case joined
    case timedOut
    case left
  }

  public let name: String
  public let presenceName: String

  private var state: [String: Codable]
  public var presenceState: State = .initialized

  public var userState: [String: Codable] {
    get {
      return state
    }
    set {
      state.merge(newValue) { $1 }
    }
  }

  public init(_ name: String, with userState: [String: Codable] = [:], and presenceState: State = .initialized) {
    self.name = name
    presenceName = name.presenceChannelName
    state = userState
    self.presenceState = presenceState
  }
}

extension PresenceChannel: Hashable {
  public func hash(into hasher: inout Hasher) {
    name.hash(into: &hasher)
  }

  public static func == (lhs: PresenceChannel, rhs: PresenceChannel) -> Bool {
    return lhs.name == rhs.name
  }
}

extension PresenceChannel: CustomStringConvertible {
  public var description: String {
    return name
  }
}

extension PresenceChannel: ExpressibleByStringLiteral {
  public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
}
