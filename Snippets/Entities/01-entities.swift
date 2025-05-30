import PubNubSDK

// Initializes a PubNub object with the configuration
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
