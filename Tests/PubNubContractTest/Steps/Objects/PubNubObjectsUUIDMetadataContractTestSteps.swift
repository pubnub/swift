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
import PubNubSDK
import XCTest

public class PubNubObjectsUUIDMetadataContractTestSteps: PubNubObjectsContractTests {
  override public func setup() {
    startCucumberHookEventsListening()

    When("^I get the UUID metadata(.*)$") { args, _ in
      let fetchUserMetadataExpect = self.expectation(description: "Fetch UUID metadata response")
      var includeCustom = false

      let uuidMetadata = self.uuidsMetadata.compactMap { $1 }.first
      guard let uuidMetadataId = uuidMetadata?.metadataId else {
        XCTAssert(false, "UUID metadata ID unknown.")
        return
      }

      if args?.count == 1, let flags = args?.first {
        includeCustom = flags.contains("with custom")
      }

      self.client.fetchUserMetadata(
        self.setUserIdAsCurrentUser ? nil : uuidMetadataId,
        include: PubNub.IncludeFields(custom: true)
      ) { result in
        switch result {
        case let .success(metadata):
          self.handleResult(result: metadata)
        case let .failure(error):
          self.handleResult(result: error)
        }

        fetchUserMetadataExpect.fulfill()
      }

      self.wait(for: [fetchUserMetadataExpect], timeout: 60.0)

      let result = self.lastResult() as? PubNubUserMetadata
      XCTAssertNotNil(result, "Fetch UUID metadata didn't returned any response or it had unexpected format")

      if includeCustom {
        XCTAssertNotNil(result?.custom)
      }
    }

    When("I set the UUID metadata") { _, _ in
      let setUserMetadataExpect = self.expectation(description: "Set UUID metadata response")
      let uuidMetadata = self.uuidsMetadata.compactMap { $1 }.first

      self.client.setUserMetadata(uuidMetadata!) { result in
        switch result {
        case let .success(metadata):
          self.handleResult(result: metadata)
        case let .failure(error):
          self.handleResult(result: error)
        }
        setUserMetadataExpect.fulfill()
      }

      self.wait(for: [setUserMetadataExpect], timeout: 60.0)

      let result = self.lastResult() as? PubNubUserMetadata
      XCTAssertNotNil(result, "Set UUID metadata didn't returned any response or it had unexpected format")
    }

    When("^I remove the UUID metadata(.*)$") { args, _ in
      let userMetadata = self.uuidsMetadata.compactMap { $1 }.first
      var metadataId = userMetadata?.metadataId

      if args?.count == 1, let flags = args?.first, flags.contains("current user") {
        metadataId = nil
      }

      let removeUserMetadataExpect = self.expectation(description: "Remove UUID metadata response")

      self.client.removeUserMetadata(metadataId) { result in
        switch result {
        case let .success(removedUUID):
          self.handleResult(result: removedUUID)
        case let .failure(error):
          self.handleResult(result: error)
        }

        removeUserMetadataExpect.fulfill()
      }

      self.wait(for: [removeUserMetadataExpect], timeout: 60.0)

      let result = self.lastResult() as? String
      XCTAssertNotNil(result, "Remove UUID metadata didn't returned any response or it had unexpected format")
      XCTAssertEqual(result, userMetadata?.metadataId)
    }

    When("^I get all UUID metadata(.*)$") { args, _ in
      let fetchAllUserMetadataExpect = self.expectation(description: "Fetch all UUID metadata response")
      var includeCustom = PubNub.IncludeFields(custom: false, totalCount: false)

      if args?.count == 1, let flags = args?.first {
        includeCustom = PubNub.IncludeFields(custom: flags.contains("with custom"), totalCount: false)
      }

      self.client.allUserMetadata(include: PubNub.IncludeFields(custom: true)) { result in
        switch result {
        case let .success(metadata):
          for uuidMetadata in metadata.users {
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

        fetchAllUserMetadataExpect.fulfill()
      }

      self.wait(for: [fetchAllUserMetadataExpect], timeout: 60.0)
    }

    Match(["And"], "^the UUID metadata for '(.*)' persona(.*)$") { args, _ in
      guard let result = self.lastResult() as? PubNubUserMetadata else { return }
      guard let userName = args?.first?.lowercased() else { return }
      guard let userMetadata = self.uuidMetadata(with: userName) else { return }

      XCTAssertEqual(result.metadataId, userMetadata.metadataId)
      XCTAssertEqual(result.name, userMetadata.name)
      XCTAssertEqual(result.type, userMetadata.type)
      XCTAssertEqual(result.status, userMetadata.status)
      XCTAssertEqual(result.externalId, userMetadata.externalId)
      XCTAssertEqual(result.profileURL, userMetadata.profileURL)
      XCTAssertEqual(result.email, userMetadata.email)
      XCTAssertEqual(result.updated, userMetadata.updated)
      XCTAssertEqual(result.eTag, userMetadata.eTag)

      if args?.count == 2, let flags = args?.last, flags.contains("contains updated") {
        XCTAssertNotNil(result.updated)
      }
    }

    Match(["And"], "^the response contains list with '(.*)' and '(.*)' UUID metadata$") { _, _ in
      
    }
  }
}
