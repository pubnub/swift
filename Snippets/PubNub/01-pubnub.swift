//
//  01-pubnub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

// snippet.import
import PubNubSDK

// snippet.end

// snippet.pubnub
let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// snippet.end

// snippet.connection-status
pubnub.onConnectionStateChange = { newStatus in
  print("Connection status: \(newStatus)")
}
// snippet.end

// snippet.unsubscribe-all
pubnub.unsubscribeAll()
// snippet.end
