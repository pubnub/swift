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

// snippet.signal
pubnub.signal(
  channel: "my-channel",
  message: "Hello from PubNub Swift SDK",
  customMessageType: "text-message-signalled"
) { result in
  switch result {
  case let .success(timetoken):
    print("Message Successfully Published at: \(timetoken)")
  case let .failure(error):
    print("Failed Response: \(error.localizedDescription)")
  }
}
// snippet.end
