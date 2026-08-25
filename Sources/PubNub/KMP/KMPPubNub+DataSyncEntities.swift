//
//  KMPPubNub+DataSyncEntities.swift
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

// MARK: - DataSync Entities

@objc
public extension KMPPubNub {
  func getDataSyncEntities(
    entityClass: String,
    entityClassVersion: NSNumber?,
    entityClassLevel: String?,
    cursor: String?,
    limit: NSNumber?,
    filter: String?,
    filterAdvanced: String?,
    sort: [KMPDataSyncSortField],
    onSuccess: @escaping (([KMPDataSyncEntity], KMPDataSyncPage?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.getEntities(
      entityClass: entityClass,
      entityClassVersion: entityClassVersion?.intValue,
      entityClassLevel: dataSyncClassLevel(from: entityClassLevel),
      cursor: cursor,
      limit: limit?.intValue,
      filter: filter,
      filterAdvanced: filterAdvanced,
      sort: dataSyncSortFields(from: sort)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.entities.map { KMPDataSyncEntity(entity: $0) },
          res.next.map { KMPDataSyncPage(page: $0) }
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func getDataSyncEntity(
    id: String,
    onSuccess: @escaping ((KMPDataSyncEntity) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.getEntity(id) {
      switch $0 {
      case .success(let entity):
        onSuccess(KMPDataSyncEntity(entity: entity))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func createDataSyncEntity(
    entityClass: String,
    entityClassVersion: Int,
    entityClassLevel: String?,
    id: String?,
    status: String?,
    payload: Any?,
    onSuccess: @escaping ((KMPDataSyncEntity) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.createEntity(
      entityClass: entityClass,
      entityClassVersion: entityClassVersion,
      entityClassLevel: dataSyncClassLevel(from: entityClassLevel),
      id: id,
      status: status,
      payload: asOptionalCodable(payload)
    ) {
      switch $0 {
      case .success(let entity):
        onSuccess(KMPDataSyncEntity(entity: entity))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func setDataSyncEntity(
    id: String,
    entityClassVersion: Int,
    status: String?,
    payload: Any?,
    ifMatchesEtag: String?,
    onSuccess: @escaping ((KMPDataSyncEntity) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.setEntity(
      id,
      entityClassVersion: entityClassVersion,
      status: status,
      payload: asOptionalCodable(payload),
      ifMatchesEtag: ifMatchesEtag
    ) {
      switch $0 {
      case .success(let entity):
        onSuccess(KMPDataSyncEntity(entity: entity))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func updateDataSyncEntity(
    id: String,
    operations: [KMPDataSyncPatchOperation],
    ifMatchesEtag: String?,
    onSuccess: @escaping ((KMPDataSyncEntity) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    let patchOperations: [PubNubDataSyncPatchOperation]

    do {
      patchOperations = try dataSyncPatchOperations(from: operations)
    } catch {
      onFailure(KMPError(underlying: error))
      return
    }

    pubnub.dataSync.updateEntity(id, operations: patchOperations, ifMatchesEtag: ifMatchesEtag) {
      switch $0 {
      case .success(let entity):
        onSuccess(KMPDataSyncEntity(entity: entity))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func removeDataSyncEntity(
    id: String,
    ifMatchesEtag: String?,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.removeEntity(id, ifMatchesEtag: ifMatchesEtag) {
      switch $0 {
      case .success:
        onSuccess()
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }
}
