//
//  PubNubObjectsMembershipsContractTestSteps.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
