//
//  KMPDataSyncPatchOperation.swift
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

// MARK: - KMPDataSyncPatchOperation

@objc
public class KMPDataSyncPatchOperation: NSObject {

}

// MARK: - KMPDataSyncAddOperation

@objc
public class KMPDataSyncAddOperation: KMPDataSyncPatchOperation {
  @objc public let path: String
  @objc public let value: Any?

  @objc
  public init(path: String, value: Any?) {
    self.path = path
    self.value = value
  }
}

// MARK: - KMPDataSyncRemoveOperation

@objc
public class KMPDataSyncRemoveOperation: KMPDataSyncPatchOperation {
  @objc public let path: String

  @objc
  public init(path: String) {
    self.path = path
  }
}

// MARK: - KMPDataSyncReplaceOperation

@objc
public class KMPDataSyncReplaceOperation: KMPDataSyncPatchOperation {
  @objc public let path: String
  @objc public let value: Any?

  @objc
  public init(path: String, value: Any?) {
    self.path = path
    self.value = value
  }
}

// MARK: - KMPDataSyncMoveOperation

@objc
public class KMPDataSyncMoveOperation: KMPDataSyncPatchOperation {
  @objc public let from: String
  @objc public let path: String

  @objc
  public init(from: String, path: String) {
    self.from = from
    self.path = path
  }
}

// MARK: - KMPDataSyncCopyOperation

@objc
public class KMPDataSyncCopyOperation: KMPDataSyncPatchOperation {
  @objc public let from: String
  @objc public let path: String

  @objc
  public init(from: String, path: String) {
    self.from = from
    self.path = path
  }
}

// MARK: - KMPDataSyncTestOperation

@objc
public class KMPDataSyncTestOperation: KMPDataSyncPatchOperation {
  @objc public let path: String
  @objc public let value: Any?

  @objc
  public init(path: String, value: Any?) {
    self.path = path
    self.value = value
  }
}
