//
//  01-subscribe-unsubscribe-old.swift
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

// snippet.subscribe
pubnub.subscribe(to: ["my_channel"])
// snippet.end

// snippet.subscribe-multiple-channels
pubnub.subscribe(to: ["my_channel", "my_channel-2", "my_channel-3"])
// snippet.end

// snippet.subscribe-with-presence
pubnub.subscribe(
  to: ["my_channel"],
  withPresence: true
)
// snippet.end

// snippet.subscribe-wildcard
pubnub.subscribe(to: ["a.b.*"])
// snippet.end

// snippet.subscribe-channel-group
pubnub.subscribe(
  to: [],
  and: ["my_group"]
)
// snippet.end

// snippet.subscribe-channel-group-presence
pubnub.subscribe(
  to: [],
  and: ["my_group"],
  withPresence: true
)
// snippet.end

// snippet.subscribe-multiple-channel-groups
pubnub.subscribe(
  to: [],
  and: ["my_group", "my_group-2", "my_group-3"]
)
// snippet.end

// snippet.subscribe-channel-group-and-channel
pubnub.subscribe(
  to: ["my_channel"],
  and: ["my_group"]
)
// snippet.end
