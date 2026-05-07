//
//  TestPubNubFactory.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK

enum TestPubNubFactory {
  static func makeConfig(
    publishKey: String? = "FakeTestString",
    subscribeKey: String = "FakeTestString",
    userId: String = "testUserId",
    authKey: String? = nil,
    authToken: String? = nil,
    cryptoModule: CryptoModule? = nil,
    enableEventEngine: Bool = true,
    heartbeatInterval: UInt = 0
  ) -> PubNubConfiguration {
    var config = PubNubConfiguration(
      publishKey: publishKey,
      subscribeKey: subscribeKey,
      userId: userId,
      authKey: authKey,
      authToken: authToken,
      heartbeatInterval: heartbeatInterval,
      enableEventEngine: enableEventEngine
    )
    config.cryptoModule = cryptoModule
    return config
  }

  static func make(
    publishKey: String? = "FakeTestString",
    subscribeKey: String = "FakeTestString",
    userId: String = "testUserId",
    authKey: String? = nil,
    authToken: String? = nil,
    cryptoModule: CryptoModule? = nil,
    enableEventEngine: Bool = true,
    heartbeatInterval: UInt = 0,
    session: SessionReplaceable? = nil
  ) -> PubNub {
    let config = makeConfig(
      publishKey: publishKey,
      subscribeKey: subscribeKey,
      userId: userId,
      authKey: authKey,
      authToken: authToken,
      cryptoModule: cryptoModule,
      enableEventEngine: enableEventEngine,
      heartbeatInterval: heartbeatInterval
    )
    return PubNub(configuration: config, session: session)
  }
}
