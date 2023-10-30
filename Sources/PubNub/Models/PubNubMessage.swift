//
//  PubNubMessage.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public enum PubNubMessageType: Int, Codable, Hashable {
  case message = 0
  case signal = 1
  case object = 2
  case messageAction = 3
  case file = 4

  case unknown = 999
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
  /// The channel group or wildcard subscription match (if exists)
  var subscription: String? { get }
  /// Timetoken for the message
  var published: Timetoken { get set }
  /// Meta information for the message
  var metadata: JSONCodable? { get set }
  /// The type of message that was received
  var messageType: PubNubMessageType { get set }

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

  public var messageType: PubNubMessageType

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
      subscription: subscribe.subscription,
      published: subscribe.publishTimetoken.timetoken,
      metadata: subscribe.metadata,
      messageType: subscribe.messageType.asPubNubMessageType
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
      subscription: nil,
      published: history.timetoken,
      metadata: history.meta,
      messageType: history.messageType ?? .unknown
    )
  }

  public init(
    payload: AnyJSON,
    actions: [PubNubMessageActionBase],
    publisher: String?,
    channel: String,
    subscription: String?,
    published: Timetoken,
    metadata: AnyJSON?,
    messageType: PubNubMessageType = .unknown
  ) {
    concretePayload = payload
    concreteMessageActions = actions
    self.publisher = publisher
    self.channel = channel
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
