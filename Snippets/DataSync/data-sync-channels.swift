//
//  data-sync-channels.swift
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

// snippet.channel-payload
// The fields stored on a channel, as a type the SDK can encode into a request and decode from a response
struct ChannelDetails: JSONCodable {
  let name: String
  let topic: String
  let retentionDays: Int
  let isPrivate: Bool
}

// snippet.end

// MARK: - Reading channels

// snippet.get-channels
// Retrieve a page of channels
pubnub.dataSync.getChannels(limit: 20) { result in
  switch result {
  case let .success((channels, next)):
    print("The channels: \(channels)")
    print("The next page used for pagination: \(String(describing: next))")
  case let .failure(error):
    print("Get channels request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.sort-channels
// Sort a page of channels by the properties declared on the `channel` class
pubnub.dataSync.getChannels(
  limit: 20,
  sort: [.init(property: "retentionDays", ascending: false), .init(property: "name")]
) { result in
  switch result {
  case let .success((channels, _)):
    print("The sorted channels: \(channels)")
  case let .failure(error):
    print("Get channels request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-channel
// Retrieve a single channel by identifier, and decode its payload into your own type
pubnub.dataSync.getChannel(id: "general") { result in
  switch result {
  case let .success(channel):
    print("The channel for `\(channel.id)`: \(channel)")
    print("Its eTag, used for optimistic concurrency: \(channel.eTag)")

    do {
      if let details = try channel.payload?.decode(ChannelDetails.self) {
        print("\(details.name) discusses \(details.topic)")
        print("It keeps messages for \(details.retentionDays) days, and is private: \(details.isPrivate)")
      } else {
        print("The channel has no stored payload")
      }
    } catch {
      print("The payload isn't a \(ChannelDetails.self): \(error)")
    }
  case let .failure(error):
    print("Get channel request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// MARK: - Writing channels

// snippet.create-channel
// Create a channel
pubnub.dataSync.createChannel(
  classVersion: 1,
  id: "general",
  status: "active",
  payload: ChannelDetails(
    name: "General",
    topic: "Company-wide announcements",
    retentionDays: 30,
    isPrivate: false
  )
) { result in
  switch result {
  case let .success(channel):
    print("The created channel: \(channel)")
  case let .failure(error):
    print("Create channel request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.set-channel
// Set a channel's payload wholesale, only if it hasn't changed since it was read.
// Every field to keep has to be sent back: an omitted field is cleared, not preserved
pubnub.dataSync.setChannel(
  id: "general",
  classVersion: 1,
  status: "active",
  payload: ChannelDetails(
    name: "General",
    topic: "All-hands announcements",
    retentionDays: 90,
    isPrivate: false
  ),
  ifMatchesEtag: "3w5e111uk7djz"
) { result in
  switch result {
  case let .success(channel):
    print("The set channel: \(channel)")
  case let .failure(error):
    print("Set channel request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.update-channel
// Change part of a channel, leaving the rest of its payload untouched.
// The operations are applied atomically: if any one of them fails, the channel is left unchanged
pubnub.dataSync.updateChannel(
  id: "general",
  operations: [
    .replace(path: "/payload/topic", value: "Company announcements"),
    .replace(path: "/payload/retentionDays", value: 365),
    .replace(path: "/payload/isPrivate", value: true),
    .add(path: "/payload/archivedAt", value: "2026-08-11")
  ]
) { result in
  switch result {
  case let .success(channel):
    print("The updated channel: \(channel)")
  case let .failure(error):
    print("Update channel request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-channel
// Remove a channel
pubnub.dataSync.removeChannel(id: "general") { result in
  switch result {
  case .success:
    print("The channel was removed")
  case let .failure(error):
    print("Remove channel request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end
