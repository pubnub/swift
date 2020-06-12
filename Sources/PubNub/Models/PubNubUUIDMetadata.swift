//
//  PubNubUUIDMetadata.swift
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

/// A object capable of representing PubNub UUID Metadata
public protocol PubNubUUIDMetadata {
  /// The unique identifier of the UUID
  var metadataId: String { get }
  /// The name of the UUID
  var name: String { get set }
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
  init(from other: PubNubUUIDMetadata) throws
}

extension PubNubUUIDMetadata {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  public func transcode<T: PubNubUUIDMetadata>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  public func transcode<T: PubNubUUIDMetadata>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

// MARK: Concrete Base Class

/// The default implementation of the `PubNubUUIDMetadata` protocol
public struct PubNubUUIDMetadataBase: PubNubUUIDMetadata, Hashable {
  public let metadataId: String
  public var name: String
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
    name: String,
    externalId: String? = nil,
    profileURL: String? = nil,
    email: String? = nil,
    custom concreteCustom: [String: JSONCodableScalar]? = nil,
    updated: Date? = nil,
    eTag: String? = nil
  ) {
    self.metadataId = metadataId
    self.name = name
    self.externalId = externalId
    self.profileURL = profileURL
    self.email = email
    self.concreteCustom = concreteCustom?.mapValues { $0.scalarValue }
    self.updated = updated
    self.eTag = eTag
  }

  public init(from other: PubNubUUIDMetadata) throws {
    self.init(
      metadataId: other.metadataId,
      name: other.name,
      externalId: other.externalId,
      profileURL: other.profileURL,
      email: other.email,
      custom: other.custom,
      updated: other.updated,
      eTag: other.eTag
    )
  }
}

extension PubNubUUIDMetadataBase: Codable {
  enum CodingKeys: String, CodingKey {
    case metadataId = "id"
    case name
    case externalId
    case profileURL = "profileUrl"
    case email
    case concreteCustom = "custom"
    case updated
    case eTag
  }
}
