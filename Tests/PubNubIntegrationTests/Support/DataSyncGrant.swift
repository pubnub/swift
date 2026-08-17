//
//  DataSyncGrant.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import PubNubSDK

// MARK: - Grant

struct DataSyncGrant {
  let patterns: [String: [String: PAMPermission]]
  let meta: [String: Any]
  let ttl: Int

  init(
    patterns: [String: [String: PAMPermission]],
    meta: [String: Any] = [:],
    ttl: Int = 60
  ) {
    self.patterns = patterns
    self.meta = meta
    self.ttl = ttl
  }
}

// MARK: - Suite grants

extension DataSyncGrant {
  private static let testPattern = "^\(Constants.prefix).*$"
  private static let projectionChannelPattern = "^__admin__\(Constants.prefix).*$"
  private static let crud: PAMPermission = [.get, .create, .update, .delete]

  /// Authorizes the DataSync User, Channel, and Membership integration test suites.
  static let userChannelMembership = DataSyncGrant(
    patterns: [
      "channels": [testPattern: crud],
      "datasync:users": [testPattern: crud],
      "datasync:memberships": [testPattern: crud]
    ]
  )

  /// Authorizes the DataSync healthcare Entity and Relationship integration test suites.
  static let healthcareAdmin = DataSyncGrant(
    patterns: [
      "datasync:entities": [testPattern: .all],
      "datasync:relationships": [testPattern: .all]
    ],
    meta: [
      "pn-projections": [
        "pat": [
          "datasync:entities:\(Constants.prefix).*": "admin",
          "datasync:relationships:\(Constants.prefix).*": "admin"
        ]
      ]
    ]
  )

  /// Authorizes the DataSync healthcare suites under the `__default__` projection.
  static let healthcareDefault = DataSyncGrant(
    patterns: [
      "datasync:entities": [testPattern: .all],
      "datasync:relationships": [testPattern: .all]
    ]
  )

  /// Authorizes subscribing to the DataSync healthcare Entity and Relationship objects.
  static let healthcareSubscribe = DataSyncGrant(
    patterns: [
      "channels": [projectionChannelPattern: .read]
    ]
  )
}

// MARK: - Request body

extension DataSyncGrant {
  func requestBody() throws -> String {
    let permissions: [String: Any] = [
      "resources": [String: Any](),
      "patterns": patterns.mapValues { $0.mapValues { Int($0.rawValue) } },
      "meta": meta
    ]
    let payload: [String: Any] = [
      "ttl": ttl,
      "permissions": permissions
    ]

    let data: Data

    do {
      data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
    } catch {
      throw DataSyncTokenGrantError.invalidRequestBody(error)
    }

    guard let body = String(data: data, encoding: .utf8) else {
      throw DataSyncTokenGrantError.invalidRequestBody(
        DataSyncTokenGrantError.bodyNotUTF8
      )
    }

    return body
  }
}
