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

// snippet.publish-mixed
/// Ensure that your custom types conform to `JSONCodable`
struct Location: JSONCodable {
  var lat: Double
  var long: Double
}

struct Message: JSONCodable {
  var greeting: String
  var location: Location
}

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
  message: Message(greeting: "hello", location: .init(lat: 37.782486, long: -122.395344))
) { result in
  switch result {
  case let .success(timetoken):
    print("Message Successfully Published at: \(timetoken)")
  case let .failure(error):
    print("Failed Publish Response: \(error.localizedDescription)")
  }
}
// snippet.end
