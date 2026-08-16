//
//  data-sync-relationships.swift
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

// snippet.relationship-payload
// The fields stored on an `enrollment` relationship, as a type the SDK can encode into a request
// and decode from a response
struct EnrollmentDetails: JSONCodable {
  let role: String
  let completedLessons: Int
  let isActive: Bool
  let grade: String?
}

// snippet.end

// MARK: - Reading relationships

// snippet.get-relationships
// Retrieve a page of relationships of your own class
pubnub.dataSync.getRelationships(relationshipClass: "enrollment", limit: 20) { result in
  switch result {
  case let .success((relationships, next)):
    print("The relationships: \(relationships)")
    print("The next page used for pagination: \(String(describing: next))")
  case let .failure(error):
    print("Get relationships request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-relationships-by-side
// Retrieve the relationships whose side A is a specific entity
pubnub.dataSync.getRelationships(
  relationshipClass: "enrollment",
  entityAId: "student-alice",
  limit: 20
) { result in
  switch result {
  case let .success((relationships, _)):
    print("The courses `student-alice` enrolled in: \(relationships.map { $0.entityBId })")
  case let .failure(error):
    print("Get relationships request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-relationship
// Retrieve a single relationship by identifier, and decode its payload into your own type
pubnub.dataSync.getRelationship("alice-course-swift-basics") { result in
  switch result {
  case let .success(relationship):
    print("The relationship for `\(relationship.id)`: \(relationship)")
    print("It connects `\(relationship.entityAId)` and `\(relationship.entityBId)`")
    print("Its eTag, used for optimistic concurrency: \(relationship.eTag)")

    do {
      if let details = try relationship.payload?.decode(EnrollmentDetails.self) {
        print("The \(details.role) completed \(details.completedLessons) lessons")
        print("The enrollment is active: \(details.isActive)")
        print("Their grade: \(details.grade ?? "not graded yet")")
      } else {
        print("The relationship has no stored payload")
      }
    } catch {
      print("The payload isn't a \(EnrollmentDetails.self): \(error)")
    }
  case let .failure(error):
    print("Get relationship request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// MARK: - Writing relationships

// snippet.create-relationship
// Connect two entities with a relationship of your own class
pubnub.dataSync.createRelationship(
  relationshipClass: "enrollment",
  entityAId: "student-alice",
  entityBId: "course-swift-basics",
  relationshipClassVersion: 1,
  id: "alice-course-swift-basics",
  status: "active",
  payload: EnrollmentDetails(
    role: "student",
    completedLessons: 0,
    isActive: true,
    grade: nil
  )
) { result in
  switch result {
  case let .success(relationship):
    print("The created relationship: \(relationship)")
  case let .failure(error):
    print("Create relationship request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.set-relationship
// Set a relationship's payload wholesale, only if it hasn't changed since it was read.
// Every field to keep has to be sent back: an omitted field is cleared, not preserved
pubnub.dataSync.setRelationship(
  "alice-course-swift-basics",
  relationshipClassVersion: 1,
  status: "active",
  payload: EnrollmentDetails(
    role: "student",
    completedLessons: 12,
    isActive: true,
    grade: "A"
  ),
  ifMatchesEtag: "3w5e111uk7djz"
) { result in
  switch result {
  case let .success(relationship):
    print("The set relationship: \(relationship)")
  case let .failure(error):
    print("Set relationship request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.update-relationship
// Change part of a relationship, leaving the rest of its payload untouched
pubnub.dataSync.updateRelationship(
  "alice-course-swift-basics",
  operations: [
    .replace(path: "/payload/completedLessons", value: 24),
    .replace(path: "/payload/isActive", value: false),
    .remove(path: "/payload/grade")
  ]
) { result in
  switch result {
  case let .success(relationship):
    print("The updated relationship: \(relationship)")
  case let .failure(error):
    print("Update relationship request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-relationship
// Remove a relationship
pubnub.dataSync.removeRelationship("alice-course-swift-basics") { result in
  switch result {
  case .success:
    print("The relationship was removed")
  case let .failure(error):
    print("Remove relationship request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end
