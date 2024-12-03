//
//  PubNubUserMetadata.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: Outbound Protocol

/// Alias for `PubNubUserMetadata`, maintained for backward compatibility with existing code using `PubNubUUIDMetadata`.
/// Please update your code to use `PubNubUserMetadata` directly, as `PubNubUUIDMetadata` is deprecated and will be removed in a future version.
@available(*, deprecated, message: "Use `PubNubUserMetadata` instead.")
public typealias PubNubUUIDMetadata = PubNubUserMetadata

/// A object capable of representing PubNub User Metadata
public protocol PubNubUserMetadata {
  /// The unique identifier of the User
  var metadataId: String { get }
  /// The name of the User
  var name: String? { get set }
  /// The classification of the User
  var type: String? { get set }
  /// The current state of the User
  var status: String? { get set }
  /// The external identifier for the object
  var externalId: String? { get set }
  /// The profile URL for the object
  var profileURL: String? { get set }
  /// The email address of the object
  var email: String? { get set }
  /// The last updated timestamp for the object
  var updated: Date? { get set }
  /// The caching identifier for the object
  var eTag: String? { get set }
  /// All custom fields set on the object
  var custom: [String: JSONCodableScalar]? { get set }

  /// Allows for other PubNubUUIDMetadata objects to transcode between themselves
  init(from other: PubNubUserMetadata) throws
}

public extension PubNubUserMetadata {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubUserMetadata>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  func transcode<T: PubNubUserMetadata>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

// MARK: Concrete Base Class

/// Alias for `PubNubUserMetadataBase`, maintained for backward compatibility with existing code using `PubNubUUIDMetadataBase`.
/// Please update your code to use `PubNubUserMetadataBase` directly, as `PubNubUUIDMetadataBase` is deprecated and will be removed in a future version.
@available(*, deprecated, message: "Use `PubNubUserMetadataBase` instead.")
public typealias PubNubUUIDMetadataBase = PubNubUserMetadataBase

/// The default implementation of the `PubNubUserMetadata` protocol
public struct PubNubUserMetadataBase: PubNubUserMetadata, Hashable {
  public let metadataId: String
  public var name: String?
  public var type: String?
  public var status: String?
  public var externalId: String?
  public var profileURL: String?
  public var email: String?
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
    externalId: String? = nil,
    profileURL: String? = nil,
    email: String? = nil,
    custom concreteCustom: [String: JSONCodableScalar]? = nil,
    updated: Date? = nil,
    eTag: String? = nil
  ) {
    self.metadataId = metadataId
    self.name = name
    self.type = type
    self.status = status
    self.externalId = externalId
    self.profileURL = profileURL
    self.email = email
    self.concreteCustom = concreteCustom?.mapValues { $0.scalarValue }
    self.updated = updated
    self.eTag = eTag
  }

  public init(from other: PubNubUserMetadata) throws {
    self.init(
      metadataId: other.metadataId,
      name: other.name,
      type: other.type,
      status: other.status,
      externalId: other.externalId,
      profileURL: other.profileURL,
      email: other.email,
      custom: other.custom,
      updated: other.updated,
      eTag: other.eTag
    )
  }
}

extension PubNubUserMetadataBase: Codable {
  enum CodingKeys: String, CodingKey {
    case metadataId = "id"
    case name
    case type
    case status
    case externalId
    case profileURL = "profileUrl"
    case email
    case concreteCustom = "custom"
    case updated
    case eTag
  }
}
