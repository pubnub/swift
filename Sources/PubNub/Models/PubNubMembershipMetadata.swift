//
//  PubNubMembershipMetadata.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: Outbound Protocol

/// A object capable of representing PubNub Membership Metadata
public protocol PubNubMembershipMetadata {
  /// The unique identifier of the associated UUID
  @available(*, deprecated, renamed: "userMetadataId")
  var uuidMetadataId: String { get }
  /// The unique identifier of the associated User
  var userMetadataId: String { get }
  /// The unique identifier of the associated Channel
  var channelMetadataId: String { get }
  /// The current status of the MembershipMetadata
  var status: String? { get set }
  /// The current type of the MembershipMetadata
  var type: String? { get set }
  /// The associated UUID metadata
  @available(*, deprecated, renamed: "user")
  var uuid: PubNubUUIDMetadata? { get set }
  /// The associated User metadata
  var user: PubNubUserMetadata? { get set }
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

public extension PubNubMembershipMetadata {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubMembershipMetadata>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubMembershipMetadata>() throws -> T {
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
  /// The unique identifier of the associated UUID
  @available(*, deprecated, renamed: "userMetadataId")
  public private(set) var uuidMetadataId: String
  /// The unique identifier of the associated Channel
  public let channelMetadataId: String
  /// The current status of the MembershipMetadata
  public var status: String?
  /// The current type of the MembershipMetadata
  public var type: String?
  /// The last updated timestamp for the object
  public var updated: Date?
  /// The caching identifier for the object
  public var eTag: String?

  var concreteUUID: PubNubUUIDMetadataBase?
  var concreteChannel: PubNubChannelMetadataBase?
  var concreteCustom: [String: JSONCodableScalarType]?

  /// The associated User metadata
  public var user: (any PubNubUserMetadata)? {
    get {
      uuid
    } set {
      uuid = newValue
    }
  }

  /// The unique identifier of the associated User
  public var userMetadataId: String {
    get {
      uuidMetadataId
    } set {
      uuidMetadataId = newValue
    }
  }

  @available(*, deprecated, renamed: "user")
  public var uuid: PubNubUUIDMetadata? {
    get { concreteUUID }
    set { concreteUUID = try? newValue?.transcode() }
  }

  public var channel: PubNubChannelMetadata? {
    get { concreteChannel }
    set { concreteChannel = try? newValue?.transcode() }
  }

  public var custom: [String: JSONCodableScalar]? {
    get { return concreteCustom }
    set { concreteCustom = newValue?.mapValues { $0.scalarValue } }
  }

  @available(*, deprecated, renamed: "init(userMetadataId:channelMetadataId:status:type:user:channel:custom:updated:eTag:)")
  public init(
    uuidMetadataId: String,
    channelMetadataId: String,
    status: String? = nil,
    type: String? = nil,
    uuid: PubNubUUIDMetadataBase? = nil,
    channel: PubNubChannelMetadataBase? = nil,
    custom concreteCustom: [String: JSONCodableScalar]? = nil,
    updated: Date? = nil,
    eTag: String? = nil
  ) {
    self.init(
      userMetadataId: uuidMetadataId,
      channelMetadataId: channelMetadataId,
      status: status,
      type: type,
      user: uuid,
      channel: channel,
      custom: concreteCustom,
      updated: updated,
      eTag: eTag
    )
  }

  public init(
    userMetadataId: String,
    channelMetadataId: String,
    status: String? = nil,
    type: String? = nil,
    user: PubNubUUIDMetadataBase? = nil,
    channel: PubNubChannelMetadataBase? = nil,
    custom concreteCustom: [String: JSONCodableScalar]? = nil,
    updated: Date? = nil,
    eTag: String? = nil
  ) {
    self.uuidMetadataId = userMetadataId
    self.channelMetadataId = channelMetadataId
    self.uuid = user
    self.channel = channel
    self.concreteCustom = concreteCustom?.mapValues { $0.scalarValue }
    self.status = status
    self.type = type
    self.updated = updated
    self.eTag = eTag
  }

  public init(from other: PubNubMembershipMetadata) throws {
    self.init(
      userMetadataId: other.userMetadataId,
      channelMetadataId: other.channelMetadataId,
      status: other.status,
      type: other.type,
      user: try other.user?.transcode(),
      channel: try other.channel?.transcode(),
      custom: other.custom,
      updated: other.updated,
      eTag: other.eTag
    )
  }

  public init?(from partial: ObjectMetadataPartial, other identifier: String) {
    if let uuid = partial.uuid {
      self.init(
        userMetadataId: uuid.metadataId,
        channelMetadataId: identifier,
        status: partial.status,
        type: partial.type,
        user: uuid.metadataObject,
        custom: partial.custom,
        updated: partial.updated,
        eTag: partial.eTag
      )
    } else if let channel = partial.channel {
      self.init(
        userMetadataId: identifier,
        channelMetadataId: channel.metadataId,
        status: partial.status,
        type: partial.type,
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
    case status
    case type
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
    status = try container.decodeIfPresent(String.self, forKey: .status)
    type = try container.decodeIfPresent(String.self, forKey: .type)

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
    try container.encodeIfPresent(status, forKey: .status)
    try container.encodeIfPresent(type, forKey: .type)

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
      try uuidContainer.encode(userMetadataId, forKey: .id)
    }
  }
}
