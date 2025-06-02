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
// Create a subscription from a channel entity
let weatherSubscription = pubnub.channel("weather-updates").subscription()
// Create another subscription from a channel group entity
let newsGroupSubscription = pubnub.channelGroup("news-feed").subscription()

// Create a SubscriptionSet object from individual entities
let subscriptionSet = pubnub.subscription(entities: [weatherSubscription, newsGroupSubscription])
// Create a subscription from another channel entity
let sportsSubscription = pubnub.channel("sports-scores").subscription()

// An example of how to add a `sportsSubscription` to a SubscriptionSet
subscriptionSet.add(subscription: sportsSubscription)
// An example of how to remove a `sportsSubscription` from a SubscriptionSet
subscriptionSet.remove(subscription: sportsSubscription)

// Triggers the `.subscribe()` method on the SubscriptionSet.
// This will trigger the batch subscription including all underlying subscriptions.
subscriptionSet.subscribe()
// snippet.end
