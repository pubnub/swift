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
pubnub.dataSync.getEntities(className: "course", limit: 20) { result in
  switch result {
  case let .success((entities, next)):
    print("The entities: \(entities)")
    print("The next page used for pagination: \(String(describing: next))")
  case let .failure(error):
    print("Get entities request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-entities-filter-fast
// Filter strongly consistent data, so a entity you just wrote is matched
pubnub.dataSync.getEntities(
  className: "course",
  limit: 20,
  filterFast: "isPublished == true && lessonCount > 20"
) { result in
  switch result {
  case let .success((entities, _)):
    print("The matching entities: \(entities)")
  case let .failure(error):
    print("Get entities request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-entities-filter
// Filter eventually consistent data with the full expression language
pubnub.dataSync.getEntities(
  className: "course",
  limit: 20,
  filter: "title LIKE \"*Swift*\""
) { result in
  switch result {
  case let .success((entities, _)):
    print("The matching entities: \(entities)")
  case let .failure(error):
    print("Get entities request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.get-entities-pagination
// Page through every entity, passing the cursor of each page into the next request
func fetchEntities(cursor: String? = nil) {
  pubnub.dataSync.getEntities(
    className: "course",
    cursor: cursor,
    limit: 20
  ) { result in
    switch result {
    case let .success((entities, next)):
      print("A page of entities: \(entities)")

      // Stop when the response has no next page
      if let next = next, next.hasNext {
        fetchEntities(cursor: next.cursor)
      }
    case let .failure(error):
      print("Get entities request failed with error: \(error.localizedDescription)")
    }
  }
}

fetchEntities()
// snippet.end

// snippet.get-entity
// Retrieve a single entity by identifier, and decode its payload into your own type
pubnub.dataSync.getEntity(id: "course-swift-basics") { result in
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
      print("Could not decode \(entity.className) version \(entity.classVersion) for entity \(entity.id): \(error)")
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
  className: "course",
  classVersion: 1,
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
// Replace every mutable field. Every field to keep must be sent back; an omitted field is cleared
pubnub.dataSync.setEntity(
  id: "course-swift-basics",
  classVersion: 1,
  status: "published",
  payload: CourseDetails(
    title: "Swift Basics",
    lessonCount: 30,
    isPublished: true,
    summary: "An introduction to Swift for new developers"
  ),
  ifMatchesEtag: "3w5e111uk7djz" // Always provide the eTag from the most recent response
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
// Change selected fields, leaving every unaddressed field untouched
pubnub.dataSync.updateEntity(
  id: "course-swift-basics",
  operations: [
    .replace(path: "/payload/title", value: "Swift Basics (2026)"),
    .replace(path: "/payload/lessonCount", value: 32),
    .replace(path: "/payload/isPublished", value: true),
    .remove(path: "/payload/summary")
  ],
  ifMatchesEtag: "3w5e111uk7djz" // Always provide the eTag from the most recent response
) { result in
  switch result {
  case let .success(entity):
    print("The updated entity: \(entity)")
  case let .failure(error):
    print("Update entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.update-entity-multiple-operations
// Combine several operations in one atomic patch, and guard the write with the eTag
pubnub.dataSync.updateEntity(
  id: "course-swift-basics",
  operations: [
    .test(path: "/status", value: "draft"),
    .replace(path: "/payload/lessonCount", value: 30),
    .add(path: "/payload/level", value: "beginner"),
    .copy(from: "/payload/title", path: "/payload/slug"),
    .move(from: "/payload/summary", path: "/payload/description"),
    .remove(path: "/payload/isPublished")
  ],
  ifMatchesEtag: "3w5e111uk7djz" // Always provide the eTag from the most recent response
) { result in
  switch result {
  case let .success(entity):
    print("The patched entity: \(entity)")
  case let .failure(error):
    print("Update entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-entity
// Remove an entity
pubnub.dataSync.removeEntity(
  id: "course-swift-basics",
  ifMatchesEtag: "3w5e111uk7djz" // Always provide the eTag from the most recent response
) { result in
  switch result {
  case .success:
    print("The entity was removed")
  case let .failure(error):
    print("Remove entity request failed with error: \(error.localizedDescription)")
  }
}
// snippet.end
