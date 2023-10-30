//
//  PubNubObjectsUUIDMetadataContractTestSteps.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Cucumberish
import Foundation
import PubNub
import XCTest

public class PubNubObjectsUUIDMetadataContractTestSteps: PubNubObjectsContractTests {
  override public func setup() {
    startCucumberHookEventsListening()

    When("^I get the UUID metadata(.*)$") { args, _ in
      let fetchUUIDMetadataExpect = self.expectation(description: "Fetch UUID metadata response")
      var includeCustom = false

      let uuidMetadata = self.uuidsMetadata.compactMap { $1 }.first
      guard let uuidMetadataId = uuidMetadata?.metadataId else {
        XCTAssert(false, "UUID metadata ID unknown.")
        return
      }

      if args?.count == 1, let flags = args?.first {
        includeCustom = flags.contains("with custom")
      }

      self.client.fetch(
        uuid: self.setUserIdAsCurrentUser ? nil : uuidMetadataId,
        include: includeCustom
      ) { result in
        switch result {
        case let .success(metadata):
          self.handleResult(result: metadata)
        case let .failure(error):
          self.handleResult(result: error)
        }

        fetchUUIDMetadataExpect.fulfill()
      }

      self.wait(for: [fetchUUIDMetadataExpect], timeout: 60.0)

      let result = self.lastResult() as? PubNubUUIDMetadata
      XCTAssertNotNil(result, "Fetch UUID metadata didn't returned any response or it had unexpected format")

      if includeCustom {
        XCTAssertNotNil(result?.custom)
      }
    }

    When("I set the UUID metadata") { _, _ in
      let setUUIDExpect = self.expectation(description: "Set UUID metadata response")
      let uuidMetadata = self.uuidsMetadata.compactMap { $1 }.first

      self.client.set(uuid: uuidMetadata!) { result in
        switch result {
        case let .success(metadata):
          self.handleResult(result: metadata)
        case let .failure(error):
          self.handleResult(result: error)
        }
        setUUIDExpect.fulfill()
      }

      self.wait(for: [setUUIDExpect], timeout: 60.0)

      let result = self.lastResult() as? PubNubUUIDMetadata
      XCTAssertNotNil(result, "Set UUID metadata didn't returned any response or it had unexpected format")
    }

    When("^I remove the UUID metadata(.*)$") { args, _ in
      let uuidMetadata = self.uuidsMetadata.compactMap { $1 }.first
      var metadataId = uuidMetadata?.metadataId

      if args?.count == 1, let flags = args?.first, flags.contains("current user") {
        metadataId = nil
      }

      let removeUUIDMetadataExpect = self.expectation(description: "Remove UUID metadata response")

      self.client.remove(uuid: metadataId) { result in
        switch result {
        case let .success(removedUUID):
          self.handleResult(result: removedUUID)
        case let .failure(error):
          self.handleResult(result: error)
        }

        removeUUIDMetadataExpect.fulfill()
      }

      self.wait(for: [removeUUIDMetadataExpect], timeout: 60.0)

      let result = self.lastResult() as? String
      XCTAssertNotNil(result, "Remove UUID metadata didn't returned any response or it had unexpected format")
      XCTAssertEqual(result, uuidMetadata?.metadataId)
    }

    When("^I get all UUID metadata(.*)$") { args, _ in
      let fetchAllUUIDMetadataExpect = self.expectation(description: "Fetch all UUID metadata response")
      var includeCustom = PubNub.IncludeFields(custom: false, totalCount: false)

      if args?.count == 1, let flags = args?.first {
        includeCustom = PubNub.IncludeFields(custom: flags.contains("with custom"), totalCount: false)
      }

      self.client.allUUIDMetadata(include: includeCustom) { result in
        switch result {
        case let .success(metadata):
          for uuidMetadata in metadata.uuids {
            XCTAssert(
              includeCustom.customFields && uuidMetadata.custom != nil
                || !includeCustom.customFields && uuidMetadata.custom == nil,
              "\(uuidMetadata.custom != nil ? "Missing" : "Unexpected") custom data for \(uuidMetadata.metadataId) persona."
            )
          }

          self.handleResult(result: metadata)
        case let .failure(error):
          self.handleResult(result: error)
        }

        fetchAllUUIDMetadataExpect.fulfill()
      }

      self.wait(for: [fetchAllUUIDMetadataExpect], timeout: 60.0)
    }

    Match(["And"], "^the UUID metadata for '(.*)' persona(.*)$") { args, _ in
      guard let result = self.lastResult() as? PubNubUUIDMetadata else { return }
      guard let uuidName = args?.first?.lowercased() else { return }
      guard let uuidMetadata = self.uuidMetadata(with: uuidName) else { return }

      XCTAssertEqual(result.metadataId, uuidMetadata.metadataId)
      XCTAssertEqual(result.name, uuidMetadata.name)
      XCTAssertEqual(result.type, uuidMetadata.type)
      XCTAssertEqual(result.status, uuidMetadata.status)
      XCTAssertEqual(result.externalId, uuidMetadata.externalId)
      XCTAssertEqual(result.profileURL, uuidMetadata.profileURL)
      XCTAssertEqual(result.email, uuidMetadata.email)
      XCTAssertEqual(result.updated, uuidMetadata.updated)
      XCTAssertEqual(result.eTag, uuidMetadata.eTag)

      if args?.count == 2, let flags = args?.last, flags.contains("contains updated") {
        XCTAssertNotNil(result.updated)
      }
    }

    Match(["And"], "^the response contains list with '(.*)' and '(.*)' UUID metadata$") { _, _ in
//      let result = self.lastResult() as? ((uuids:[PubNubUUIDMetadata], next: PubNubHashedPage))
//      XCTAssertNotNil(result, "Fetch all UUID metadata didn't returned any response or it had unexpected format")
//      guard let receivedUUIDs = result?.uuids else { return }
//
//      XCTAssertEqual(args?.count, 2, "Not all UUID names specified")
//      XCTAssertEqual(receivedUUIDs.count, 2)
//
//      var uuids: [PubNubUUIDMetadata] = []
//      for userName in args ?? [] {
//        guard let uuidMetadata = self.uuidMetadata(with: userName.lowercased()) else {
//          XCTAssert(false, "Persona file not parsed.")
//          return
//        }
//
//        uuids.append(uuidMetadata)
//      }
//
//      for uuidMetadata in uuids {
//        XCTAssert(receivedUUIDs.map { $0.metadataId }.contains(uuidMetadata.metadataId),
//                  "\(uuidMetadata.metadataId) is missing from received UUIDs list.")
//      }
    }
  }
}
