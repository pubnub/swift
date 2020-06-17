//
//  PubNubObjectMetadataPatcher.swift
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

/// The type of change that will be applied
public enum PubNubMetadataChange<MetadataType> {
  /// A String value along a predfined KeyPath
  case string(WritableKeyPath<MetadataType, String>, String)
  /// An Optional String value along a predfined KeyPath
  case stringOptional(WritableKeyPath<MetadataType, String?>, String?)
  /// A custom `Dictionary` value along a predfined KeyPath
  case customOptional(WritableKeyPath<MetadataType, [String: JSONCodableScalar]?>, [String: JSONCodableScalar]?)
}

/// A UUID Metadata changeset that can be used to update existing objects
public struct PubNubUUIDMetadataChangeset {
  /// The unique identifier of the object that was changed
  public let metadataId: String
  /// The changes that will be made to the object
  public let changes: [PubNubMetadataChange<PubNubUUIDMetadata>]
  /// The timestamp of the change
  public let updated: Date
  /// The cache identifier of the change
  public let eTag: String

  /// Default init for the object
  public init(
    metadataId: String,
    changes: [PubNubMetadataChange<PubNubUUIDMetadata>],
    updated: Date,
    eTag: String
  ) {
    self.metadataId = metadataId
    self.changes = changes
    self.updated = updated
    self.eTag = eTag
  }

  /// Will attempt to apply the changeset to the passed object
  ///
  /// The changes will be applied only if the ids of the object matches
  /// - Parameter to: The Object that will be patched
  /// - Returns: A copy of the object with the patched chagnes, or the passed object if changes could not be applied
  public func apply(to object: PubNubUUIDMetadata) -> PubNubUUIDMetadata {
    guard metadataId == object.metadataId,
      eTag != object.eTag,
      updated.timeIntervalSince(object.updated ?? Date.distantPast) > 0 else {
      return object
    }

    // Create mutable copy
    var patchedObject = object
    // Update common fields
    patchedObject.updated = updated
    patchedObject.eTag = eTag
    // Apply changes
    for change in changes {
      switch change {
      case let .string(path, value):
        patchedObject[keyPath: path] = value
      case let .stringOptional(path, value):
        patchedObject[keyPath: path] = value
      case let .customOptional(path, value):
        patchedObject[keyPath: path] = value
      }
    }

    return patchedObject
  }
}

/// A Channel Metadata changeset that can be used to update existing objects
public struct PubNubChannelMetadataChangeset {
  /// The unique identifier of the object that was changed
  public let metadataId: String
  /// The changes that will be made to the object
  public let changes: [PubNubMetadataChange<PubNubChannelMetadata>]
  /// The timestamp of the change
  public let updated: Date
  /// The cache identifier of the change
  public let eTag: String

  /// Default init for the object
  public init(
    metadataId: String,
    changes: [PubNubMetadataChange<PubNubChannelMetadata>],
    updated: Date,
    eTag: String
  ) {
    self.metadataId = metadataId
    self.changes = changes
    self.updated = updated
    self.eTag = eTag
  }

  /// Will attempt to apply the changeset to the passed object
  ///
  /// The changes will be applied only if the ids of the object matches
  /// - Parameter to: The Object that will be patched
  /// - Returns: A copy of the object with the patched chagnes, or the passed object if changes could not be applied
  public func apply(to object: PubNubChannelMetadata) -> PubNubChannelMetadata {
    guard metadataId == object.metadataId,
      eTag != object.eTag,
      updated.timeIntervalSince(object.updated ?? Date.distantPast) > 0 else {
      return object
    }

    // Create mutable copy
    var patchedObject = object
    // Update common fields
    patchedObject.updated = updated
    patchedObject.eTag = eTag
    // Apply changes
    for change in changes {
      switch change {
      case let .string(path, value):
        patchedObject[keyPath: path] = value
      case let .stringOptional(path, value):
        patchedObject[keyPath: path] = value
      case let .customOptional(path, value):
        patchedObject[keyPath: path] = value
      }
    }

    return patchedObject
  }
}
