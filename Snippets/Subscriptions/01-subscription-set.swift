import PubNubSDK

// Initializes a PubNub object with the configuration
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
