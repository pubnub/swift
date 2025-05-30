import PubNubSDK

let pubnub = PubNub(
  publishKey: "demo",
  subscribeKey: "demo",
  userId: "myUniqueUserId"
)

let subscription = pubnub.channel("channelName").subscription()

// snippet.on-message
// Defines a custom type that will be used to decode the message payload
struct Person: JSONCodable {
  var lastName: String
  var firstName: String
  var age: Int
}

// Add a listener for Message events.

// Assume that a Person object was sent as the message parameter
// in PubNub's publish(...) method, or that the received payload can be decoded as a Person object
subscription.onMessage = { message in
  print("Message Received: \(message) Publisher: \(message.publisher ?? "defaultUUID")")
  print("Will attempt to decode the message payloadas a Person object")

  if let person = try? message.payload.decode(Person.self) {
    print("Person object decoded successfully: \(person)")
    print("Person details: \(person.lastName), \(person.firstName), \(person.age)")
  } else {
    print("Failed to decode the message payload as a Person object")
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
// Add a listener to receive Message Reaction events
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
