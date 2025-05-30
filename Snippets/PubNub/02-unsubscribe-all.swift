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

// snippet.unsubscribe-all
pubnub.unsubscribeAll()
// snippet.end
