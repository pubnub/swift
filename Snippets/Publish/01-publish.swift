//
//  01-publish.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

// snippet.import
import PubNubSDK

// snippet.end

// snippet.custom-type-message
/// Ensure that your custom type implements `JSONCodable`
struct Message: JSONCodable {
  var greeting: String
  var location: String
}

// snippet.end

// snippet.custom-type-location
/// Ensure that your custom type implements `JSONCodable`
struct Location: JSONCodable {
  var lat: Double
  var long: Double
}

// snippet.end

// snippet.custom-type-custom-message
/// Ensure that your custom type implements `JSONCodable`
struct CustomMessage: JSONCodable {
  var greeting: String
  var location: Location
}

// snippet.end

// snippet.pubnub
// Initializes a PubNub object with the configuration
let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// snippet.end

// snippet.publish
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

// snippet.publish-mixed
/// Publish payload JSON equivalent to:
///
/// ```
/// {
///   "greeting": "hello",
///   "location": {
///     "lat": 37.782486,
///     "long": -122.395344
///   }
/// }
/// ```
pubnub.publish(
  channel: "my_channel",
  message: CustomMessage(greeting: "hello", location: Location(lat: 37.782486, long: -122.395344))
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

// snippet.fire
pubnub.fire(
  channel: "my-channel",
  message: "Hello from PubNub Swift SDK"
) { result in
  switch result {
  case let .success(timetoken):
    print("Message Successfully Published at: \(timetoken)")
  case let .failure(error):
    print("Failed Response: \(error.localizedDescription)")
  }
}
// snippet.end

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
