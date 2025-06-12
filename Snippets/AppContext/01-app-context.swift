//
//  01-app-context.swift
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

// snippet.all-user-metadata
// Retrieve all user metadata
pubnub.allUserMetadata { result in
  switch result {
  case let .success(response):
    print("The user metadata objects: \(response.users)")
    print("The next page used for pagination: \(String(describing: response.next))")
  case let .failure(error):
    print("Fetch All request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.fetch-user-metadata
// Retrieve user metadata for a specific identifier
pubnub.fetchUserMetadata("some-id") { result in
  switch result {
  case let .success(userMetadata):
    print("The metadata for `\(userMetadata.metadataId)`: \(userMetadata)")
  case let .failure(error):
    print("Fetch request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.set-user-metadata
// Set user metadata for a specific identifier
let userMetadataToSet = PubNubUserMetadataBase(
  metadataId: "some-id",
  name: "Some User",
  custom: ["department": "Engineering"]
)

pubnub.setUserMetadata(userMetadataToSet) { result in
  switch result {
  case let .success(userMetadata):
    print("The metadata for `\(userMetadata.metadataId)`: \(userMetadata)")
  case let .failure(error):
    print("Create request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-user-metadata
// Remove user metadata for a specific identifier
pubnub.removeUserMetadata("some-id") { result in
  switch result {
  case let .success(metadataId):
    print("The metadata has been removed for the identifier `\(metadataId)`")
  case let .failure(error):
    print("Delete request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.all-channel-metadata
// Retrieve all channel metadata
pubnub.allChannelMetadata { result in
  switch result {
  case let .success(response):
    print("The channel metadata objects \(response.channels)")
    print("The next page used for pagination: \(String(describing: response.next))")
  case let .failure(error):
    print("Fetch All request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.fetch-channel-metadata
// Retrieve channel metadata for a specific identifier
pubnub.fetchChannelMetadata("some-channel-id") { result in
  switch result {
  case let .success(channelMetadata):
    print("The metadata for `\(channelMetadata.metadataId)`: \(channelMetadata)")
  case let .failure(error):
    print("Fetch request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.set-channel-metadata
// Set channel metadata for a specific identifier
let channelMetadataToSet = PubNubChannelMetadataBase(
  metadataId: "some-channel-id",
  name: "Channel Name"
)

pubnub.setChannelMetadata(channelMetadataToSet) { result in
  switch result {
  case let .success(channelMetadata):
    print("The metadata for `\(channelMetadata.metadataId)`: \(channelMetadata)")
  case let .failure(error):
    print("Create request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.update-existing-channel-metadata
// Simulates a reference to already fetched channel metadata
var existingChannelMetadata = PubNubChannelMetadataBase(
  metadataId: "yourChannelMetadataId",
  name: "Offtopic",
  type: "Miscellaneous",
  status: "active",
  custom: ["admin": "John Stones"]
)

// Modify properties directly, such as updating `custom` and `name`
existingChannelMetadata.custom = ["admin": "Charles Dawson"]
existingChannelMetadata.name = "Unrelated"

// When you're ready, set the updated metadata on the server to persist the changes:
pubnub.setChannelMetadata(existingChannelMetadata) { result in
  switch result {
  case let .success(metadata):
    print("Did successfully set channel metadata with \(metadata.metadataId)")
  case let .failure(error):
    print("Unexpected error along the way: \(error)")
  }
}
// snippet.end

// snippet.remove-channel-metadata
// Remove channel metadata for a specific identifier
pubnub.removeChannelMetadata("some-channel-id") { result in
  switch result {
  case let .success(metadataId):
    print("The metadata has been removed for the channel `\(metadataId)`")
  case let .failure(error):
    print("Delete request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.fetch-memberships
// Retrieve channel memberships for a specific user identifier
pubnub.fetchMemberships(userId: "some-user-id") { result in
  switch result {
  case let .success(response):
    print("The channel memberships for the userId: \(response.memberships)")
    print("The next page used for pagination: \(String(describing: response.next))")
  case let .failure(error):
    print("Fetch Memberships request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.fetch-memberships-sort
// Retrieve channel memberships for a specific user identifier and sort them by name
pubnub.fetchMemberships(
  userId: "someUserId",
  sort: [.init(property: .object(.name))]
) { result in
  switch result {
  case let .success(response):
    print("List of channel memberships: \(response.memberships)")
    print("The next page used for pagination: \(String(describing: response.next))")
  case let .failure(error):
    print("An error occurred: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.set-memberships
let membershipToSet = PubNubMembershipMetadataBase(
  userMetadataId: "my_user",
  channelMetadataId: "my_channel"
)

// Set channel memberships for a specific user identifier
pubnub.setMemberships(
  userId: membershipToSet.userMetadataId,
  channels: [membershipToSet]
) { result in
  switch result {
  case let .success(response):
    print("The channel memberships for the userId: \(response.memberships)")
    print("The next page used for pagination: \(String(describing: response.next))")
  case let .failure(error):
    print("Update Memberships request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-memberships
let membershipToRemove = PubNubMembershipMetadataBase(
  userMetadataId: "my_user",
  channelMetadataId: "my_channel"
)

// Remove channel memberships for a specific user identifier
pubnub.removeMemberships(
  userId: membershipToRemove.userMetadataId,
  channels: [membershipToRemove]
) { result in
  switch result {
  case let .success(response):
    print("The channel memberships for the userId: \(response.memberships)")
    print("The next page used for pagination: \(String(describing: response.next))")
  case let .failure(error):
    print("Update Memberships request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.fetch-members
// Retrieve members for a specific channel
pubnub.fetchMembers(channel: "my_channel_id") { result in
  switch result {
  case let .success(response):
    print("The user members for the channel: \(response.memberships)")
    print("The next page used for pagination: \(String(describing: response.next))")
  case let .failure(error):
    print("Fetch Memberships request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.set-members
let userToSet = PubNubMembershipMetadataBase(
  userMetadataId: "my_user",
  channelMetadataId: "my_channel"
)

// Set members for a specific channel
pubnub.setMembers(
  channel: userToSet.channelMetadataId,
  users: [userToSet]
) { result in
  switch result {
  case let .success(response):
    print("The user members for the channel: \(response.memberships)")
    print("The next page used for pagination: \(String(describing: response.next))")
  case let .failure(error):
    print("Update Memberships request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-members
let memberToRemove = PubNubMembershipMetadataBase(
  userMetadataId: "my_user",
  channelMetadataId: "my_channel"
)

// Remove members for a specific channel
pubnub.removeMembers(
  channel: memberToRemove.channelMetadataId,
  users: [memberToRemove]
) { result in
  switch result {
  case let .success(response):
    print("The user members of the channel: \(response.memberships)")
    print("The next page used for pagination: \(String(describing: response.next))")
  case let .failure(error):
    print("Update Memberships request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end
