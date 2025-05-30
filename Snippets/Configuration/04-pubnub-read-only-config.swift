//
//  04-pubnub-read-only-config.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK

let configuration = PubNubConfiguration(
  publishKey: "demo",
  subscribeKey: "demo",
  userId: "myUniqueUserId"
)
let pubnub = PubNub(
  configuration: configuration
)

// snippet.config-read-only
// Accessing the current configuration
var config = pubnub.configuration
// Modyfing user ID parameter
config.userId = "my_new_userId"
// Creating a new PubNub instance with the modified configuration
let newPubNub = PubNub(configuration: config)
