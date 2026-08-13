//
//  DataSyncConfiguration.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import Foundation

/// The configuration authorizing the DataSync User, Channel, and Membership integration test suites
func dataSyncConfiguration(from bundle: Bundle) -> PubNubConfiguration {
  PubNubConfiguration(
    publishKey: PubNubConfiguration(bundle: bundle).publishKey,
    subscribeKey: PubNubConfiguration(bundle: bundle).subscribeKey,
    userId: randomString(),
    authToken: dataSyncUserChannelMembershipAuthToken
  )
}

/// The configuration authorizing the DataSync healthcare Entity and Relationship integration test suites
func dataSyncHealthcareConfiguration(from bundle: Bundle) -> PubNubConfiguration {
  PubNubConfiguration(
    publishKey: PubNubConfiguration(bundle: bundle).publishKey,
    subscribeKey: PubNubConfiguration(bundle: bundle).subscribeKey,
    userId: randomString(),
    authToken: dataSyncHealthcareAdminAuthToken
  )
}

/// The configuration reading the DataSync healthcare classes through the `__default__` projection
func dataSyncHealthcareDefaultProjectionConfiguration(from bundle: Bundle) -> PubNubConfiguration {
  PubNubConfiguration(
    publishKey: PubNubConfiguration(bundle: bundle).publishKey,
    subscribeKey: PubNubConfiguration(bundle: bundle).subscribeKey,
    userId: randomString(),
    authToken: dataSyncHealthcareDefaultAuthToken
  )
}

/// The configuration authorizing a subscribe to the DataSync healthcare projection channels
func dataSyncHealthcareSubsribeConfiguration(from bundle: Bundle) -> PubNubConfiguration {
  PubNubConfiguration(
    publishKey: PubNubConfiguration(bundle: bundle).publishKey,
    subscribeKey: PubNubConfiguration(bundle: bundle).subscribeKey,
    userId: randomString(),
    authToken: dataSyncHealthcareSubscribeToken,
  )
}
