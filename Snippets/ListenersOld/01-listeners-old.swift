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
  case let .connectionStatusChanged(status):
    print("Status Received: \(status)")
  case let .presenceChanged(presence):
    print("Presence Received: \(presence)")
  case let .subscribeError(error):
    print("Subscription Error \(error)")
  default:
    break
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

    case .connectionStatusChanged(let connectionChange):
      switch connectionChange {
      case let .subscriptionChanged(channels, groups):
        print("The SDK has subscribed to new channels or channel groups after the initial connection")
        print("Currently subscribed channels: \(channels)")
        print("Currently subscribed groups: \(channels)")
      case .connected:
        print("Connection status: connected!")
      case .disconnected:
        print("Connection status: disconnected!")
      case let .connectionError(error):
        print("Connection status: connection error! \(error.localizedDescription)")
      case let .disconnectedUnexpectedly(error):
        print("Connection status: disconnected unexpectedly due to error! \(error.localizedDescription)")
      }

    case .subscriptionChanged(let subscribeChange):
      switch subscribeChange {
      case let .subscribed(channels, groups):
        print("Subscribed to channels: \(channels), groups: \(groups).")
      case let .responseHeader(channels, groups, previous, next):
        print("Response received from channels: \(channels), groups: \(groups). Previous timetoken: \(previous?.timetoken ?? 0). Next timetoken: \(next?.timetoken ?? 0).")
      case let .unsubscribed(channels, groups):
        print("Unsubscribed from channels: \(channels), groups: \(groups).")
      }

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

    case .uuidMetadataSet(let uuidMetadataChange):
      print("UUID metadata changes detected for \(uuidMetadataChange.metadataId) at \(uuidMetadataChange.updated).")
      print("All changes made to the object: \(uuidMetadataChange.changes)")
      print("To apply these changes, fetch the relevant object and call `uuidMetadataChange.apply(to: otherUUIDMetadata)`.")

    case .uuidMetadataRemoved(let metadataId):
      print("Metadata for UUID \(metadataId) has been removed.")

    case .channelMetadataSet(let channelMetadata):
      print("Channel metadata changes detected for \(channelMetadata.metadataId) at \(channelMetadata.updated).")
      print("All changes made to the object: \(channelMetadata.changes)")
      print("To apply these changes, fetch the relevant object and call `channelMetadata.apply(to: otherChannelMetadata)`.")

    case .channelMetadataRemoved(let metadataId):
      print("Metadata for channel \(metadataId) has been removed.")

    case .membershipMetadataSet(let membership):
      print("Membership established between UUID \(membership.uuidMetadataId) and channel \(membership.channelMetadataId).")

    case .membershipMetadataRemoved(let membership):
      print("Membership removed between UUID \(membership.uuidMetadataId) and channel \(membership.channelMetadataId).")

    case .messageActionAdded(let messageAction):
      print("Message action added in \(messageAction.channel) channel at message timetoken \(messageAction.messageTimetoken).")
      print("Action created at \(messageAction.actionTimetoken) with type \(messageAction.actionType) and value \(messageAction.actionValue).")

    case .messageActionRemoved(let messageAction):
      print("The \(messageAction.channel) channel received a message at \(messageAction.messageTimetoken)")
      print("A message reaction with the timetoken of \(messageAction.actionTimetoken) has been removed")

    case .subscribeError(let error):
      print("Subscription error occurred: \(error.localizedDescription). Check if a `disconnectedUnexpectedly` status also happened; if so, restart the subscription.")

    case let .fileUploaded(fileEvent):
      print("A file was uploaded: \(fileEvent)")
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
