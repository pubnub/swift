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
// Initializes a PubNub object with the configuration
let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// snippet.end

// snippet.connection-status
// Sets a callback to handle connection state changes
pubnub.onConnectionStateChange = { newStatus in
  print("Connection status: \(newStatus)")
}
// snippet.end

// snippet.unsubscribe-all
// Unsubscribes from all channels and channel groups
pubnub.unsubscribeAll()
// snippet.end
