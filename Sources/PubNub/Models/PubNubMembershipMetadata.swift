//
//  PubNubMembershipMetadata.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2020 PubNub Inc.
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

// MARK: Outbound Protocol

/// A object capable of representing PubNub Membership Metadata
public protocol PubNubMembershipMetadata {
  /// The unique identifier of the associated UUID
  var uuidMetadataId: String { get }
  /// The unique identifier of the associated Channel
  var channelMetadataId: String { get }
  /// The associated UUID metadata
  var uuid: PubNubUUIDMetadata? { get set }
  /// The associated Channel metadata
  var channel: PubNubChannelMetadata? { get set }
  /// The last updated timestamp for the object
  var updated: Date? { get set }
  /// The caching identifier for the object
  var eTag: String? { get set }
  /// All custom fields set on the object
  var custom: [String: JSONCodableScalar]? { get set }

  /// Allows for other PubNubUUIDMetadata objects to transcode between themselves
  init(from other: PubNubMembershipMetadata) throws
}

extension PubNubMembershipMetadata {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  public func transcode<T: PubNubMembershipMetadata>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  public func transcode<T: PubNubMembershipMetadata>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

// MARK: Concrete Base Class

/// The default implementation of the `PubNubMembershipMetadata` protocol
public struct PubNubMembershipMetadataBase: PubNubMembershipMetadata, Hashable {
  public let uuidMetadataId: String
  public let channelMetadataId: String

  var concreteUUID: PubNubUUIDMetadataBase?
  public var uuid: PubNubUUIDMetadata? {
    get { concreteUUID }
    set {
      concreteUUID = try? newValue?.transcode()
    }
  }

  var concreteChannel: PubNubChannelMetadataBase?
  public var channel: PubNubChannelMetadata? {
    get { concreteChannel }
    set {
      concreteChannel = try? newValue?.transcode()
    }
  }

  var concreteCustom: [String: JSONCodableScalarType]?
  public var custom: [String: JSONCodableScalar]? {
    get { return concreteCustom }
    set { concreteCustom = newValue?.mapValues { $0.scalarValue } }
  }

  public var updated: Date?
  public var eTag: String?

  public init(
    uuidMetadataId: String,
    channelMetadataId: String,
    uuid: PubNubUUIDMetadataBase? = nil,
    channel: PubNubChannelMetadataBase? = nil,
    custom concreteCustom: [String: JSONCodableScalar]? = nil,
    updated: Date? = nil,
    eTag: String? = nil
  ) {
    self.uuidMetadataId = uuidMetadataId
    self.channelMetadataId = channelMetadataId
    self.uuid = uuid
    self.channel = channel
    self.concreteCustom = concreteCustom?.mapValues { $0.scalarValue }
    self.updated = updated
    self.eTag = eTag
  }

  public init(from other: PubNubMembershipMetadata) throws {
    self.init(
      uuidMetadataId: other.uuidMetadataId,
      channelMetadataId: other.channelMetadataId,
      uuid: try other.uuid?.transcode(),
      channel: try other.channel?.transcode(),
      custom: other.custom,
      updated: other.updated,
      eTag: other.eTag
    )
  }

  init?(from partial: ObjectMetadataPartial, other identifier: String) {
    if let uuid = partial.uuid {
      self.init(
        uuidMetadataId: uuid.metadataId,
        channelMetadataId: identifier,
        uuid: uuid.metadataObject,
        custom: partial.custom,
        updated: partial.updated,
        eTag: partial.eTag
      )
    } else if let channel = partial.channel {
      self.init(
        uuidMetadataId: identifier,
        channelMetadataId: channel.metadataId,
        channel: channel.metadataObject,
        custom: partial.custom,
        updated: partial.updated,
        eTag: partial.eTag
      )
    } else {
      return nil
    }
  }
}

extension PubNubMembershipMetadataBase: Codable {
  enum CodingKeys: String, CodingKey {
    case uuid
    case channel
    case custom
    case updated
    case eTag
  }

  enum NestedCodingKeys: String, CodingKey {
    case id
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    updated = try container.decodeIfPresent(Date.self, forKey: .updated)
    eTag = try container.decodeIfPresent(String.self, forKey: .eTag)
    concreteCustom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom)
    if let concreteChannel = try? container.decodeIfPresent(PubNubChannelMetadataBase.self, forKey: .channel) {
      self.concreteChannel = concreteChannel
      channelMetadataId = concreteChannel.metadataId
    } else {
      let channelContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .channel)
      channelMetadataId = try channelContainer.decode(String.self, forKey: .id)
      concreteChannel = nil
    }

    if let concreteUUID = try? container.decodeIfPresent(PubNubUUIDMetadataBase.self, forKey: .uuid) {
      self.concreteUUID = concreteUUID
      uuidMetadataId = concreteUUID.metadataId
    } else {
      let uuidContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .uuid)
      uuidMetadataId = try uuidContainer.decode(String.self, forKey: .id)
      concreteUUID = nil
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(updated, forKey: .updated)
    try container.encodeIfPresent(eTag, forKey: .eTag)
    try container.encodeIfPresent(custom?.mapValues { $0.scalarValue }, forKey: .custom)

    if let channelObject = concreteChannel {
      try container.encode(channelObject, forKey: .channel)
    } else {
      var channelContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .channel)
      try channelContainer.encode(channelMetadataId, forKey: .id)
    }

    if let uuidObject = concreteUUID {
      try container.encode(uuidObject, forKey: .uuid)
    } else {
      var uuidContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .uuid)
      try uuidContainer.encode(uuidMetadataId, forKey: .id)
    }
  }
}
