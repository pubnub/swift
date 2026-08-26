//
//  KMPPubNub+DataSyncChannels.swift
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

// MARK: - DataSync Channels

@objc
public extension KMPPubNub {
  func getDataSyncChannels(
    classVersion: NSNumber?,
    className: String?,
    classLevel: String?,
    cursor: String?,
    limit: NSNumber?,
    filter: String?,
    filterAdvanced: String?,
    sort: [KMPDataSyncSortField],
    onSuccess: @escaping (([KMPDataSyncChannel], KMPDataSyncPage?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.getChannels(
      classVersion: classVersion?.intValue,
      className: className,
      classLevel: dataSyncClassLevel(from: classLevel),
      cursor: cursor,
      limit: limit?.intValue,
      filter: filter,
      filterAdvanced: filterAdvanced,
      sort: dataSyncSortFields(from: sort)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.channels.map { KMPDataSyncChannel(channel: $0) },
          res.next.map { KMPDataSyncPage(page: $0) }
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func getDataSyncChannel(
    id: String,
    onSuccess: @escaping ((KMPDataSyncChannel) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.getChannel(id: id) {
      switch $0 {
      case .success(let channel):
        onSuccess(KMPDataSyncChannel(channel: channel))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func createDataSyncChannel(
    classVersion: Int,
    className: String?,
    classLevel: String?,
    id: String?,
    status: String?,
    payload: Any?,
    onSuccess: @escaping ((KMPDataSyncChannel) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.createChannel(
      classVersion: classVersion,
      className: className,
      classLevel: dataSyncClassLevel(from: classLevel),
      id: id,
      status: status,
      payload: asOptionalCodable(payload)
    ) {
      switch $0 {
      case .success(let channel):
        onSuccess(KMPDataSyncChannel(channel: channel))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func setDataSyncChannel(
    id: String,
    classVersion: Int,
    status: String?,
    payload: Any?,
    ifMatchesEtag: String?,
    onSuccess: @escaping ((KMPDataSyncChannel) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.setChannel(
      id: id,
      classVersion: classVersion,
      status: status,
      payload: asOptionalCodable(payload),
      ifMatchesEtag: ifMatchesEtag
    ) {
      switch $0 {
      case .success(let channel):
        onSuccess(KMPDataSyncChannel(channel: channel))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func updateDataSyncChannel(
    id: String,
    operations: [KMPDataSyncPatchOperation],
    ifMatchesEtag: String?,
    onSuccess: @escaping ((KMPDataSyncChannel) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    let patchOperations: [PubNubDataSyncPatchOperation]

    do {
      patchOperations = try dataSyncPatchOperations(from: operations)
    } catch {
      onFailure(KMPError(underlying: error))
      return
    }

    pubnub.dataSync.updateChannel(id: id, operations: patchOperations, ifMatchesEtag: ifMatchesEtag) {
      switch $0 {
      case .success(let channel):
        onSuccess(KMPDataSyncChannel(channel: channel))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func removeDataSyncChannel(
    id: String,
    ifMatchesEtag: String?,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.dataSync.removeChannel(id: id, ifMatchesEtag: ifMatchesEtag) {
      switch $0 {
      case .success:
        onSuccess()
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }
}
