//
//  PubNubMessage.swift
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

public enum PubNubMessageType: Codable, Hashable {
  case message, signal, object, messageAction, file, user(type: String), unknown
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = .init(rawValue: try container.decode(String.self))
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.rawValue)
  }
  
  public static func == (lhs: PubNubMessageType, rhs: PubNubMessageType) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
}

extension PubNubMessageType: RawRepresentable, CustomStringConvertible {
  public var rawValue: String {
    switch self {
    case .message:
      return "message"
    case .signal:
      return "signal"
    case .object:
      return "object"
    case .messageAction:
      return "messageAction"
    case .file:
      return "file"
    case let .user(type):
      return type
    default:
      return "unknown"
    }
  }
  
  public init(rawValue: String) {
    switch rawValue {
    case "message":
      self = .message
    case "signal":
      self = .signal
    case "object":
      self = .object
    case "messageAction":
      self = .messageAction
    case "file":
      self = .file
    default:
      self = .user(type: rawValue)
    }
  }
  
  public var description: String {
    return self.rawValue
  }
}

extension PubNubMessageType: ExpressibleByStringLiteral {
  fileprivate typealias LegacyPubNubMessageTypes = SubscribeMessagePayload.Action
  
  public init(_ type: String) {
    self.init(rawValue: type)
  }
  
  fileprivate init(from pubNubType: LegacyPubNubMessageTypes?, userType: String?) {
    if let userType = userType {
      self.init(userType)
    } else {
      switch pubNubType {
      case .message:
        self = .message
      case .signal:
        self = .signal
      case .object:
        self = .object
      case .messageAction:
        self = .messageAction
      case .file:
        self = .file
      case .presence, .none:
        self = .unknown
      }
    }
  }
  
  public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
}

/// An event representing a message
public protocol PubNubMessage {
  /// The message sent on the channel
  var payload: JSONCodable { get set }
  /// Message actions associated with this message
  var actions: [PubNubMessageAction] { get set }
  /// Message sender identifier
  var publisher: String? { get set }
  /// The channel for which the message belongs
  var channel: String { get }
  /// Id of space into which message has been published.
  var spaceId: PubNubSpaceId? { get }
  /// The channel group or wildcard subscription match (if exists)
  var subscription: String? { get }
  /// Timetoken for the message
  var published: Timetoken { get set }
  /// Meta information for the message
  var metadata: JSONCodable? { get set }
  /// The type of message that was received
  var messageType: PubNubMessageType? { get set }

  /// Allows for transcoding between different MessageEvent types
  init(from other: PubNubMessage) throws
}

public extension PubNubMessage {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubMessage>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubMessage>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

// MARK: Concrete Base Class

/// The default implementation of the `PubNubMessage` protocol
public struct PubNubMessageBase: PubNubMessage, Codable, Hashable {
  var concretePayload: AnyJSON
  public var publisher: String?
  var concreteMessageActions: [PubNubMessageActionBase]
  public var channel: String
  public var subscription: String?
  public var published: Timetoken
  var concreteMetadata: AnyJSON?

  public var messageType: PubNubMessageType?
  public var spaceId: PubNubSpaceId?

  public var payload: JSONCodable {
    get { return concretePayload }
    set {
      concretePayload = newValue.codableValue
    }
  }

  public var actions: [PubNubMessageAction] {
    get { return concreteMessageActions }
    set(newValue) {
      concreteMessageActions = newValue.compactMap { try? $0.transcode() }
    }
  }

  public var metadata: JSONCodable? {
    get { return concreteMetadata }
    set {
      concreteMetadata = newValue?.codableValue
    }
  }

  public init(from other: PubNubMessage) throws {
    self.init(
      payload: other.payload.codableValue,
      actions: other.actions.compactMap { try? $0.transcode() },
      publisher: other.publisher,
      channel: other.channel,
      spaceId: other.spaceId,
      subscription: other.subscription,
      published: other.published,
      metadata: other.metadata?.codableValue,
      messageType: other.messageType
    )
  }

  init(from subscribe: SubscribeMessagePayload) {
    self.init(
      payload: subscribe.payload,
      actions: [],
      publisher: subscribe.publisher,
      channel: subscribe.channel,
      spaceId: subscribe.spaceId,
      subscription: subscribe.subscription,
      published: subscribe.publishTimetoken.timetoken,
      metadata: subscribe.metadata,
      messageType: PubNubMessageType(from: subscribe.pubNubMessageType, userType: subscribe.userMessageType)
    )
  }

  init(from history: MessageHistoryMessagePayload, on channel: String) {
    let actions = [PubNubMessageActionBase](
      raw: history.actions,
      message: history.timetoken,
      on: channel
    )

    self.init(
      payload: history.message,
      actions: actions,
      publisher: history.uuid,
      channel: channel,
      spaceId: history.spaceId,
      subscription: nil,
      published: history.timetoken,
      metadata: history.meta,
      messageType: PubNubMessageType(from: history.pubNubMessageType, userType: history.userMessageType)
    )
  }

  public init(
    payload: AnyJSON,
    actions: [PubNubMessageActionBase],
    publisher: String?,
    channel: String,
    spaceId: PubNubSpaceId? = nil,
    subscription: String?,
    published: Timetoken,
    metadata: AnyJSON?,
    messageType: PubNubMessageType? = nil
  ) {
    concretePayload = payload
    concreteMessageActions = actions
    self.publisher = publisher
    self.channel = channel
    self.spaceId = spaceId
    self.subscription = subscription
    self.published = published
    concreteMetadata = metadata
    self.messageType = messageType
  }
}

// MARK: - Conversion to Base from Internal

extension MessageHistoryResponse {
  var asPubNubMessagesByChannel: [String: [PubNubMessage]] {
    var messagesByChannel = [String: [PubNubMessage]]()
    channels.keys.forEach { channel in
      messagesByChannel[channel] = channels[channel].map { $0.asPubnubMessage(on: channel) }
    }
    return messagesByChannel
  }

  func asBoundedPage(end: Timetoken? = nil, limit: Int? = nil) -> PubNubBoundedPage? {
    if channels.isEmpty {
      return nil
    }

    if let start = start {
      return PubNubBoundedPageBase(start: start, end: end, limit: limit)
    }

    var payloadStart: Timetoken?
    // Should this return a page per channel?
    for channel in channels.keys {
      if let oldest = channels[channel]?.first?.timetoken, oldest < payloadStart ?? Timetoken.max {
        payloadStart = channels[channel]?.first?.timetoken
      }
    }

    return PubNubBoundedPageBase(start: payloadStart, end: end, limit: limit)
  }
}

extension Array where Element == MessageHistoryMessagePayload {
  func asPubnubMessage(on channel: String) -> [PubNubMessage] {
    return map { PubNubMessageBase(from: $0, on: channel) }
  }
}
