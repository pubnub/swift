//
//  01-crypto-module.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK

func aesCbcCryptoModuleExample() {
  // snippet.crypto-module
  // Uses 256-bit AES-CBC encryption (recommended) with backward compatibility for legacy encryption
  let pubnub = PubNub(
    configuration: PubNubConfiguration(
      publishKey: "demo",
      subscribeKey: "demo",
      userId: "myUniqueUserId",
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "pubnubenigma")
    )
  )
  // snippet.end
}

func legacyCryptoModuleExample() {
  // snippet.legacy-crypto-module
  // Uses a legacy encryption mechanism (128-bit cipher key entropy) that is no longer recommended.
  let pubnub = PubNub(
    configuration: PubNubConfiguration(
      publishKey: "demo",
      subscribeKey: "demo",
      userId: "myUniqueUserId",
      cryptoModule: CryptoModule.legacyCryptoModule(with: "pubnubenigma")
    )
  )
  // snippet.end
}
