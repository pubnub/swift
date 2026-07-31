//
//  01-listeners-old.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

// swiftlint:disable line_length
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

// snippet.subscription-listener
// Create a new listener instance
let listener = SubscriptionListener()

// snippet.end

// snippet.did-receive-subscription
// Add listener event callbacks
listener.didReceiveSubscription = { event in
  switch event {
  case let .messageReceived(message):
    print("Message Received: \(message) Publisher: \(message.publisher ?? "defaultUUID")")
  case let .presenceChanged(presence):
    print("Presence Received: \(presence)")
  default:
    break
  }
}

// snippet.end

// snippet.did-receive-status
// Connection status changes and subscription errors are delivered through `didReceiveStatus`
listener.didReceiveStatus = { statusEvent in
  switch statusEvent {
  case let .success(status):
    print("Status Received: \(status)")
  case let .failure(error):
    print("Subscription Error \(error)")
  }
}

// snippet.end

// snippet.add-listener
// Add a listener to enable the receiving of subscription events.
// Ensure that you call `pubnub.add(listener)` before subscribing to channels or channel groups
pubnub.add(listener)
// snippet.end

// snippet.did-receive-batch-subscription
listener.didReceiveBatchSubscription = { events in
  for event in events {
    switch event {
    case .messageReceived(let message):
      print("The \(message.channel) channel received a message at \(message.published).")
      print("The channel group or wildcard subscription match (if exists): \(String(describing: message.subscription)).")
      print("Message payload: \(message.payload). Sent by: \(message.publisher ?? "unknown").")

    case .signalReceived(let signal):
      print("The \(signal.channel) channel received a signal at \(signal.published).")
      print("The channel group or wildcard subscription match (if exists): \(String(describing: signal.subscription)).")
      print("Signal payload: \(signal.payload). Sent by: \(signal.publisher ?? "unknown").")

    case .presenceChanged(let presenceChange):
      print("Presence updated for channel \(presenceChange.channel)")
      print("Channel occupancy \(presenceChange.occupancy)")

      for action in presenceChange.actions {
        switch action {
        case let .join(uuids):
          print("Occupants joined at \(presenceChange.timetoken): \(uuids).")
        case let .leave(uuids):
          print("Occupants left at \(presenceChange.timetoken): \(uuids).")
        case let .timeout(uuids):
          print("Occupants timed-out at \(presenceChange.timetoken): \(uuids).")
        case let .stateChange(uuid, state):
          print("\(uuid) updated state to \(state) at \(presenceChange.timetoken).")
        }
      }

    case .appContextChanged(let appContextEvent):
      switch appContextEvent {
      case .userMetadataSet(let userMetadataChange):
        print("User metadata changes detected for \(userMetadataChange.metadataId) at \(userMetadataChange.updated).")
        print("All changes made to the object: \(userMetadataChange.changes)")
        print("To apply these changes, fetch the relevant object and call `userMetadataChange.apply(to: otherUserMetadata)`.")
      case .userMetadataRemoved(let metadataId):
        print("Metadata for User \(metadataId) has been removed.")
      case .channelMetadataSet(let channelMetadata):
        print("Channel metadata changes detected for \(channelMetadata.metadataId) at \(channelMetadata.updated).")
        print("All changes made to the object: \(channelMetadata.changes)")
        print("To apply these changes, fetch the relevant object and call `channelMetadata.apply(to: otherChannelMetadata)`.")
      case .channelMetadataRemoved(let metadataId):
        print("Metadata for channel \(metadataId) has been removed.")
      case .membershipMetadataSet(let membership):
        print("Membership established between User \(membership.userMetadataId) and channel \(membership.channelMetadataId).")
      case .membershipMetadataRemoved(let membership):
        print("Membership removed between User \(membership.userMetadataId) and channel \(membership.channelMetadataId).")
      }

    case .messageActionChanged(let messageActionEvent):
      switch messageActionEvent {
      case .added(let messageAction):
        print("Message action added in \(messageAction.channel) channel at message timetoken \(messageAction.messageTimetoken).")
        print("Action created at \(messageAction.actionTimetoken) with type \(messageAction.actionType) and value \(messageAction.actionValue).")
      case .removed(let messageAction):
        print("The \(messageAction.channel) channel received a message at \(messageAction.messageTimetoken)")
        print("A message reaction with the timetoken of \(messageAction.actionTimetoken) has been removed")
      }

    case .fileChanged(let fileEvent):
      switch fileEvent {
      case .uploaded(let file):
        print("A file was uploaded: \(file)")
      }

    case .dataSyncChanged(let dataSyncEvent):
      print("A DataSync event was received: \(dataSyncEvent)")
    }
  }
}
// snippet.end

// snippet.did-receive-subscription-2
listener.didReceiveSubscription = { event in
  switch event {
    // Same content as the above example
  default:
    break
  }
}
// snippet.end

// snippet.unsubscribe
pubnub.unsubscribe(from: ["my_channel"])
// snippet.end

// snippet.unsubscribe-multiple-channels
pubnub.unsubscribe(from: ["my_channel", "my_channel-2", "my_channel-3"])
// snippet.end

// snippet.unsubscribe-multiple-channel-groups
pubnub.unsubscribe(
  from: [],
  and: ["my_channel", "my_channel-2", "my_channel-3"]
)
// snippet.end

// snippet.unsubscribe-all
pubnub.unsubscribeAll()
// snippet.end
// swiftlint:enable line_length
