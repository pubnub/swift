//
//  KMPPubNub+DataSyncRelationships.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
//
// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
// While these symbols are public, they are intended strictly for internal usage.
//
// External developers should refrain from directly using these symbols in their code, as their implementation details
// may change in future versions of the framework, potentially leading to breaking changes.

import Foundation

// MARK: - DataSync Relationships

@objc
public extension KMPPubNub {
  func getDataSyncRelationships(
    className: String,
    classVersion: NSNumber?,
    entityAId: String?,
    entityBId: String?,
    cursor: String?,
    limit: NSNumber?,
    filter: String?,
    filterAdvanced: String?,
    sort: [KMPDataSyncSortField],
    onSuccess: @escaping (([KMPDataSyncRelationship], KMPDataSyncPage?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.getRelationships(
      className: className,
      classVersion: classVersion?.intValue,
      entityAId: entityAId,
      entityBId: entityBId,
      cursor: cursor,
      limit: limit?.intValue,
      filter: filter,
      filterAdvanced: filterAdvanced,
      sort: dataSyncSortFields(from: sort)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.relationships.map { KMPDataSyncRelationship(relationship: $0) },
          res.next.map { KMPDataSyncPage(page: $0) }
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func getDataSyncRelationship(
    id: String,
    onSuccess: @escaping ((KMPDataSyncRelationship) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.getRelationship(id: id) {
      switch $0 {
      case .success(let relationship):
        onSuccess(KMPDataSyncRelationship(relationship: relationship))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func createDataSyncRelationship(
    className: String,
    classVersion: Int,
    entityAId: String,
    entityBId: String,
    id: String?,
    status: String?,
    payload: Any?,
    onSuccess: @escaping ((KMPDataSyncRelationship) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.createRelationship(
      className: className,
      classVersion: classVersion,
      entityAId: entityAId,
      entityBId: entityBId,
      id: id,
      status: status,
      payload: asOptionalCodable(payload)
    ) {
      switch $0 {
      case .success(let relationship):
        onSuccess(KMPDataSyncRelationship(relationship: relationship))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func setDataSyncRelationship(
    id: String,
    classVersion: Int,
    status: String?,
    payload: Any?,
    ifMatchesEtag: String?,
    onSuccess: @escaping ((KMPDataSyncRelationship) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.setRelationship(
      id: id,
      classVersion: classVersion,
      status: status,
      payload: asOptionalCodable(payload),
      ifMatchesEtag: ifMatchesEtag
    ) {
      switch $0 {
      case .success(let relationship):
        onSuccess(KMPDataSyncRelationship(relationship: relationship))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func updateDataSyncRelationship(
    id: String,
    operations: [KMPDataSyncPatchOperation],
    ifMatchesEtag: String?,
    onSuccess: @escaping ((KMPDataSyncRelationship) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    let patchOperations: [PubNubDataSyncPatchOperation]

    do {
      patchOperations = try dataSyncPatchOperations(from: operations)
    } catch {
      onFailure(KMPError(underlying: error))
      return
    }

    pubnub.dataSync.updateRelationship(id: id, operations: patchOperations, ifMatchesEtag: ifMatchesEtag) {
      switch $0 {
      case .success(let relationship):
        onSuccess(KMPDataSyncRelationship(relationship: relationship))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func removeDataSyncRelationship(
    id: String,
    ifMatchesEtag: String?,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.removeRelationship(id: id, ifMatchesEtag: ifMatchesEtag) {
      switch $0 {
      case .success:
        onSuccess()
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }
}
