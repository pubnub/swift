//
//  data-sync-entities.swift
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

// snippet.entity-payload
// The fields stored on a `course` entity, as a type the SDK can encode into a request and decode from a response
struct CourseDetails: JSONCodable {
  let title: String
  let lessonCount: Int
  let isPublished: Bool
  let summary: String?
}

// snippet.end

// MARK: - Reading entities

// snippet.get-entities
// Retrieve a page of entities of your own class
pubnub.dataSync.getEntities(entityClass: "course", limit: 20) { result in
  switch result {
  case let .success((entities, next)):
    print("The entities: \(entities)")
    print("The next page used for pagination: \(String(describing: next))")
  case let .failure(error):
    print("Get entities request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-entities-class-version
// Restrict results to a single version of the class, resolved at a specific level
pubnub.dataSync.getEntities(
  entityClass: "course",
  entityClassVersion: 1,
  entityClassLevel: .subKey,
  limit: 20
) { result in
  switch result {
  case let .success((entities, _)):
    print("The entities of version 1: \(entities)")
  case let .failure(error):
    print("Get entities request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-entity
// Retrieve a single entity by identifier, and decode its payload into your own type
pubnub.dataSync.getEntity("course-swift-basics") { result in
  switch result {
  case let .success(entity):
    print("The entity for `\(entity.id)`: \(entity)")
    print("It belongs to class `\(entity.className)` at level \(entity.classLevel.stringValue)")
    print("Its eTag, used for optimistic concurrency: \(entity.eTag)")

    do {
      if let details = try entity.payload?.decode(CourseDetails.self) {
        print("\(details.title) has \(details.lessonCount) lessons")
        print("It is published: \(details.isPublished)")
        print("Its summary: \(details.summary ?? "not written yet")")
      } else {
        print("The entity has no stored payload")
      }
    } catch {
      print("The payload isn't a \(CourseDetails.self): \(error)")
    }
  case let .failure(error):
    print("Get entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// MARK: - Writing entities

// snippet.create-entity
// Create an entity of your own class
pubnub.dataSync.createEntity(
  entityClass: "course",
  entityClassVersion: 1,
  id: "course-swift-basics",
  status: "draft",
  payload: CourseDetails(
    title: "Swift Basics",
    lessonCount: 24,
    isPublished: false,
    summary: nil
  )
) { result in
  switch result {
  case let .success(entity):
    print("The created entity: \(entity)")
  case let .failure(error):
    print("Create entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.set-entity
// Set an entity's payload wholesale, only if it hasn't changed since it was read.
// Every field to keep has to be sent back: an omitted field is cleared, not preserved
pubnub.dataSync.setEntity(
  "course-swift-basics",
  entityClassVersion: 1,
  status: "published",
  payload: CourseDetails(
    title: "Swift Basics",
    lessonCount: 30,
    isPublished: true,
    summary: "An introduction to Swift for new developers"
  ),
  ifMatchesEtag: "3w5e111uk7djz"
) { result in
  switch result {
  case let .success(entity):
    print("The set entity: \(entity)")
  case let .failure(error):
    print("Set entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.update-entity
// Change part of an entity, leaving the rest of its payload untouched
pubnub.dataSync.updateEntity(
  "course-swift-basics",
  operations: [
    .replace(path: "/payload/title", value: "Swift Basics (2026)"),
    .replace(path: "/payload/lessonCount", value: 32),
    .replace(path: "/payload/isPublished", value: true),
    .remove(path: "/payload/summary")
  ]
) { result in
  switch result {
  case let .success(entity):
    print("The updated entity: \(entity)")
  case let .failure(error):
    print("Update entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-entity
// Remove an entity
pubnub.dataSync.removeEntity("course-swift-basics") { result in
  switch result {
  case .success:
    print("The entity was removed")
  case let .failure(error):
    print("Remove entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end
