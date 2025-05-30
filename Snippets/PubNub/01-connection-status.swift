//
//  01-connection-status.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK

// Initializes a PubNub object with the configuration.
let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// snippet.connection-status
pubnub.onConnectionStateChange = { newStatus in
  print("Connection status: \(newStatus)")
}
// snippet.end
