//
//  DataSyncTestCredentials.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

struct DataSyncTestCredentials {
  let publishKey: String
  let subscribeKey: String
  let secretKey: String
  let origin: String

  init(bundle: Bundle) {
    let infoDictionary = Self.infoDictionary(from: bundle)

    secretKey = Self.requiredValue(for: "PubNubSecretKey", in: infoDictionary)
    publishKey = Self.requiredValue(for: "PubNubPublishKey", in: infoDictionary)
    subscribeKey = Self.requiredValue(for: "PubNubSubscribeKey", in: infoDictionary)
    origin = Self.value(for: "PubNubOrigin", in: infoDictionary) ?? "ps.pndsn.com"
  }
}

private extension DataSyncTestCredentials {
  static func infoDictionary(from bundle: Bundle) -> [String: Any] {
    guard let url = bundle.url(forResource: "PubNubDataSyncTests_Info", withExtension: "plist") else {
      preconditionFailure("Add PubNubDataSyncTests_Info.plist to the integration test bundle resources")
    }
    guard let dictionary = NSDictionary(contentsOf: url) as? [String: Any] else {
      preconditionFailure("Invalid PubNubDataSyncTests_Info.plist content")
    }

    return dictionary
  }

  static func requiredValue(for key: String, in infoDictionary: [String: Any]) -> String {
    guard let value = value(for: key, in: infoDictionary) else {
      preconditionFailure("Set \(key) in PubNubDataSyncTests_Info.plist to run the DataSync integration suites")
    }

    return value
  }

  static func value(for key: String, in infoDictionary: [String: Any]) -> String? {
    guard let value = infoDictionary[key] as? String, !value.isEmpty else {
      return nil
    }

    return value
  }
}
