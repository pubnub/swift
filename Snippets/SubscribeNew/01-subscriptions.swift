//
//  01-subscriptions.swift
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

func subscriptionBasicExample() {
  // snippet.basic-usage
  // Create a subscription for an example channel entity
  let subscription = pubnub.channel("channel").subscription(options: ReceivePresenceEvents())
  // Triggers the subscription
  subscription.subscribe()
  // snippet.end
}

func subscriptionSetAddRemoveExample() {
  // snippet.subscription-set-add-remove
  // Create a reference to example channel entity
  let weatherChannelEntity = pubnub.channel("weather-updates")
  // Create a reference to example channel group entity
  let newsGroupEntity = pubnub.channelGroup("news-feed")

  // Create a SubscriptionSet object from entities above
  let subscriptionSet = pubnub.subscription(entities: [weatherChannelEntity, newsGroupEntity])

  // Create a subscription for another channel entity to demonstrate
  // adding and removing to/from a SubscriptionSet
  let sportsSubscription = pubnub.channel("sports-scores").subscription()

  // An example of how to add/remove a `sportsSubscription` to/from a SubscriptionSet
  subscriptionSet.add(subscription: sportsSubscription)
  subscriptionSet.remove(subscription: sportsSubscription)

  // Triggers `.subscribe()` on the SubscriptionSet, initiating subscriptions to all contained entities
  subscriptionSet.subscribe()
  // snippet.end
}

func cloneExample() {
  // snippet.clone
  let subscriptionSet = pubnub.subscription(
    entities: [pubnub.channel("channel"), pubnub.channelGroup("channelGroup")],
    options: ReceivePresenceEvents()
  )
  let subscription = pubnub
    .channel("channelName")
    .subscription()

  let clonedSubscriptionSet = subscriptionSet.clone()
  let clonedSubscription = subscription.clone()
  // snippet.end
}

func unsubscribeExample() {
  let subscriptionSet = pubnub.subscription(
    entities: [pubnub.channel("channel"), pubnub.channelGroup("channelGroup")],
    options: ReceivePresenceEvents()
  )
  let subscription = pubnub
    .channel("channelName")
    .subscription()

  // snippet.unsubscribe
  subscription.unsubscribe()
  subscriptionSet.unsubscribe()
  // snippet.end
}

// snippet.subscription
// Create an example subscription for a channel
let subscription = pubnub
  .channel("channelName")
  .subscription()

// snippet.end

// snippet.on-message
// Defines a custom type that can be used to decode the message payload
struct Person: JSONCodable {
  var lastName: String
  var firstName: String
  var age: Int
}

// Add a listener for Message events
subscription.onMessage = { message in
  // Example showing how to decode the message payload as the custom Person type defined above
  if let person = try? message.payload.decode(Person.self) {
    print("Person object decoded successfully")
    print("Person details: \(person.lastName), \(person.firstName), \(person.age)")
  }
  // Example showing how to decode the message payload as a raw [String: Any] dictionary
  else if let dictionary = message.payload.codableValue.dictionaryOptional {
    print("Dictionary decoded successfully: \(dictionary)")
  }
  // Example showing how to decode the message payload as a raw [Any] array
  else if let array = message.payload.codableValue.arrayOptional {
    print("Array decoded successfully: \(array)")
  }
  // Example showing how to decode the message payload as a String scalar value.
  // If you need other scalar types, you can use the properties listed below:
  //
  // - .intOptional - to decode payload as an Int value
  // - .boolOptional - to decode payload as a Bool value
  // - .doubleOptional - to decode payload as a Double value
  else if let scalarValue = message.payload.codableValue.stringOptional {
    print("Scalar value: \(scalarValue)")
  }
  // Fallback when the message payload cannot be decoded
  else {
    print("Failed to decode the message payload")
  }
}
// snippet.end

// snippet.on-presence
// Add a listener to receive Presence events (requires a subscription with presence)
subscription.onPresence = { presenceChange in
  for action in presenceChange.actions {
    switch action {
    case let .join(uuids):
      print("Occupants joined at \(presenceChange.timetoken): \(uuids)")
    case let .leave(uuids):
      print("Occupants left at \(presenceChange.timetoken): \(uuids)")
    case let .timeout(uuids):
      print("Occupants timed-out at \(presenceChange.timetoken): \(uuids)")
    case let .stateChange(uuid, state):
      print("\(uuid) changed state to \(state) at \(presenceChange.timetoken)")
    }
  }
}
// snippet.end

// snippet.on-message-action
// Add a listener to receive Message Action events
subscription.onMessageAction = { messageActionEvent in
  switch messageActionEvent {
  case let .added(messageAction):
    print("Message action added in \(messageAction.channel) channel at message timetoken \(messageAction.messageTimetoken)")
  case let .removed(messageAction):
    print("A message reaction with the timetoken of \(messageAction.actionTimetoken) has been removed")
  }
}
// snippet.end

// snippet.on-app-context
// Add a listener to receive App Context events
subscription.onAppContext = { appContextEvent in
  switch appContextEvent {
  case let .userMetadataSet(changeset):
    print("User metadata changes detected for \(changeset.metadataId) at \(changeset.updated).")
    print("All changes made to the object: \(changeset.changes)")
    print("To apply these changes, fetch the relevant object and call `changeset.apply(to: otherChannelMetadata)`.")
  case let .userMetadataRemoved(metadataId):
    print("Metadata for UUID \(metadataId) removed")
  case let .channelMetadataSet(changeset):
    print("Channel metadata changes detected for \(changeset.metadataId) at \(changeset.updated).")
    print("All changes made to the object: \(changeset.changes)")
    print("To apply these changes, fetch the relevant object and call `changeset.apply(to: otherUserMetadata)`.")
  case let .channelMetadataRemoved(metadataId: metadataId):
    print("Metadata for channel \(metadataId) removed")
  case let .membershipMetadataSet(membership):
    print("Membership set between \(membership.userMetadataId) and \(membership.channelMetadataId)")
  case let .membershipMetadataRemoved(membership):
    print("Membership removed between \(membership.userMetadataId) and \(membership.channelMetadataId)")
  }
}
// snippet.end

// snippet.on-file-event
// Add a listener to receive File events
subscription.onFileEvent = { fileEvent in
  if case let .uploaded(fileInfo) = fileEvent {
    print("File uploaded: \(fileInfo)")
  }
}
// snippet.end

// snippet.on-events
// Add a batched subscription event that possibly contains multiple events
subscription.onEvents = { events in
  print("Received events: \(events)")
}
// snippet.end

// snippet.on-event
// Add a listener to capture single event
subscription.onEvent = { event in
  switch event {
  case let .messageReceived(message):
    print("Message Received: \(message) Publisher: \(message.publisher ?? "defaultUUID")")
  case let .signalReceived(signal):
    print("Signal Received: \(signal)")
  case let .presenceChanged(presence):
    print("Presence event: \(presence)")
  case let .appContextChanged(appContextEvent):
    print("App Context change event: \(appContextEvent)")
  case let .messageActionChanged(messageActionEvent):
    print("Message Reaction event: \(messageActionEvent)")
  case let .fileChanged(fileEvent):
    print("File event: \(fileEvent)")
  }
}
// snippet.end
