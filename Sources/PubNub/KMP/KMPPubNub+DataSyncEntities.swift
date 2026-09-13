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
    className: String,
    classVersion: NSNumber?,
    classLevel: String?,
    cursor: String?,
    limit: NSNumber?,
    filterFast: String?,
    filter: String?,
    sort: [KMPDataSyncSortField],
    onSuccess: @escaping (([KMPDataSyncEntity], KMPDataSyncPage?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.getEntities(
      className: className,
      classVersion: classVersion?.intValue,
      classLevel: dataSyncClassLevel(from: classLevel),
      cursor: cursor,
      limit: limit?.intValue,
      filterFast: filterFast,
      filter: filter,
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
    pubnub.dataSync.getEntity(id: id) {
      switch $0 {
      case .success(let entity):
        onSuccess(KMPDataSyncEntity(entity: entity))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func createDataSyncEntity(
    className: String,
    classVersion: Int,
    classLevel: String?,
    id: String?,
    status: String?,
    payload: Any?,
    onSuccess: @escaping ((KMPDataSyncEntity) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.createEntity(
      className: className,
      classVersion: classVersion,
      classLevel: dataSyncClassLevel(from: classLevel),
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
    classVersion: Int,
    status: String?,
    payload: Any?,
    ifMatchesEtag: String?,
    onSuccess: @escaping ((KMPDataSyncEntity) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.setEntity(
      id: id,
      classVersion: classVersion,
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

    pubnub.dataSync.updateEntity(id: id, operations: patchOperations, ifMatchesEtag: ifMatchesEtag) {
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
    pubnub.dataSync.removeEntity(id: id, ifMatchesEtag: ifMatchesEtag) {
      switch $0 {
      case .success:
        onSuccess()
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }
}
