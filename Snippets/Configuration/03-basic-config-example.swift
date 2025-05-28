import PubNubSDK

func basicConfigExample() {
  // snippet.config-basic
  // Creates a PubNub instance with publish and subscribe keys, user ID, and heartbeat interval:
  let pubnub = PubNub(
    configuration: PubNubConfiguration(
      publishKey: "yourPublishKey",
      subscribeKey: "yourSubscribeKey",
      userId: "myUniqueUserId",
      heartbeatInterval: 100
    )
  )
  // snippet.end
}

func userIdConfigExample() {
  // snippet.config-user-id
  let config = PubNubConfiguration(
    publishKey: "yourPublishKey",
    subscribeKey: "yourSubscribeKey",
    userId: "myUniqueUserId"
  )
  let pubnub = PubNub(
    configuration: config
  )
  // snippet.end
}

func configChangeExample() {
  // snippet.config-read-only
  // snippet.hide
  let configuration = PubNubConfiguration(
    publishKey: "yourPublishKey",
    subscribeKey: "yourSubscribeKey",
    userId: "myUniqueUserId"
  )
  let pubnub = PubNub(
    configuration: configuration
  )
  // snippet.show
  // Accessing the current configuration
  var config = pubnub.configuration
  // Modyfing user ID parameter
  config.userId = "my_new_userId"
  // Creating a new PubNub instance with the modified configuration
  let newPubNub = PubNub(configuration: config)
  // snippet.end
}

func filterExpressionExample() {
  // snippet.filter-expression
  // snippet.hide
  let configuration = PubNubConfiguration(
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
  let pubnub = PubNub(
    configuration: configuration
  )
  // snippet.show
  pubnub.subscribeFilterExpression = "(senderID=='my_new_userId')"
  // snippet.end
}
