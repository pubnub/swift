//
//  KMPPubNub+DataSyncUsers.swift
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

// MARK: - DataSync Users

@objc
public extension KMPPubNub {
  func getDataSyncUsers(
    className: String?,
    classVersion: NSNumber?,
    classLevel: String?,
    cursor: String?,
    limit: NSNumber?,
    filterFast: String?,
    filter: String?,
    sort: [KMPDataSyncSortField],
    onSuccess: @escaping (([KMPDataSyncUser], KMPDataSyncPage?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.getUsers(
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
          res.users.map { KMPDataSyncUser(user: $0) },
          res.next.map { KMPDataSyncPage(page: $0) }
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func getDataSyncUser(
    id: String,
    onSuccess: @escaping ((KMPDataSyncUser) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.getUser(id: id) {
      switch $0 {
      case .success(let user):
        onSuccess(KMPDataSyncUser(user: user))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func createDataSyncUser(
    className: String?,
    classVersion: Int,
    classLevel: String?,
    id: String?,
    status: String?,
    payload: Any?,
    onSuccess: @escaping ((KMPDataSyncUser) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.createUser(
      className: className,
      classVersion: classVersion,
      classLevel: dataSyncClassLevel(from: classLevel),
      id: id,
      status: status,
      payload: asOptionalCodable(payload)
    ) {
      switch $0 {
      case .success(let user):
        onSuccess(KMPDataSyncUser(user: user))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func setDataSyncUser(
    id: String,
    classVersion: Int,
    status: String?,
    payload: Any?,
    ifMatchesEtag: String?,
    onSuccess: @escaping ((KMPDataSyncUser) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.setUser(
      id: id,
      classVersion: classVersion,
      status: status,
      payload: asOptionalCodable(payload),
      ifMatchesEtag: ifMatchesEtag
    ) {
      switch $0 {
      case .success(let user):
        onSuccess(KMPDataSyncUser(user: user))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func updateDataSyncUser(
    id: String,
    operations: [KMPDataSyncPatchOperation],
    ifMatchesEtag: String?,
    onSuccess: @escaping ((KMPDataSyncUser) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    let patchOperations: [PubNubDataSyncPatchOperation]

    do {
      patchOperations = try dataSyncPatchOperations(from: operations)
    } catch {
      onFailure(KMPError(underlying: error))
      return
    }

    pubnub.dataSync.updateUser(id: id, operations: patchOperations, ifMatchesEtag: ifMatchesEtag) {
      switch $0 {
      case .success(let user):
        onSuccess(KMPDataSyncUser(user: user))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func removeDataSyncUser(
    id: String,
    ifMatchesEtag: String?,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.removeUser(id: id, ifMatchesEtag: ifMatchesEtag) {
      switch $0 {
      case .success:
        onSuccess()
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }
}
