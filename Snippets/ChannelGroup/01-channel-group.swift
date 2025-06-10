//
//  01-channel-group.swift
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

// snippet.add-channels
pubnub.add(
  channels: ["channelSwift", "otherChannel"],
  to: "SwiftGroup"
) { result in
  switch result {
  case let .success(response):
    print("The channel-group `\(response.group)` had the following channels added: \(response.channels)")
  case let .failure(error):
    print("Failed Add Channels Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.list-channels
pubnub.listChannels(for: "family") { result in
  switch result {
  case let .success(response):
    print("The channel-group `\(response.group)` is made of the following channels: \(response.channels)")
  case let .failure(error):
    print("Failed Add Channels Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-channels
pubnub.remove(
  channels: ["channelSwift", "otherChannel"],
  from: "SwiftGroup"
) { result in
  switch result {
  case let .success(response):
    print("The channel-group `\(response.group)` had the following channels removed: \(response.channels)")
  case let .failure(error):
    print("Failed Add Channels Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.list-channel-groups
pubnub.listChannelGroups { result in
  switch result {
  case let .success(channelGroups):
    print("List of all channel-groups: \(channelGroups)")
  case let .failure(error):
    print("Failed Channel Groups Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-channel-group
pubnub.remove(channelGroup: "SwiftGroup") { result in
  switch result {
  case let .success(channelGroup):
    print("The channel-group that was removed: \(channelGroup)")
  case let .failure(error):
    print("Failed Add Channels Response: \(error.localizedDescription)")
  }
}
// snippet.end
