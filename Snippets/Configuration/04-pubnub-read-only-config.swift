import PubNubSDK

let configuration = PubNubConfiguration(
  publishKey: "yourPublishKey",
  subscribeKey: "yourSubscribeKey",
  userId: "myUniqueUserId"
)
let pubnub = PubNub(
  configuration: configuration
)

// snippet.config-read-only
// Accessing the current configuration
var config = pubnub.configuration
// Modyfing user ID parameter
config.userId = "my_new_userId"
// Creating a new PubNub instance with the modified configuration
let newPubNub = PubNub(configuration: config)
