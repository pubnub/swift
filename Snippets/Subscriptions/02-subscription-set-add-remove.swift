import PubNubSDK

let pubnub = PubNub(
  publishKey: "demo",
  subscribeKey: "demo",
  userId: "myUniqueUserId",
  automaticRetry: automaticRetry
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
// An example of how to remove a `sportsSubscription` to a SubscriptionSet
subscriptionSet.remove(subscription: sportsSubscription)
// snippet.end
