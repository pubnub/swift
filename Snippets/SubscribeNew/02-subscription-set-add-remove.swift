//
//  01-subscription-set-add-remove.swift
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

// snippet.subscription-set-add-remove
let weatherChannelEntity = pubnub.channel("weather-updates")
let newsGroupEntity = pubnub.channelGroup("news-feed")

// Create a SubscriptionSet object from individual entities
let subscriptionSet = pubnub.subscription(entities: [weatherChannelEntity, newsGroupEntity])
// Create a subscription for another channel entity
let sportsSubscription = pubnub.channel("sports-scores").subscription()

// An example of how to add a `sportsSubscription` to a SubscriptionSet
subscriptionSet.add(subscription: sportsSubscription)
// An example of how to remove a `sportsSubscription` from a SubscriptionSet
subscriptionSet.remove(subscription: sportsSubscription)

// Triggers `.subscribe()` on the SubscriptionSet, initiating subscriptions to all contained entities
subscriptionSet.subscribe()
// snippet.end
