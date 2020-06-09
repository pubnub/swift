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

public enum PubNubMetadataChange<MetadataType> {
  case string(WritableKeyPath<MetadataType, String>, String)
  case stringOptional(WritableKeyPath<MetadataType, String?>, String?)
  case customOptional(WritableKeyPath<MetadataType, [String: JSONCodableScalar]?>, [String: JSONCodableScalar]?)
}

public struct PubNubUUIDMetadataChangeset {
  public let metadataId: String
  public let changes: [PubNubMetadataChange<PubNubUUIDMetadata>]
  public let updated: Date
  public let eTag: String

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

  public func apply(to object: PubNubUUIDMetadata) -> PubNubUUIDMetadata {
    // other.updated.timeIntervalSince(updated) < 0
    if metadataId != object.metadataId || object.eTag == eTag || object.updated == updated {
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

public struct PubNubChannelMetadataChangeset {
  public let metadataId: String
  public let changes: [PubNubMetadataChange<PubNubChannelMetadata>]
  public let updated: Date
  public let eTag: String

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

  public func apply(to object: PubNubChannelMetadata) -> PubNubChannelMetadata {
    // other.updated.timeIntervalSince(updated) < 0
    if metadataId != object.metadataId || object.eTag == eTag || object.updated == updated {
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
