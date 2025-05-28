import PubNubSDK

func basicConfigExample() {
  // snippet.config-basic
  // Creates a PubNubConfiguration instance with publish and subscribe keys, user ID,
  // and heartbeat interval:
  let configuration = PubNubConfiguration(
    publishKey: "yourPublishKey",
    subscribeKey: "yourSubscribeKey",
    userId: "myUniqueUserId",
    heartbeatInterval: 100
  )
  
  // Creates a PubNub instance with the configuration specified above:
  let pubnub = PubNub(
    configuration: configuration
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
