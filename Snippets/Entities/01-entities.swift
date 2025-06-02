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
pubnub.channel("channelName")
// snippet.end

// snippet.channel-group-entity
pubnub.channelGroup("channelGroupName")
// snippet.end

// snippet.channel-metadata-entity
pubnub.channelMetadata("channelMetadataName")
// snippet.end

// snippet.user-metadata-entity
pubnub.userMetadata("userMetadataName")
// snippet.end
