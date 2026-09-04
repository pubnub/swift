//
//  data-sync-users.swift
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

// snippet.user-payload
// The fields stored on a user, as a type the SDK can encode into a request and decode from a response
struct UserProfile: JSONCodable {
  let fullName: String
  let email: String
  let loginCount: Int
  let isEmailVerified: Bool
}

// snippet.end

// MARK: - Reading users

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

// snippet.sort-users
// Sort a page of users by the properties declared on the `user` class
pubnub.dataSync.getUsers(
  limit: 20,
  sort: [.init(property: "isEmailVerified", ascending: false), .init(property: "fullName")]
) { result in
  switch result {
  case let .success((users, _)):
    print("The sorted users: \(users)")
  case let .failure(error):
    print("Get users request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-user
// Retrieve a single user by identifier, and decode its payload into your own type
pubnub.dataSync.getUser(id: "alice") { result in
  switch result {
  case let .success(user):
    print("The user for `\(user.id)`: \(user)")
    print("Its eTag, used for optimistic concurrency: \(user.eTag)")

    do {
      if let profile = try user.payload?.decode(UserProfile.self) {
        print("\(profile.fullName) has logged in \(profile.loginCount) times")
        print("Their email is verified: \(profile.isEmailVerified)")
      } else {
        print("The user has no stored payload")
      }
    } catch {
      print("Could not decode \(user.className) version \(user.classVersion) for user \(user.id): \(error)")
    }
  case let .failure(error):
    print("Get user request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// MARK: - Writing users

// snippet.create-user
// Create a user
pubnub.dataSync.createUser(
  classVersion: 1,
  id: "alice",
  status: "active",
  payload: UserProfile(
    fullName: "Alice Summers",
    email: "alice@example.com",
    loginCount: 0,
    isEmailVerified: false
  )
) { result in
  switch result {
  case let .success(user):
    print("The created user: \(user)")
  case let .failure(error):
    print("Create user request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.set-user
// Replace every mutable field. Every field to keep must be sent back; an omitted field is cleared
pubnub.dataSync.setUser(
  id: "alice",
  classVersion: 1,
  status: "active",
  payload: UserProfile(
    fullName: "Alice R. Summers",
    email: "alice.summers@example.com",
    loginCount: 12,
    isEmailVerified: true
  ),
  ifMatchesEtag: "3w5e111uk7djz" // Always provide the eTag from the most recent response
) { result in
  switch result {
  case let .success(user):
    print("The set user: \(user)")
  case let .failure(error):
    print("Set user request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.update-user
// Change selected fields, leaving every unaddressed field untouched
pubnub.dataSync.updateUser(
  id: "alice",
  operations: [
    .replace(path: "/payload/email", value: "alice.summers@example.com"),
    .replace(path: "/payload/isEmailVerified", value: true),
    .replace(path: "/payload/loginCount", value: 13),
    .add(path: "/payload/nickname", value: "Ali")
  ],
  ifMatchesEtag: "3w5e111uk7djz" // Always provide the eTag from the most recent response
) { result in
  switch result {
  case let .success(user):
    print("The updated user: \(user)")
  case let .failure(error):
    print("Update user request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-user
// Remove a user
pubnub.dataSync.removeUser(
  id: "alice",
  ifMatchesEtag: "3w5e111uk7djz" // Always provide the eTag from the most recent response
) { result in
  switch result {
  case .success:
    print("The user was removed")
  case let .failure(error):
    print("Remove user request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end
