//
//  01-presence.swift
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

// snippet.here-now
// Get presence information for a channel
pubnub.hereNow(on: ["my_channel"]) { result in
  switch result {
  case let .success(response):
    print("Total channels: \(response.presenceByChannel.count)")
    print("Total occupancy across all channels: \(response.presenceByChannel.totalOccupancy)")

    if let myChannelPresence = response.presenceByChannel["my_channel"] {
      print("The occupancy for `my_channel` is \(myChannelPresence.occupancy)")
      // Iterating over each occupant in the channel and printing their UUID
      myChannelPresence.occupants.forEach { occupant in
        print("Occupant UUID: \(occupant)")
      }
    }
  case let .failure(error):
    print("Failed hereNow Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.here-now-2
// Get presence information for a channel without UUIDs
pubnub.hereNow(
  on: ["my-channel"],
  includeUUIDs: false
) { result in
  switch result {
  case let .success(response):
    if let myChannelPresence = response.presenceByChannel["my_channel"] {
      print("The occupancy for `my_channel` is \(myChannelPresence.occupancy)")
    }
  case let .failure(error):
    print("Failed hereNow Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.here-now-channel-groups
// Get presence information for a channel group
pubnub.hereNow(
  on: [],
  and: ["my-channel-group"]
) { result in
  switch result {
  case let .success(response):
    print("The `Dictionary` of channels mapped to their respective `PubNubPresence`: \(response.presenceByChannel)")
  case let .failure(error):
    print("Failed hereNow Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.where-now
// Get the channels that a specific UUID is present on
pubnub.whereNow(for: "my-unique-uuid") { result in
  switch result {
  case let .success(channelsByUUID):
    print("A `Dictionary` of UUIDs mapped to their respective `Array` of channels they have presence on \(channelsByUUID)")
    if let channels = channelsByUUID["my-unique-uuid"] {
      print("The list of channel identifiers for the UUID `my-unique-uuid`: \(channels)")
    }
  case let .failure(error):
    print("Failed WhereNow Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.set-presence-state
// Set the presence state for a channel and channel group
pubnub.setPresence(
  state: ["new": "state"],
  on: ["channelSwift"],
  and: ["demo"]
) { result in
  switch result {
  case let .success(presenceSet):
    print("The presence State set as a `JSONCodable`: \(presenceSet)")
  case let .failure(error):
    print("Failed Set State Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-presence-state
// Get the presence state for a channel and channel group
pubnub.getPresenceState(
  for: pubnub.configuration.uuid,
  on: ["channelSwift"],
  and: ["demo"]
) { result in
  switch result {
  case let .success(uuid, stateByChannel):
    print("The UUID `\(uuid)` has the following presence state \(stateByChannel)")
  case let .failure(error):
    print("Failed Get State Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-presence-state-decode
// Get the presence state for a channel and decode it into a Dictionary type
pubnub.setPresence(
  state: ["new": "state"],
  on: ["channelSwift"]
) { result in
  switch result {
  case let .success(presenceSet):
    print("The String value for `New` is: \(presenceSet.codableValue[rawValue: "new"] as? String)")
  case let .failure(error):
    print("Failed Set State Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-presence-state-decode-2
// Declares the type to decode the state value into
struct MyPresenceState: JSONCodable {
  var new: String
}

// Set the presence state for a channel and decode it into a custom type
pubnub.setPresence(
  state: ["new": "state"],
  on: ["channelSwift"]
) { result in
  switch result {
  case let .success(presenceSet):
    print("The Object representation is: \(try? presenceSet.codableValue.decode(MyPresenceState.self))")
  case let .failure(error):
    print("Failed Set State Response: \(error.localizedDescription)")
  }
}
// snippet.end
