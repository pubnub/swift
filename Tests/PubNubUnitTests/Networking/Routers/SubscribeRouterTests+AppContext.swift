//
//  SubscribeRouterTests+AppContext.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

// MARK: - User Object Response

extension SubscribeRouterTests {
  func test_Subscribe_WithUUIDMetadataSetEvent_ReceivesMetadataChangeset() throws {
    let baseUser = PubNubUserMetadataBase(
      metadataId: "TestUserID",
      name: "Not Real Name"
    )
    let patchedUser = PubNubUserMetadataBase(
      metadataId: "TestUserID",
      name: "Test Name", type: "Test Type", status: "Test Status",
      updated: DateFormatter.iso8601.date(from: "2019-10-06T01:55:50.645685Z"),
      eTag: "UserUpdateEtag"
    )

    let event = try decodeEvent(from: "subscription_uuidSet_success")
    let changeset = try XCTUnwrap(event.userMetadataChangeset)

    XCTAssertEqual(try changeset.apply(to: baseUser).transcode(), patchedUser)
  }

  func test_Subscribe_WithUUIDMetadataRemovedEvent_ReceivesMetadataId() throws {
    let event = try decodeEvent(from: "subscription_uuidRemove_success")
    let metadataId = try XCTUnwrap(event.removedUserMetadataId)

    XCTAssertEqual(metadataId, "TestUserID")
  }

  func test_Subscribe_WithChannelMetadataSetEvent_ReceivesMetadataChangeset() throws {
    let baseChannel = PubNubChannelMetadataBase(
      metadataId: "TestSpaceID",
      name: "Not Real Name",
      type: "someType"
    )
    let patchedChannel = PubNubChannelMetadataBase(
      metadataId: "TestSpaceID", name: "Test Name",
      type: "Test Type", status: "Test Status",
      updated: DateFormatter.iso8601.date(from: "2019-10-06T01:55:50.645685Z"),
      eTag: "SpaceUpdateEtag"
    )

    let event = try decodeEvent(from: "subscription_channelSet_success")
    let changeset = try XCTUnwrap(event.channelMetadataChangeset)

    XCTAssertEqual(try changeset.apply(to: baseChannel).transcode(), patchedChannel)
  }

  func test_Subscribe_WithChannelMetadataRemovedEvent_ReceivesMetadataId() throws {
    let event = try decodeEvent(from: "subscription_channelRemove_success")
    let metadataId = try XCTUnwrap(event.removedChannelMetadataId)

    XCTAssertEqual(metadataId, "TestSpaceID")
  }

  func test_Subscribe_WithMembershipSetEvent_ReceivesMembership() throws {
    let expectedMembership = PubNubMembershipMetadataBase(
      userMetadataId: "TestUserID", channelMetadataId: "TestSpaceID",
      status: "Test Status",
      user: PubNubUserMetadataBase(metadataId: "TestUserID"),
      channel: PubNubChannelMetadataBase(metadataId: "TestSpaceID"),
      custom: ["something": true],
      updated: DateFormatter.iso8601.date(from: "2019-10-05T23:35:38.457823306Z"),
      eTag: "TestETag"
    )

    let event = try decodeEvent(from: "subscription_membershipSet_success")
    let membership = try XCTUnwrap(event.membershipSet)

    XCTAssertEqual(try membership.transcode(), expectedMembership)
  }

  func test_Subscribe_WithMembershipRemovedEvent_ReceivesMembership() throws {
    let expectedMembership = PubNubMembershipMetadataBase(
      userMetadataId: "TestUserID", channelMetadataId: "TestSpaceID",
      user: PubNubUserMetadataBase(metadataId: "TestUserID"),
      channel: PubNubChannelMetadataBase(metadataId: "TestSpaceID"),
      updated: DateFormatter.iso8601.date(from: "2019-10-05T23:35:38.457823306Z"), eTag: "TestETag"
    )

    let event = try decodeEvent(from: "subscription_membershipRemove_success")
    let membership = try XCTUnwrap(event.membershipRemoved)

    XCTAssertEqual(try membership.transcode(), expectedMembership)
  }
}

// MARK: Helpers

private extension PubNubEvent {

  var userMetadataChangeset: PubNubUserMetadataChangeset? {
    guard case let .appContextChanged(.userMetadataSet(c)) = self else { return nil }
    return c
  }

  var removedUserMetadataId: String? {
    guard case let .appContextChanged(.userMetadataRemoved(metadataId)) = self else { return nil }
    return metadataId
  }

  var channelMetadataChangeset: PubNubChannelMetadataChangeset? {
    guard case let .appContextChanged(.channelMetadataSet(c)) = self else { return nil }
    return c
  }

  var removedChannelMetadataId: String? {
    guard case let .appContextChanged(.channelMetadataRemoved(metadataId)) = self else { return nil }
    return metadataId
  }

  var membershipSet: PubNubMembershipMetadata? {
    guard case let .appContextChanged(.membershipMetadataSet(m)) = self else { return nil }
    return m
  }

  var membershipRemoved: PubNubMembershipMetadata? {
    guard case let .appContextChanged(.membershipMetadataRemoved(m)) = self else { return nil }
    return m
  }
}
