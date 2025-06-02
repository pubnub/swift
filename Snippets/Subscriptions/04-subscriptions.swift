//
//  04-subscriptions.swift
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

// snippet.clone
let subscriptionSet = pubnub.subscription(
  entities: [pubnub.channel("channel"), pubnub.channelGroup("channelGroup")],
  options: ReceivePresenceEvents()
)
let subscription = pubnub
  .channel("channelName")
  .subscription()

let clonedSubscriptionSet = subscriptionSet.clone()
let clonedSubscription = subscription.clone()
// snippet.end

// snippet.unsubscribe
subscription.unsubscribe()
subscriptionSet.unsubscribe()
// snippet.end
