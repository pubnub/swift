//
//  PubNubObjectMetadataPatcher.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// The type of change that will be applied
public enum PubNubMetadataChange<MetadataType> {
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
          updated.timeIntervalSince(object.updated ?? Date.distantPast) > 0
    else {
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
          updated.timeIntervalSince(object.updated ?? Date.distantPast) > 0
    else {
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
      case let .stringOptional(path, value):
        patchedObject[keyPath: path] = value
      case let .customOptional(path, value):
        patchedObject[keyPath: path] = value
      }
    }

    return patchedObject
  }
}
