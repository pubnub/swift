//
//  01-history.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

// snippet.fetch-message-history
import PubNubSDK

// Initializes a PubNub object with the configuration
let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// Retrieve the last message on a channel
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
