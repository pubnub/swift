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
import XCTest

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
  let keys = PubNubConfiguration(bundle: bundle)

  return PubNubConfiguration(
    publishKey: keys.publishKey,
    subscribeKey: keys.subscribeKey,
    userId: randomString(),
    authToken: try DataSyncTokenGrant.token(for: grant, bundle: bundle)
  )
}

/// Skips the calling suite when no secret key is available to grant its token with.
func skipUnlessDataSyncTokensCanBeGranted(from bundle: Bundle) throws {
  try XCTSkipIf(
    DataSyncTokenGrant.secretKey(from: bundle) == nil,
    "Set the PUBNUB_SECRET_KEY environment variable to run the DataSync integration suites"
  )
}
