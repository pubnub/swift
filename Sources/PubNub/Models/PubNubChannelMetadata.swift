//
//  PubNubChannelMetadata.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: Outbound Protocol

/// A object capable of representing PubNub Channel Metadata
public protocol PubNubChannelMetadata {
  /// The unique identifier of the Channel
  var metadataId: String { get }
  /// The name of the Channel
  var name: String? { get set }
  /// The classification of ChannelMetadata
  var type: String? { get set }
  /// The current state of the ChannelMetadata
  var status: String? { get set }
  /// Text describing the purpose of the channel
  var channelDescription: String? { get set }
  /// The last updated timestamp for the object
  var updated: Date? { get set }
  /// The caching identifier for the object
  var eTag: String? { get set }
  /// All custom fields set on the object
  var custom: [String: JSONCodableScalar]? { get set }

  /// Allows for other PubNubUUIDMetadata objects to transcode between themselves
  init(from other: PubNubChannelMetadata) throws
}

public extension PubNubChannelMetadata {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubChannelMetadata>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubChannelMetadata>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

// MARK: Concrete Base Class

/// The default implementation of the `PubNubChannelMetadata` protocol
public struct PubNubChannelMetadataBase: PubNubChannelMetadata, Hashable {
  public let metadataId: String
  public var name: String?
  public var type: String?
  public var status: String?
  public var channelDescription: String?

  public var updated: Date?
  public var eTag: String?

  var concreteCustom: [String: JSONCodableScalarType]?
  public var custom: [String: JSONCodableScalar]? {
    get { return concreteCustom }
    set { concreteCustom = newValue?.mapValues { $0.scalarValue } }
  }

  public init(
    metadataId: String = UUID().uuidString,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    channelDescription: String? = nil,
    custom concreteCustom: [String: JSONCodableScalar]? = nil,
    updated: Date? = nil,
    eTag: String? = nil
  ) {
    self.metadataId = metadataId
    self.name = name
    self.type = type
    self.status = status
    self.channelDescription = channelDescription
    self.concreteCustom = concreteCustom?.mapValues { $0.scalarValue }
    self.updated = updated
    self.eTag = eTag
  }

  public init(from other: PubNubChannelMetadata) throws {
    self.init(
      metadataId: other.metadataId,
      name: other.name,
      type: other.type,
      status: other.status,
      channelDescription: other.channelDescription,
      custom: other.custom,
      updated: other.updated,
      eTag: other.eTag
    )
  }
}

extension PubNubChannelMetadataBase: Codable {
  enum CodingKeys: String, CodingKey {
    case metadataId = "id"
    case name
    case type
    case status
    case channelDescription = "description"
    case concreteCustom = "custom"
    case updated
    case eTag
  }
}
