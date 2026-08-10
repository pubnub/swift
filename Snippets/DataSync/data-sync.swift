//
//  data-sync.swift
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

// MARK: - Entities

// snippet.get-entities
// Retrieve a page of entities of a given class
pubnub.dataSync.getEntities(entityClass: "patient", limit: 20) { result in
  switch result {
  case let .success((entities, next)):
    print("The entities: \(entities)")
    print("The next page used for pagination: \(String(describing: next))")
  case let .failure(error):
    print("Get entities request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.sort-entities
// Sort a page of entities by the properties declared on their class
pubnub.dataSync.getEntities(
  entityClass: "patient",
  limit: 20,
  sort: [.init(property: "fullName", ascending: false), .init(property: "mrn")]
) { result in
  switch result {
  case let .success((entities, next)):
    print("The sorted entities: \(entities)")
    print("The next page used for pagination: \(String(describing: next))")
  case let .failure(error):
    print("Get entities request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-entity
// Retrieve a single entity by identifier
pubnub.dataSync.getEntity("hcn-patient-alice") { result in
  switch result {
  case let .success(entity):
    print("The entity for `\(entity.id)`: \(entity)")
    print("Its class: \(entity.className)")
  case let .failure(error):
    print("Get entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.create-entity
// Create an entity of a registered class
pubnub.dataSync.createEntity(
  entityClass: "patient",
  entityClassVersion: 1,
  id: "hcn-patient-alice",
  status: "active",
  payload: ["mrn": "MRN-100001", "fullName": "Alice Summers"]
) { result in
  switch result {
  case let .success(entity):
    print("The created entity: \(entity)")
    print("Its eTag, used for optimistic concurrency: \(entity.eTag)")
  case let .failure(error):
    print("Create entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.replace-entity
// Replace an entity's payload wholesale, only if it hasn't changed since it was read
pubnub.dataSync.replaceEntity(
  "hcn-patient-alice",
  entityClassVersion: 1,
  status: "active",
  payload: ["mrn": "MRN-100001", "fullName": "Alice R. Summers"],
  ifMatchesEtag: "3w5e111uk7djz"
) { result in
  switch result {
  case let .success(entity):
    print("The replaced entity: \(entity)")
  case let .failure(error):
    print("Replace entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.patch-entity
// Apply RFC 6902 JSON Patch operations to an entity
pubnub.dataSync.patchEntity(
  "hcn-patient-alice",
  operations: [
    .replace(path: "/status", value: "inactive"),
    .add(path: "/payload/dischargedAt", value: "2026-08-07"),
    .remove(path: "/payload/isSmoker")
  ]
) { result in
  switch result {
  case let .success(entity):
    print("The patched entity: \(entity)")
  case let .failure(error):
    print("Patch entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-entity
// Remove an entity
pubnub.dataSync.removeEntity("hcn-patient-alice") { result in
  switch result {
  case .success:
    print("The entity was removed")
  case let .failure(error):
    print("Remove entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// MARK: - Users

// snippet.get-users
// Retrieve a page of users
pubnub.dataSync.getUsers(limit: 20) { result in
  switch result {
  case let .success((users, next)):
    print("The users: \(users)")
    print("The next page used for pagination: \(String(describing: next))")
  case let .failure(error):
    print("Get users request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-user
// Retrieve a single user by identifier
pubnub.dataSync.getUser("alice") { result in
  switch result {
  case let .success(user):
    print("The user for `\(user.id)`: \(user)")
  case let .failure(error):
    print("Get user request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.create-user
// Create a user
pubnub.dataSync.createUser(
  classVersion: 1,
  id: "alice",
  status: "active",
  payload: ["fullName": "Alice Summers", "email": "alice@example.com"]
) { result in
  switch result {
  case let .success(user):
    print("The created user: \(user)")
  case let .failure(error):
    print("Create user request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.replace-user
// Replace a user's payload wholesale
pubnub.dataSync.replaceUser(
  "alice",
  classVersion: 1,
  status: "active",
  payload: ["fullName": "Alice R. Summers", "email": "alice@example.com"]
) { result in
  switch result {
  case let .success(user):
    print("The replaced user: \(user)")
  case let .failure(error):
    print("Replace user request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.patch-user
// Apply JSON Patch operations to a user
pubnub.dataSync.patchUser(
  "alice",
  operations: [.replace(path: "/payload/email", value: "alice.summers@example.com")]
) { result in
  switch result {
  case let .success(user):
    print("The patched user: \(user)")
  case let .failure(error):
    print("Patch user request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-user
// Remove a user
pubnub.dataSync.removeUser("alice") { result in
  switch result {
  case .success:
    print("The user was removed")
  case let .failure(error):
    print("Remove user request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// MARK: - Channels

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

// snippet.get-channel
// Retrieve a single channel by identifier
pubnub.dataSync.getChannel("general") { result in
  switch result {
  case let .success(channel):
    print("The channel for `\(channel.id)`: \(channel)")
  case let .failure(error):
    print("Get channel request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.create-channel
// Create a channel
pubnub.dataSync.createChannel(
  classVersion: 1,
  id: "general",
  status: "active",
  payload: ["name": "General", "description": "Company-wide announcements"]
) { result in
  switch result {
  case let .success(channel):
    print("The created channel: \(channel)")
  case let .failure(error):
    print("Create channel request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.replace-channel
// Replace a channel's payload wholesale
pubnub.dataSync.replaceChannel(
  "general",
  classVersion: 1,
  status: "active",
  payload: ["name": "General", "description": "All-hands announcements"]
) { result in
  switch result {
  case let .success(channel):
    print("The replaced channel: \(channel)")
  case let .failure(error):
    print("Replace channel request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.patch-channel
// Apply JSON Patch operations to a channel
pubnub.dataSync.patchChannel(
  "general",
  operations: [.replace(path: "/payload/description", value: "Company announcements")]
) { result in
  switch result {
  case let .success(channel):
    print("The patched channel: \(channel)")
  case let .failure(error):
    print("Patch channel request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-channel
// Remove a channel
pubnub.dataSync.removeChannel("general") { result in
  switch result {
  case .success:
    print("The channel was removed")
  case let .failure(error):
    print("Remove channel request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// MARK: - Memberships

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

// snippet.get-membership
// Retrieve a single membership by identifier
pubnub.dataSync.getMembership("general-alice") { result in
  switch result {
  case let .success(membership):
    print("The membership for `\(membership.id)`: \(membership)")
    print("It joins channel `\(membership.channelId)` and user `\(membership.userId)`")
  case let .failure(error):
    print("Get membership request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.create-membership
// Add a user to a channel
pubnub.dataSync.createMembership(
  channelId: "general",
  userId: "alice",
  classVersion: 1,
  id: "general-alice",
  status: "active",
  payload: ["role": "moderator"]
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
// Replace a membership's payload wholesale
pubnub.dataSync.replaceMembership(
  "general-alice",
  classVersion: 1,
  status: "active",
  payload: ["role": "member"]
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
// Apply JSON Patch operations to a membership
pubnub.dataSync.patchMembership(
  "general-alice",
  operations: [.replace(path: "/payload/role", value: "admin")]
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

// MARK: - Relationships

// snippet.get-relationships
// Retrieve a page of relationships of a given class
pubnub.dataSync.getRelationships(relationshipClass: "attending-physician", limit: 20) { result in
  switch result {
  case let .success((relationships, next)):
    print("The relationships: \(relationships)")
    print("The next page used for pagination: \(String(describing: next))")
  case let .failure(error):
    print("Get relationships request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-relationship
// Retrieve a single relationship by identifier
pubnub.dataSync.getRelationship("hcn-rel-attending-carter-alice") { result in
  switch result {
  case let .success(relationship):
    print("The relationship for `\(relationship.id)`: \(relationship)")
    print("It joins `\(relationship.entityAId)` and `\(relationship.entityBId)`")
  case let .failure(error):
    print("Get relationship request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.create-relationship
// Relate two entities
pubnub.dataSync.createRelationship(
  relationshipClass: "attending-physician",
  entityAId: "hcn-practitioner-carter",
  entityBId: "hcn-patient-alice",
  relationshipClassVersion: 1,
  id: "hcn-rel-attending-carter-alice",
  status: "active",
  payload: AnyJSON(["role": "attending", "isPrimary": true])
) { result in
  switch result {
  case let .success(relationship):
    print("The created relationship: \(relationship)")
  case let .failure(error):
    print("Create relationship request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.replace-relationship
// Replace a relationship's payload wholesale
pubnub.dataSync.replaceRelationship(
  "hcn-rel-attending-carter-alice",
  relationshipClassVersion: 1,
  status: "active",
  payload: AnyJSON(["role": "consulting", "isPrimary": false])
) { result in
  switch result {
  case let .success(relationship):
    print("The replaced relationship: \(relationship)")
  case let .failure(error):
    print("Replace relationship request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.patch-relationship
// Apply JSON Patch operations to a relationship
pubnub.dataSync.patchRelationship(
  "hcn-rel-attending-carter-alice",
  operations: [.replace(path: "/payload/visitsPerMonth", value: 1)]
) { result in
  switch result {
  case let .success(relationship):
    print("The patched relationship: \(relationship)")
  case let .failure(error):
    print("Patch relationship request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-relationship
// Remove a relationship
pubnub.dataSync.removeRelationship("hcn-rel-attending-carter-alice") { result in
  switch result {
  case .success:
    print("The relationship was removed")
  case let .failure(error):
    print("Remove relationship request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// MARK: - Pagination

// snippet.paginate-entities
// Walk forward through pages of entities using the returned cursor
pubnub.dataSync.getEntities(entityClass: "patient", limit: 20) { result in
  switch result {
  case let .success((entities, next)):
    print("The first page: \(entities)")

    guard let next = next, next.hasNext else {
      return
    }
    pubnub.dataSync.getEntities(
      entityClass: "patient",
      cursor: next.cursor,
      limit: next.limit
    ) { result in
      print("The second page: \(result)")
    }
  case let .failure(error):
    print("Get entities request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end
