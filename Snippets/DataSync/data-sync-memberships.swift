//
//  data-sync-memberships.swift
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

// snippet.membership-payload
// The fields stored on a membership, as a type the SDK can encode into a request and decode from a response
struct MembershipDetails: JSONCodable {
  let role: String
  let unreadCount: Int
  let isMuted: Bool
}

// snippet.end

// MARK: - Reading memberships

// snippet.get-memberships
// Retrieve the memberships of a channel
pubnub.dataSync.getMemberships(channelId: "general", limit: 20) { result in
  switch result {
  case let .success((memberships, next)):
    print("The memberships: \(memberships)")
    print("The next page used for pagination: \(String(describing: next))")
  case let .failure(error):
    print("Get memberships request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-user-memberships
// Retrieve the channels a user belongs to
pubnub.dataSync.getMemberships(userId: "alice", limit: 20) { result in
  switch result {
  case let .success((memberships, _)):
    print("The channels `alice` belongs to: \(memberships.map { $0.channelId })")
  case let .failure(error):
    print("Get memberships request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.sort-memberships
// Sort a page of memberships by the properties declared on the `Membership` class
pubnub.dataSync.getMemberships(
  channelId: "general",
  limit: 20,
  sort: [.init(property: "unreadCount", ascending: false), .init(property: "role")]
) { result in
  switch result {
  case let .success((memberships, _)):
    print("The sorted memberships: \(memberships)")
  case let .failure(error):
    print("Get memberships request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-membership
// Retrieve a single membership by identifier, and decode its payload into your own type
pubnub.dataSync.getMembership("general-alice") { result in
  switch result {
  case let .success(membership):
    print("The membership for `\(membership.id)`: \(membership)")
    print("It joins channel `\(membership.channelId)` and user `\(membership.userId)`")
    print("Its eTag, used for optimistic concurrency: \(membership.eTag)")

    if let details = try? membership.payload?.decode(MembershipDetails.self) {
      print("The member is a \(details.role) with \(details.unreadCount) unread messages")
      print("They muted the channel: \(details.isMuted)")
    }
  case let .failure(error):
    print("Get membership request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// MARK: - Writing memberships

// snippet.create-membership
// Add a user to a channel
pubnub.dataSync.createMembership(
  channelId: "general",
  userId: "alice",
  classVersion: 1,
  id: "general-alice",
  status: "active",
  payload: MembershipDetails(role: "moderator", unreadCount: 0, isMuted: false)
) { result in
  switch result {
  case let .success(membership):
    print("The created membership: \(membership)")
  case let .failure(error):
    print("Create membership request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.replace-membership
// Replace a membership's payload wholesale, only if it hasn't changed since it was read.
// Every field to keep has to be sent back: an omitted field is cleared, not preserved
pubnub.dataSync.replaceMembership(
  "general-alice",
  classVersion: 1,
  status: "active",
  payload: MembershipDetails(role: "member", unreadCount: 7, isMuted: true),
  ifMatchesEtag: "3w5e111uk7djz"
) { result in
  switch result {
  case let .success(membership):
    print("The replaced membership: \(membership)")
  case let .failure(error):
    print("Replace membership request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.patch-membership
// Change part of a membership, leaving the rest of its payload untouched.
// A `Date` value is sent as an ISO 8601 string
pubnub.dataSync.patchMembership(
  "general-alice",
  operations: [
    .replace(path: "/payload/role", value: "admin"),
    .replace(path: "/payload/unreadCount", value: 0),
    .replace(path: "/payload/isMuted", value: false),
    .add(path: "/payload/lastReadAt", value: Date())
  ]
) { result in
  switch result {
  case let .success(membership):
    print("The patched membership: \(membership)")
  case let .failure(error):
    print("Patch membership request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-membership
// Remove a user from a channel
pubnub.dataSync.removeMembership("general-alice") { result in
  switch result {
  case .success:
    print("The membership was removed")
  case let .failure(error):
    print("Remove membership request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end
