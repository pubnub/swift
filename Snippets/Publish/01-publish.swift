import PubNubSDK

// snippet.publish
// Initializes a PubNub object with the configuration.
// Keep a strong reference to your top-level `pubnub` object.
let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// Publish a message to a channel
pubnub.publish(
  channel: "my-channel",
  message: "Hello from PubNub Swift SDK",
  customMessageType: "text-message"
) { result in
  switch result {
  case let .success(timetoken):
    print("Message Successfully Published at: \(timetoken)")
  case let .failure(error):
    print("Failed Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.publish-dictionary
/// Publish payload JSON equivalent to:
///
/// ```
/// {
///   "greeting": "hello",
///   "location": "right here"
///  }
/// ```
pubnub.publish(
  channel: "my_channel",
  message: ["greeting": "hello", "location": "right here"]
) { result in
  switch result {
  case let .success(timetoken):
    print("Message Successfully Published at: \(timetoken)")
  case let .failure(error):
    print("Failed Publish Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.publish-custom-type
/// Ensure that your custom object implements `JSONCodable`
struct Message: JSONCodable {
  var greeting: String
  var location: String
}

/// Publish payload JSON equivalent to:
///
/// ```
/// {
///   "greeting": "hello",
///   "location": "right here"
///  }
/// ```
pubnub.publish(
  channel: "my_channel",
  message: Message(greeting: "hello", location: "right here")
) { result in
  switch result {
  case let .success(timetoken):
    print("Message Successfully Published at: \(timetoken)")
  case let .failure(error):
    print("Failed Publish Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.publish-apns-message
let pushMessage = PubNubPushMessage(
  apns: PubNubAPNSPayload(
    aps: APSPayload(alert: .object(.init(title: "Apple Message")), badge: 1, sound: .string("default")),
    pubnub: [.init(targets: [.init(topic: "com.pubnub.swift", environment: .production)], collapseID: "SwiftSDK")],
    payload: "Push Message from PubNub Swift SDK"
  ),
  fcm: PubNubFCMPayload(
    payload: "Push Message from PubNub Swift SDK",
    target: .topic("com.pubnub.swift"),
    notification: FCMNotificationPayload(title: "Android Message"),
    android: FCMAndroidPayload(collapseKey: "SwiftSDK", notification: FCMAndroidNotification(sound: "default"))
  ),
  additional: "Push Message from PubNub Swift SDK"
)

pubnub.publish(
  channel: "my-channel",
  message: pushMessage
) { result in
  switch result {
  case let .success(timetoken):
    print("Message Successfully Published at: \(timetoken)")
  case let .failure(error):
    print("Failed Response: \(error.localizedDescription)")
  }
}
// snippet.end
