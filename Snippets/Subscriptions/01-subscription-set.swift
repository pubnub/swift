//
//  01-subscription-set.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK

let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// snippet.subscription-set
// Create a subscription set with multiple local entities
let subscriptionSet = pubnub.subscription(
  entities: [
    pubnub.channel("channel"),
    pubnub.channelGroup("channelGroup"),
    pubnub.userMetadata("userMetadataIdentifier")
  ],
  options: ReceivePresenceEvents()
)

// Triggers the subscription
subscriptionSet.subscribe()
// snippet.end
