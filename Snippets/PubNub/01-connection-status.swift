import PubNubSDK

// Initializes a PubNub object with the configuration.
let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// snippet.connection-status
pubnub.onConnectionStateChange = { newStatus in
  print("Connection status: \(newStatus)")
}
// snippet.end
