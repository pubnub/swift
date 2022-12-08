//
//  PubNubObjectsMembersContractTestSteps.swift
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

public class PubNubObjectsMembersContractTestSteps: PubNubObjectsContractTests {
  override public func setup() {
    startCucumberHookEventsListening()

    When("^I get the channel members(.*)$") { args, _ in
      let fetchChannelMembersExpect = self.expectation(description: "Fetch channel members response")
      var includeMembersCustoms = false
      var includeUUIDCustom = false

      if args?.count == 1, let flags = args?.first {
        includeMembersCustoms = flags.contains("including custom")
        includeUUIDCustom = flags.contains("UUID custom information") || flags.contains("UUID with custom")
      }

      let channelMetadata = self.channelsMetadata.compactMap { $1 }.last
      guard let channelMetadataId = channelMetadata?.metadataId else { return }

      self.client.fetchMembers(
        channel: channelMetadataId,
        include: PubNub.MemberInclude(
          customFields: includeMembersCustoms,
          uuidCustomFields: includeUUIDCustom
        )
      ) { result in
        switch result {
        case let .success(membership):
          self.handleResult(result: membership)
        case let .failure(error):
          self.handleResult(result: error)
        }

        fetchChannelMembersExpect.fulfill()
      }

      self.wait(for: [fetchChannelMembersExpect], timeout: 60.0)

      guard let result = self.lastResult() as? (memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?) else { return }
      XCTAssertNotNil(result.memberships, "Membership information is missing")
      XCTAssertGreaterThan(result.memberships.count, 0)

      if includeMembersCustoms {
        XCTAssertTrue(
          result.memberships.contains(where: { $0.custom != nil }),
          "At least one membership should contain custom information."
        )
      }

      if includeUUIDCustom {
        XCTAssertTrue(
          result.memberships.contains(where: { $0.uuid?.custom != nil }),
          "At least one membership should contain UUIDs custom information."
        )
      }
    }

    When("^I set a channel member(.*)$") { args, _ in
      let setChannelMembersExpect = self.expectation(description: "Set channel members response")
      var include: PubNub.MemberInclude = .init()

      if args?.count == 1, let flags = args?.first {
        include = .init(
          customFields: flags.contains("including custom"),
          uuidCustomFields: flags.contains("UUID with custom")
        )
      }

      let addedMembers = self.membershipsMetadata.compactMap {
        if case let .add(member) = $1 { return member } else { return nil }
      }

      let channelMetadata = self.channelsMetadata.compactMap { $1 }.last
      guard let channelMetadataId = channelMetadata?.metadataId else { return }
      guard let memberMetadata = addedMembers.last else {
        XCTAssert(false, "There is no new members for addition specified.")
        return
      }

      self.client.setMembers(channel: channelMetadataId, uuids: [memberMetadata], include: include) { result in
        switch result {
        case let .success(membership):
          self.handleResult(result: membership)
        case let .failure(error):
          self.handleResult(result: error)
        }

        setChannelMembersExpect.fulfill()
      }

      self.wait(for: [setChannelMembersExpect], timeout: 60.0)

      guard let result = self.lastResult() as? (memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?) else { return }
      XCTAssertNotNil(result.memberships, "Membership information is missing")
      XCTAssertGreaterThan(result.memberships.count, 0)

      if include.customFields {
        result.memberships.forEach { XCTAssertNotNil($0.custom) }
      }

      if include.uuidCustomFields {
        result.memberships.forEach { XCTAssertNotNil($0.uuid?.custom) }
      }
    }

    When("I remove a channel member") { _, _ in
      let removeChannelMembersExpect = self.expectation(description: "Remove channel members response")

      let removedMembers = self.membershipsMetadata.compactMap {
        if case let .remove(member) = $1 { return member } else { return nil }
      }

      let channelMetadata = self.channelsMetadata.compactMap { $1 }.last
      guard let channelMetadataId = channelMetadata?.metadataId else { return }
      guard let memberMetadata = removedMembers.last else {
        XCTAssert(false, "There is no existing members for removal specified.")
        return
      }

      self.client.removeMembers(channel: channelMetadataId, uuids: [memberMetadata]) { result in
        switch result {
        case let .success(membership):
          self.handleResult(result: membership)
        case let .failure(error):
          self.handleResult(result: error)
        }

        removeChannelMembersExpect.fulfill()
      }

      self.wait(for: [removeChannelMembersExpect], timeout: 60.0)

      guard let result = self.lastResult() as? (memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?) else { return }
      XCTAssertNotNil(result.memberships, "Membership information is missing")
      XCTAssertEqual(result.memberships.count, 0)
    }

    When("I manage channel members") { _, _ in
      let manageChannelMembersExpect = self.expectation(description: "Manage channel members response")

      let addedMembers = self.membershipsMetadata.compactMap {
        if case let .add(member) = $1 { return member } else { return nil }
      }

      let removedMembers = self.membershipsMetadata.compactMap {
        if case let .remove(member) = $1 { return member } else { return nil }
      }

      let channelMetadata = self.channelsMetadata.compactMap { $1 }.last
      guard let channelMetadataId = channelMetadata?.metadataId else { return }

      self.client.manageMembers(channel: channelMetadataId, setting: addedMembers, removing: removedMembers) { result in
        switch result {
        case let .success(membership):
          self.handleResult(result: membership)
        case let .failure(error):
          self.handleResult(result: error)
        }

        manageChannelMembersExpect.fulfill()
      }

      self.wait(for: [manageChannelMembersExpect], timeout: 60.0)
      guard let result = self.lastResult() as? (memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?) else { return }
      XCTAssertNotNil(result.memberships, "Membership information is missing")
      XCTAssertEqual(result.memberships.count, 1)
    }
  }
}
