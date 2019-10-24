//
//  MessageEvent.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
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

/// An event representing a message
public protocol MessageEvent: CustomStringConvertible {
  /// Message sender identifier
  var publisher: String? { get }
  /// The message sent on the channel
  var payload: AnyJSON { get }
  /// The channel for which the message belongs
  var channel: String { get }
  /// The channel group or wildcard subscription match (if exists)
  var subscription: String? { get }
  /// Timetoken for the message
  var timetoken: Timetoken { get }
  /// User metadata
  var userMetadata: AnyJSON? { get }
  /// The type of message that was received
  var messageType: MessageType { get }
}

// MARK: - CustomStringConvertible

extension MessageEvent {
  public var description: String {
    return "User '\(publisher ?? "Unknown")' sent '\(payload)' message on '\(channel)' at \(timetoken)"
  }
}

// MARK: - Implementation

extension MessageResponse: MessageEvent, CustomStringConvertible where Payload == AnyJSON {
  public var publisher: String? { return issuer }
  public var subscription: String? { return subscriptionMatch }
  public var timetoken: Timetoken {
    return publishTimetoken.timetoken
  }

  public var userMetadata: AnyJSON? { return metadata }
}
