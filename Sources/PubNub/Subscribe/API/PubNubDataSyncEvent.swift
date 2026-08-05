//
//  PubNubDataSyncEvent.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// Possible subevents for DataSync
public enum PubNubDataSyncEvent {
  /// An entity was created
  case entityCreated(PubNubDataSyncEntity)
  /// An entity was updated
  case entityUpdated(PubNubDataSyncEntity)
  /// An entity was deleted
  case entityDeleted(PubNubDataSyncRemovedObject)
  /// A relationship was created
  case relationshipCreated(PubNubDataSyncRelationship)
  /// A relationship was updated
  case relationshipUpdated(PubNubDataSyncRelationship)
  /// A relationship was deleted
  case relationshipDeleted(PubNubDataSyncRemovedObject)
}

/// A DataSync entity or relationship that was deleted.
public struct PubNubDataSyncRemovedObject: Hashable {
  /// The unique identifier of the deleted entity or relationship
  public let id: String
  /// The name of the deleted object's class
  public let className: String
  /// The level the deleted object's class is registered at
  public let classLevel: PubNubDataSyncClassLevel
  /// The version of the deleted object's class
  public let classVersion: Int
  /// The date the object was deleted
  public let deletedAt: Date
}
