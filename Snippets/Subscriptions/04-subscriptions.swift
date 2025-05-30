import PubNubSDK

// Initializes a PubNub object with the configuration.
// Keep a strong reference to your top-level `pubnub` object.
let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// snippet.clone
let entitiesToSubscribe = [
  pubnub.channel("channel"),
  pubnub.channelGroup("channelGroup")
]
let subscriptionSet = pubnub.subscription(
  entities: [pubnub.channel("channel"), pubnub.channelGroup("channelGroup")],
  options: ReceivePresenceEvents()
)
let channelSubscription = pubnub
  .channel("channelName")
  .subscription()


let clonedSubscriptionSet = subscriptionSet.clone()
let clonedSubscription = channelSubscription.clone()
// snippet.end


// snippet.unsubscribe
subscription.unsubscribe()
subscriptionSet.unsubscribe()
// snippet.end


