import PubNubSDK

// snippet.basic-config-example
// Creates a PubNub instance with publish and subscribe keys, user ID, and heartbeat interval:
let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "yourPublishKey",
    subscribeKey: "yourSubscribeKey",
    userId: "yourUserId",
    heartbeatInterval: 100
  )
)
// snippet.end
