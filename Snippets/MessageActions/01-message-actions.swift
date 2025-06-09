//
//  01-message-actions.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

// snippet.import
import PubNubSDK
import Foundation

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

// snippet.add-message-action
pubnub.addMessageAction(
  channel: "my_channel",
  type: "reaction",
  value: "smiley_face",
  messageTimetoken: 15_610_547_826_969_050
) { result in
  switch result {
  case let .success(messageAction):
    print("Action type \(messageAction.actionType) added at \(messageAction.actionTimetoken) with value \(messageAction.actionValue)")
    print("`\(messageAction.publisher)` added action onto message \(messageAction.messageTimetoken) on `\(messageAction.channel)`")
  case let .failure(error):
    print("Error from failed response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-message-action
pubnub.removeMessageActions(
  channel: "my_channel",
  message: 15_610_547_826_969_050,
  action: 15_610_547_826_970_050
) { result in
  switch result {
  case let .success(response):
    print("Action published at \(response.action) was removed from message \(response.message) on channel \(response.channel)")
  case let .failure(error):
    print("Error from failed response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.fetch-message-actions
pubnub.fetchMessageActions(channel: "my_channel") { result in
  switch result {
  case let .success(response):
    print("The actions for the channel \(response.actions)")
    print("The next page used for pagination: \(String(describing: response.next))")
  case let .failure(error):
    print("Error from failed response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.pubnub-time
pubnub.time { result in
  switch result {
  case let .success(timetoken):
    print("Handle downloaded server timetoken: \(timetoken)")
  case let .failure(error):
    print("Handle response error: \(error.localizedDescription)")
  }
}
// snippet.end
