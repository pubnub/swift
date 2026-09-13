//
//  KMPPubNub+DataSync.swift
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

// MARK: - DataSync (Shared Converters)

extension KMPPubNub {
  func dataSyncSortFields(from fields: [KMPDataSyncSortField]) -> [PubNub.DataSyncSortField] {
    fields.map { PubNub.DataSyncSortField(property: $0.property, ascending: $0.ascending) }
  }

  func dataSyncClassLevel(from value: String?) -> PubNubDataSyncClassLevel? {
    if let value {
      PubNubDataSyncClassLevel(stringValue: value)
    } else {
      nil
    }
  }

  func dataSyncPatchOperations(
    from operations: [KMPDataSyncPatchOperation]
  ) throws -> [PubNubDataSyncPatchOperation] {
    try operations.map { operation in
      switch operation {
      case let operation as KMPDataSyncAddOperation:
        return .add(path: operation.path, value: dataSyncPatchValue(from: operation.value))
      case let operation as KMPDataSyncRemoveOperation:
        return .remove(path: operation.path)
      case let operation as KMPDataSyncReplaceOperation:
        return .replace(path: operation.path, value: dataSyncPatchValue(from: operation.value))
      case let operation as KMPDataSyncMoveOperation:
        return .move(from: operation.from, path: operation.path)
      case let operation as KMPDataSyncCopyOperation:
        return .copy(from: operation.from, path: operation.path)
      case let operation as KMPDataSyncTestOperation:
        return .test(path: operation.path, value: dataSyncPatchValue(from: operation.value))
      default:
        throw PubNubError(
          .invalidArguments,
          additional: ["Unrecognized \(type(of: operation)) patch operation"]
        )
      }
    }
  }

  private func dataSyncPatchValue(from value: Any?) -> JSONCodable {
    asOptionalCodable(value) ?? AnyJSON(AnyJSONType.null)
  }
}
