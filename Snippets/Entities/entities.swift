//
//  01-entities.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK

let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// snippet.channel-entity
// Create a Pub/Sub channel reference
pubnub.channel("channelName")
// snippet.end

// snippet.channel-group-entity
// Create a Pub/Sub channel group reference
pubnub.channelGroup("channelGroupName")
// snippet.end

// snippet.channel-metadata-entity
// Create an App Context channel metadata reference
pubnub.channelMetadata("channelMetadataId")
// snippet.end

// snippet.user-metadata-entity
// Create an App Context user metadata reference
pubnub.userMetadata("userMetadataId")
// snippet.end

// snippet.data-sync-user-entity
// Create a Data Sync user reference
pubnub.dataSyncUser("player-1")
// snippet.end

// snippet.data-sync-channel-entity
// Create a Data Sync channel reference
pubnub.dataSyncChannel("team-1")
// snippet.end

// snippet.data-sync-membership-entity
// Create a Data Sync membership reference
pubnub.dataSyncMembership("membership-1")
// snippet.end

// snippet.data-sync-entity
// Create a Data Sync custom entity reference
pubnub.dataSyncEntity("match-1")
// snippet.end

// snippet.data-sync-relationship-entity
// Create a Data Sync custom relationship reference
pubnub.dataSyncRelationship("relationship-1")
// snippet.end

// snippet.data-sync-projection-subscription
// Subscribe to a custom projection of a Data Sync entity
pubnub.dataSyncEntity("match-1").subscription(projection: "stats")
// snippet.end
