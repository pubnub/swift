//
//  01-access-manager.swift
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

// snippet.set-token
// Update the authentication token granted by the server
pubnub.set(token: "#yourAuthToken")
// snippet.end

// snippet.parse-token
// Parse an existing token
pubnub.parse(token: "#yourAuthToken")
// snippet.end
