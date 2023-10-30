//
//  PubNubObjectsContractTests.swift
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

@objc public class PubNubObjectsContractTests: PubNubContractTestCase {
  public static var membershipMetadata: [String: PubNubTestMembershipForAction?] = [:]
  public static var channelsMetadata: [String: PubNubChannelMetadata?] = [:]
  public static var uuidsMetadata: [String: PubNubUUIDMetadata?] = [:]
  private static var _setUserIdAsCurrentUser: Bool = false

  public var membershipsMetadata: [String: PubNubTestMembershipForAction?] {
    get { Self.membershipMetadata }
    set { Self.membershipMetadata = newValue }
  }

  public var channelsMetadata: [String: PubNubChannelMetadata?] {
    get { Self.channelsMetadata }
    set { Self.channelsMetadata = newValue }
  }

  public var uuidsMetadata: [String: PubNubUUIDMetadata?] {
    get { Self.uuidsMetadata }
    set { Self.uuidsMetadata = newValue }
  }

  public var setUserIdAsCurrentUser: Bool {
    get { Self._setUserIdAsCurrentUser }
    set { Self._setUserIdAsCurrentUser = newValue }
  }

  override public var configuration: PubNubConfiguration {
    let uuidMetadata = self.uuidsMetadata.compactMap { $1 }.first
    var config = super.configuration

    if setUserIdAsCurrentUser, let metadataId = uuidMetadata?.metadataId {
      config.userId = metadataId
    }

    return config
  }

  override public func handleBeforeHook() {
    membershipsMetadata = [:]
    channelsMetadata = [:]
    uuidsMetadata = [:]
  }

  override public func setup() {
    startCucumberHookEventsListening()

    Given("I have a keyset with Objects V2 enabled") { _, _ in
      // Do noting, because client doesn't support token grant.
    }

    Given("^current user is '(.*)' persona$") { args, _ in
      guard args?.count == 1, let personaName = args?.first?.lowercased() else {
        XCTAssert(false, "UUID not specified.")
        return
      }

      guard let uuidMetadata = self.uuidMetadata(with: personaName) else {
        XCTAssert(false, "Persona file not parsed.")
        return
      }

      Self._setUserIdAsCurrentUser = true
      self.uuidsMetadata[uuidMetadata.metadataId] = uuidMetadata
    }

    Match(["Given", "And"], "^the (.*) for '(.*)' channel$") { args, _ in
      guard args?.count == 2 else {
        XCTAssert(false, "Not all arguments specified in step.")
        return
      }

      guard let usedDataType = args?.first?.lowercased() else {
        XCTAssert(false, "Not specified type of object used in test.")
        return
      }

      guard let channelName = args?.last?.lowercased() else {
        XCTAssert(false, "Channel name not specified.")
        return
      }

      guard let channelMetadata = self.channelMetadata(with: channelName) else {
        XCTAssert(false, "Channel file not parsed.")
        return
      }

      XCTAssertNotNil(channelMetadata.metadataId)
      if usedDataType == "id" {
        self.channelsMetadata[channelMetadata.metadataId] = PubNubChannelMetadataBase(metadataId: channelMetadata.metadataId)
      } else {
        self.channelsMetadata[channelMetadata.metadataId] = channelMetadata
      }
    }

    Match(["Given", "And"], "^the (.*) for '(.*)' persona$") { args, _ in
      guard args?.count == 2 else {
        XCTAssert(false, "Not all arguments specified in step.")
        return
      }

      guard let usedDataType = args?.first?.lowercased() else {
        XCTAssert(false, "Not specified type of object used in test.")
        return
      }

      guard let personaName = args?.last?.lowercased() else {
        XCTAssert(false, "UUID not specified.")
        return
      }

      guard let uuidMetadata = self.uuidMetadata(with: personaName) else {
        XCTAssert(false, "Persona file not parsed.")
        return
      }

      XCTAssertNotNil(uuidMetadata.metadataId)
      if usedDataType == "id" {
        self.uuidsMetadata[uuidMetadata.metadataId] = PubNubUUIDMetadataBase(metadataId: uuidMetadata.metadataId)
      } else {
        self.uuidsMetadata[uuidMetadata.metadataId] = uuidMetadata
      }
    }

    Match(["Given", "And"], "^the data for '(.*)' (member|membership)(.*)$") { args, _ in
      let stepMatchArguments = (args ?? []).filter { $0.count > 0 }
      var toRemove = false

      if stepMatchArguments.count == 3, let flags = args?.last {
        toRemove = flags.contains("to remove")
      }

      guard stepMatchArguments.count >= 1, let memberName = stepMatchArguments.first?.lowercased() else {
        XCTAssert(false, "Member name not specified.")
        return
      }

      guard let memberMetadata = self.membership(with: memberName, for: "test-id") else {
        XCTAssert(false, "Member file not parsed.")
        return
      }

      self.membershipsMetadata[memberMetadata.uuidMetadataId] = toRemove ? .remove(memberMetadata) : .add(memberMetadata)
    }

    /// Hook for member and membership test steps (2 steps).
    Match(["And"], "^the response contains list with '(.*)' and '(.*)' (members|memberships)$") { args, _ in
      let stepMatchArguments = (args ?? []).filter { $0.count > 0 }

      let result = self.lastResult() as? (memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?)
      XCTAssertNotNil(result, "Fetch all channel metadata didn't returned any response or it had unexpected format")
      guard let receivedMemberships = result?.memberships else { return }
      let isMembershipForMembers = stepMatchArguments.last == "members"
      var metadataId: String?

      XCTAssertGreaterThanOrEqual(stepMatchArguments.count, 2, "Not all membership names specified")
      XCTAssertEqual(receivedMemberships.count, 2)

      if isMembershipForMembers {
        metadataId = self.channelsMetadata.compactMap { $1 }.last?.metadataId
      } else {
        metadataId = self.uuidsMetadata.compactMap { $1 }.last?.metadataId
      }

      var memberships: [PubNubMembershipMetadata] = []
      for membershipName in Array(stepMatchArguments[..<2]) {
        guard let membershipMetadata = self.membership(with: membershipName.lowercased(), for: metadataId!) else {
          XCTAssert(false, "Memberships file not parsed.")
          return
        }

        memberships.append(membershipMetadata)
      }

      let checkedId: (PubNubMembershipMetadata) -> String = { metadata in
        isMembershipForMembers ? metadata.uuidMetadataId : metadata.channelMetadataId
      }

      for membershipMetadata in memberships {
        XCTAssert(
          receivedMemberships.map { checkedId($0) }.contains(checkedId(membershipMetadata)),
          "\(membershipMetadata.uuidMetadataId) is missing from received memberships list."
        )
      }
    }

    /// Hook for member and membership test steps (4 steps).
    Match(["And"], "^the response (.*)contains? list with '(.*)' (member|membership)$") { args, _ in
      let stepMatchArguments = (args ?? []).filter { $0.count > 0 }
      let checkNotIncludeMember = stepMatchArguments.first?.contains("does not") ?? false

      let result = self.lastResult() as? (memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?)
      XCTAssertNotNil(result, "Fetch all channel metadata didn't returned any response or it had unexpected format")
      guard let receivedMemberships = result?.memberships else { return }
      let isMembershipForMembers = stepMatchArguments.last == "member"
      var metadataId: String?

      XCTAssertEqual(stepMatchArguments.count, checkNotIncludeMember ? 3 : 2, "Not all member names specified")
      XCTAssertEqual(receivedMemberships.count, 1)

      if isMembershipForMembers {
        metadataId = self.channelsMetadata.compactMap { $1 }.last?.metadataId
      } else {
        metadataId = self.uuidsMetadata.compactMap { $1 }.last?.metadataId
      }

      guard let membershipName = stepMatchArguments.count == 2 ? stepMatchArguments.first : stepMatchArguments[1] else {
        XCTAssert(false, "Unable to get membership file name from step")
        return
      }

      guard let stepMembershipMetadata = self.membership(with: membershipName.lowercased(), for: metadataId!) else {
        XCTAssert(false, "Memberships file not parsed.")
        return
      }

      let checkedId: (PubNubMembershipMetadata) -> String = { metadata in
        isMembershipForMembers ? metadata.uuidMetadataId : metadata.channelMetadataId
      }

      for membershipMetadata in [stepMembershipMetadata] {
        let contains = receivedMemberships.map { checkedId($0) }.contains(checkedId(membershipMetadata))

        XCTAssert(
          (contains && !checkNotIncludeMember) || (!contains && checkNotIncludeMember),
          "\(membershipMetadata.uuidMetadataId) \(!checkNotIncludeMember ? "is missing from" : "is present in")  received members list."
        )
      }
    }
  }
}
