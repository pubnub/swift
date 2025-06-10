//
//  01-history.swift
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

// snippet.fetch-message-history
// Retrieve messages from a channel
pubnub.fetchMessageHistory(for: ["my_channel"]) { result in
  switch result {
  case let .success(response):
    if let myChannelMessages = response.messagesByChannel["my_channel"] {
      // Iterating over each message in the channel and printing its payload
      myChannelMessages.forEach { historicalMessage in
        print("Message payload: \(historicalMessage.payload)")
      }
    }
    if let nextPage = response.next {
      print("The next page used for pagination: \(nextPage)")
    }
  case let .failure(error):
    print("Failed History Fetch Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.fetch-message-history-end
// Retrieve messages that are newer or equal to a specific timetoken
pubnub.fetchMessageHistory(
  for: ["my_channel"],
  page: PubNubBoundedPageBase(end: 13406746780720711)
) { result in
  switch result {
  case let .success(response):
    if let myChannelMessages = response.messagesByChannel["my_channel"] {
      // Iterating over each message in the channel and printing its payload
      myChannelMessages.forEach { historicalMessage in
        print("Message payload: \(historicalMessage.payload)")
      }
    }
    if let nextPage = response.next {
      print("The next page used for pagination: \(nextPage)")
    }
  case let .failure(error):
    print("Failed History Fetch Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.fetch-message-history-start
// Retrieve messages older than a specific timetoken (exclusive).
// Exclusive means that the message associated with the `13406746780720711` timetoken will be excluded from the result.
pubnub.fetchMessageHistory(
  for: ["my_channel"],
  page: PubNubBoundedPageBase(start: 13406746780720711)
) { result in
  switch result {
  case let .success(response):
    if let myChannelMessages = response.messagesByChannel["my_channel"] {
      // Iterating over each message in the channel and printing its payload
      myChannelMessages.forEach { historicalMessage in
        print("Message payload: \(historicalMessage.payload)")
      }
    }
    if let nextPage = response.next {
      print("The next page used for pagination: \(nextPage)")
    }
  case let .failure(error):
    print("Failed History Fetch Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.fetch-message-history-limit
// Retrieve messages from multiple channels with a limit on the number of messages returned
pubnub.fetchMessageHistory(
  for: ["channelSwift", "otherChannel", "myChannel"],
  page: PubNubBoundedPageBase(limit: 10)
) { result in
  switch result {
  case let .success(response):
    response.messagesByChannel.forEach { channel, messages in
      print("Channel `\(channel)` has the following messages: \(messages)")
    }
    if let nextPage = response.next {
      print("The next page used for pagination: \(nextPage)")
    }
  case let .failure(error):
    print("Failed History Fetch Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.fetch-message-history-include-meta
// Retrieve messages from a channel with metadata
pubnub.fetchMessageHistory(
  for: ["my_channel"],
  includeMeta: true
) { result in
  switch result {
  case let .success(response):
    if let myChannelMessages = response.messagesByChannel["my_channel"] {
      // Iterating over each message in the channel to print its payload and metadata
      myChannelMessages.forEach { message in
        print("Message sent at \(message.published):")
        print("Payload: \(message.payload)")
        print("Metadata: \(String(describing: message.metadata))")
      }
    }
    if let nextPage = response.next {
      print("The next page used for pagination: \(nextPage)")
    }
  case let .failure(error):
    print("Failed History Fetch Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.fetch-message-history-include-actions
// Retrieve messages from a channel with actions
pubnub.fetchMessageHistory(
  for: ["my_channel"],
  includeActions: true
) { result in
  switch result {
  case let .success(response):
    if let myChannelMessages = response.messagesByChannel["my_channel"] {
      myChannelMessages.forEach { message in
        print("Message sent at \(message.published):")
        print("Actions: \(message.actions)")
      }
    }
    if let nextPage = response.next {
      print("The next page used for pagination: \(nextPage)")
    }
  case let .failure(error):
    print("Failed History Fetch Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.delete-message-history
// Delete all messages from a channel
pubnub.deleteMessageHistory(
  from: "my_channel"
) { result in
  switch result {
  case .success:
    print("The message deletion was successful")
  case let .failure(error):
    print("Failed Message Deletion Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.delete-specific-message-from-history
// Delete a specific message from a channel
pubnub.deleteMessageHistory(
  from: "my_channel",
  start: 15526611838554309,
  end: 15526611838554310
) { result in
  switch result {
  case .success:
    print("The message deletion was successful")
  case let .failure(error):
    print("Failed Message Deletion Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.message-counts
// Retrieve the message count for a channel
pubnub.messageCounts(channels: ["my_channel"]) { result in
  switch result {
  case let .success(messageCountByChannel):
    if let myChannelCount = messageCountByChannel["my_channel"] {
      print("The current message count for `my_channel` is \(myChannelCount)")
    }
  case let .failure(error):
    print("Failed Message Count Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.message-counts-multiple-channels
// Retrieve the message count for multiple channels
pubnub.messageCounts(
  channels: ["my_channel", "other_channel", "their_channel"],
  timetoken: 15526611838554310
) { result in
  switch result {
  case let .success(messageCountByChannel):
    messageCountByChannel.forEach { channel, messageCount in
      print("The current message count for `\(channel)` is \(messageCount)")
    }
  case let .failure(error):
    print("Failed Message Count Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.message-counts-multiple-channels-different-timetokens
// Retrieve the message count for multiple channels with different timetokens
pubnub.messageCounts(
  channels: [
    "my_channel": 15526611838554309,
    "other_channel": 15526611838554310,
    "their_channel": 1
  ]
) { result in
  switch result {
  case let .success(messageCountByChannel):
    messageCountByChannel.forEach { channel, messageCount in
      print("The current message count for `\(channel)` is \(messageCount)")
    }
  case let .failure(error):
    print("Failed Message Count Response: \(error.localizedDescription)")
  }
}
// snippet.end
