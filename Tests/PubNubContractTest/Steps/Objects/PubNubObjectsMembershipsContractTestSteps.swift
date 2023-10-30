//
//  PubNubObjectsMembershipsContractTestSteps.swift
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

public class PubNubObjectsMembershipsContractTestSteps: PubNubObjectsContractTests {
  override public func setup() {
    startCucumberHookEventsListening()

    When("^I get the memberships(.*)$") { args, _ in
      let fetchUUIDMembershipsExpect = self.expectation(description: "Fetch UUID memberships response")
      var include: PubNub.MembershipInclude = .init()

      if args?.count == 1, let flags = args?.first {
        include = .init(
          customFields: flags.contains("including custom"),
          channelCustomFields: flags.contains("channel custom information")
        )
      }

      let uuidMetadata = self.uuidsMetadata.compactMap { $1 }.first
      guard let uuidMetadataId = uuidMetadata?.metadataId else {
        XCTAssert(false, "UUID metadata ID unknown.")
        return
      }

      self.client.fetchMemberships(uuid: uuidMetadataId, include: include) { result in
        switch result {
        case let .success(membership):
          self.handleResult(result: membership)
        case let .failure(error):
          self.handleResult(result: error)
        }

        fetchUUIDMembershipsExpect.fulfill()
      }

      self.wait(for: [fetchUUIDMembershipsExpect], timeout: 60.0)

      guard let result = self.lastResult() as? (memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?) else { return }
      XCTAssertNotNil(result.memberships, "Membership information is missing")
      XCTAssertGreaterThan(result.memberships.count, 0)

      if include.customFields {
        XCTAssertTrue(
          result.memberships.contains(where: { $0.custom != nil }),
          "At least one membership should has custom information."
        )
      }

      if include.channelCustomFields {
        XCTAssertTrue(
          result.memberships.contains(where: { $0.channel?.custom != nil }),
          "At least one membership should contain channel custom information."
        )
      }
    }

    When("^I set the membership(.*)$") { args, _ in
      let setUUIDMembershipExpect = self.expectation(description: "Set UUID membership response")
      var useCurrentUser = false

      if args?.count == 1, let flags = args?.first {
        useCurrentUser = flags.contains("current user")
      }

      let addedChannelMemberships = self.membershipsMetadata.compactMap {
        if case let .add(channel) = $1 { return channel } else { return nil }
      }

      let uuidMetadata = self.uuidsMetadata.compactMap { $1 }.last
      guard let uuidMetadataId = uuidMetadata?.metadataId else { return }
      guard let channelMembership = addedChannelMemberships.last else {
        XCTAssert(false, "There is no new members for addition specified.")
        return
      }

      self.client.setMemberships(uuid: useCurrentUser ? nil : uuidMetadataId, channels: [channelMembership]) { result in
        switch result {
        case let .success(membership):
          self.handleResult(result: membership)
        case let .failure(error):
          self.handleResult(result: error)
        }

        setUUIDMembershipExpect.fulfill()
      }

      self.wait(for: [setUUIDMembershipExpect], timeout: 60.0)

      guard let result = self.lastResult() as? (memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?) else { return }
      XCTAssertNotNil(result.memberships, "Membership information is missing")
      XCTAssertGreaterThan(result.memberships.count, 0)
    }

    When("^I remove the membership(.*)$") { args, _ in
      let removeUUIDMembershipsExpect = self.expectation(description: "Remove UUID memberships response")
      var useCurrentUser = false

      if args?.count == 1, let flags = args?.first {
        useCurrentUser = flags.contains("current user")
      }

      let removedChannelMemberships = self.membershipsMetadata.compactMap {
        if case let .remove(channel) = $1 { return channel } else { return nil }
      }

      let uuidMetadata = self.uuidsMetadata.compactMap { $1 }.last
      guard let uuidMetadataId = uuidMetadata?.metadataId else { return }

      self.client.removeMemberships(
        uuid: useCurrentUser ? nil : uuidMetadataId,
        channels: removedChannelMemberships
      ) { result in
        switch result {
        case let .success(membership):
          self.handleResult(result: membership)
        case let .failure(error):
          self.handleResult(result: error)
        }

        removeUUIDMembershipsExpect.fulfill()
      }

      self.wait(for: [removeUUIDMembershipsExpect], timeout: 60.0)

      guard let result = self.lastResult() as? (memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?) else { return }
      XCTAssertNotNil(result.memberships, "Membership information is missing")
      XCTAssertEqual(result.memberships.count, 0)
    }

    When("I manage memberships") { _, _ in
      let manageUUIDMembershipsExpect = self.expectation(description: "Manage UUID memberships response")

      let addedChannelMemberships = self.membershipsMetadata.compactMap {
        if case let .add(membership) = $1 { return membership } else { return nil }
      }

      let removedChannelMemberships = self.membershipsMetadata.compactMap {
        if case let .remove(membership) = $1 { return membership } else { return nil }
      }

      let uuidMetadata = self.uuidsMetadata.compactMap { $1 }.last
      guard let uuidMetadataId = uuidMetadata?.metadataId else { return }

      self.client.manageMemberships(
        uuid: uuidMetadataId,
        setting: addedChannelMemberships,
        removing: removedChannelMemberships
      ) { result in
        switch result {
        case let .success(membership):
          self.handleResult(result: membership)
        case let .failure(error):
          self.handleResult(result: error)
        }

        manageUUIDMembershipsExpect.fulfill()
      }

      self.wait(for: [manageUUIDMembershipsExpect], timeout: 60.0)

      guard let result = self.lastResult() as? (memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?) else { return }
      XCTAssertNotNil(result.memberships, "Membership information is missing")
      XCTAssertEqual(result.memberships.count, 1)
    }
  }
}
