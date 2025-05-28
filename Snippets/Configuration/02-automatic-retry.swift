import PubNubSDK

// snippet.automatic-retry
/// Creates automatic retry behavior for failed requests with a linear backoff policy
/// The delay parameter (4 seconds) specifies the base linear delay between retry attempts.

/// As an example, we'll disable automatic retry for publish, signal, and fire requests.
/// Other possible values to exclude are:
/// - .messageSend
/// - .subscribe
/// - .presence
/// - .files
/// - .messageStorage
/// - .channelGroups
/// - .devicePushNotifications
/// - .appContext
/// - .messageActions
let automaticRetry = AutomaticRetry(
  policy: .linear(delay: 4),
  exclude: [.messageSend]
)

// Creates a PubNub instance with retry mechanism enabled:
let pubNub = PubNub(
  publishKey: "yourPublishKey",
  subscribeKey: "yourSubscribeKey",
  userId: "myUniqueUserId",
  automaticRetry: automaticRetry
)
// snippet.end
