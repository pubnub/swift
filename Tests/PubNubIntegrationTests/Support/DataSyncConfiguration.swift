//
//  DataSyncConfiguration.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import PubNubSDK

/// The configuration authorizing the DataSync User, Channel, and Membership integration test suites
func dataSyncConfiguration(from bundle: Bundle) throws -> PubNubConfiguration {
  try dataSyncConfiguration(granting: .userChannelMembership, from: bundle)
}

/// The configuration authorizing the DataSync healthcare Entity and Relationship integration test suites
func dataSyncHealthcareConfiguration(from bundle: Bundle) throws -> PubNubConfiguration {
  try dataSyncConfiguration(granting: .healthcareAdmin, from: bundle)
}

/// The configuration reading the DataSync healthcare classes through the `__default__` projection
func dataSyncHealthcareDefaultProjectionConfiguration(from bundle: Bundle) throws -> PubNubConfiguration {
  try dataSyncConfiguration(granting: .healthcareDefault, from: bundle)
}

/// The configuration authorizing a subscribe to the DataSync healthcare projection channels
func dataSyncHealthcareSubsribeConfiguration(from bundle: Bundle) throws -> PubNubConfiguration {
  try dataSyncConfiguration(granting: .healthcareSubscribe, from: bundle)
}

/// A configuration carrying a freshly granted token for `grant`.
private func dataSyncConfiguration(granting grant: DataSyncGrant, from bundle: Bundle) throws -> PubNubConfiguration {
  let credentials = DataSyncTestCredentials(
    bundle: bundle
  )
  let authToken = try DataSyncTokenGrant.token(
    origin: credentials.origin,
    secretKey: credentials.secretKey,
    subscribeKey: credentials.subscribeKey,
    publishKey: credentials.publishKey,
    grant: grant
  )
  return PubNubConfiguration(
    publishKey: credentials.publishKey,
    subscribeKey: credentials.subscribeKey,
    userId: randomString(),
    authToken: authToken,
    origin: credentials.origin
  )
}
