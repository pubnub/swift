//
//  ObjectsMembershipsRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class ObjectsMembershipsRouterTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString", userId: UUID().uuidString)
  let testChannel = PubNubChannelMetadataBase(name: "TestChannel")
  let testUser = PubNubUUIDMetadataBase(name: "TestUser")
}

// MARK: - Fetch Memberships Tests

extension ObjectsMembershipsRouterTests {
  func testMembershipFetch_Router() {
    let router = ObjectsMembershipsRouter(
      .fetchMemberships(uuidMetadataId: "TestUser", customFields: [], totalCount: false,
                        filter: nil, sort: [], limit: nil, start: nil, end: nil),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Fetch the Membership Metadata for a UUID")
    XCTAssertEqual(router.category, "Fetch the Membership Metadata for a UUID")
    XCTAssertEqual(router.service, .objects)
  }

  func testMembershipFetch_Router_ValidationError() {
    let router = ObjectsMembershipsRouter(
      .fetchMemberships(
        uuidMetadataId: "", customFields: [], totalCount: false,
        filter: nil, sort: [], limit: nil, start: nil, end: nil
      ),
      configuration: config
    )

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testMembershipFetch_Success() {
    let expectation = self.expectation(description: "Fetch Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_membership_success"]),
          let channeDate = DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z"),
          let firstDate = DateFormatter.iso8601.date(from: "2019-10-02T18:07:52.858703Z"),
          let lastDate = DateFormatter.iso8601.date(from: "2019-09-29T19:46:28.84402Z")
    else {
      return XCTFail("Could not create mock url session")
    }

    let firstChannel = PubNubChannelMetadataBase(
      metadataId: "FirstChannel", name: "First Channel",
      channelDescription: "Channel Description", updated: channeDate, eTag: "ChanneleTag"
    )

    let lastChannel = PubNubChannelMetadataBase(metadataId: "LastChannel")
    let firstMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: "TestUser", channelMetadataId: firstChannel.metadataId,
      channel: firstChannel,
      updated: firstDate, eTag: "FirstETag"
    )
    let lastMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: "TestUser", channelMetadataId: "LastChannel",
      channel: lastChannel,
      updated: lastDate, eTag: "LastETag"
    )

    let page = PubNubHashedPageBase(start: "NextPage", totalCount: 2)

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.fetchMemberships(uuid: "TestUser") { result in
      switch result {
      case let .success((memberships, nextPage)):
        XCTAssertEqual(memberships.compactMap { try? $0.transcode() }, [firstMembership, lastMembership])
        XCTAssertEqual(try? nextPage?.transcode(), page)
      case let .failure(error):
        XCTFail("Fetch Memberships request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testMembershipFetch_Success_Empty() {
    let expectation = self.expectation(description: "Fetch Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_uuid_all_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    let testPage = PubNubHashedPageBase(start: "NextPage")

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.fetchMemberships(uuid: "TestUser") { result in
      switch result {
      case let .success((memberships, nextPage)):
        XCTAssertTrue(memberships.isEmpty)
        XCTAssertEqual(try? nextPage?.transcode(), testPage)

      case let .failure(error):
        XCTFail("Fetch Memberships request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Set Memberships Tests

extension ObjectsMembershipsRouterTests {
  func testMembershipSet_Router() {
    let router = ObjectsMembershipsRouter(
      .setMemberships(uuidMetadataId: "TestUUID", customFields: [], totalCount: true,
                      changes: .init(set: [], delete: []),
                      filter: "filter", sort: ["sort"], limit: 100, start: "Next", end: "last"),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Set the Membership Metadata for a UUID")
    XCTAssertEqual(router.category, "Set the Membership Metadata for a UUID")
    XCTAssertEqual(router.service, .objects)
  }

  func testMembershipSet_Router_ValidationError() {
    let router = ObjectsMembershipsRouter(
      .setMemberships(uuidMetadataId: "", customFields: [], totalCount: true,
                      changes: .init(set: [], delete: []),
                      filter: "filter", sort: ["sort"], limit: 100, start: "Next", end: "last"),
      configuration: config
    )

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testMembershipSet_Success() {
    let expectation = self.expectation(description: "Update Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_membership_success"]),
          let channeDate = DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z"),
          let firstDate = DateFormatter.iso8601.date(from: "2019-10-02T18:07:52.858703Z"),
          let lastDate = DateFormatter.iso8601.date(from: "2019-09-29T19:46:28.84402Z")
    else {
      return XCTFail("Could not create mock url session")
    }

    let firstChannel = PubNubChannelMetadataBase(
      metadataId: "FirstChannel", name: "First Channel",
      channelDescription: "Channel Description", updated: channeDate, eTag: "ChanneleTag"
    )
    let lastChannel = PubNubChannelMetadataBase(metadataId: "LastChannel")
    let firstMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: "TestUser", channelMetadataId: firstChannel.metadataId,
      channel: firstChannel,
      updated: firstDate, eTag: "FirstETag"
    )
    let lastMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: "TestUser", channelMetadataId: "LastChannel",
      channel: lastChannel,
      updated: lastDate, eTag: "LastETag"
    )

    let page = PubNubHashedPageBase(start: "NextPage", totalCount: 2)

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.setMemberships(uuid: "TestUser", channels: [firstMembership]) { result in
      switch result {
      case let .success((memberships, nextPage)):
        XCTAssertEqual(memberships.compactMap { try? $0.transcode() }, [firstMembership, lastMembership])
        XCTAssertEqual(try? nextPage?.transcode(), page)
      case let .failure(error):
        XCTFail("Fetch Memberships request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testMembershipRemove_Success() {
    let expectation = self.expectation(description: "Update Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_membership_success"]),
          let channeDate = DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z"),
          let firstDate = DateFormatter.iso8601.date(from: "2019-10-02T18:07:52.858703Z"),
          let lastDate = DateFormatter.iso8601.date(from: "2019-09-29T19:46:28.84402Z")
    else {
      return XCTFail("Could not create mock url session")
    }

    let firstChannel = PubNubChannelMetadataBase(
      metadataId: "FirstChannel", name: "First Channel",
      channelDescription: "Channel Description", updated: channeDate, eTag: "ChanneleTag"
    )
    let lastChannel = PubNubChannelMetadataBase(metadataId: "LastChannel")
    let firstMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: "TestUser", channelMetadataId: firstChannel.metadataId,
      channel: firstChannel,
      updated: firstDate, eTag: "FirstETag"
    )
    let lastMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: "TestUser", channelMetadataId: "LastChannel",
      channel: lastChannel,
      updated: lastDate, eTag: "LastETag"
    )

    let page = PubNubHashedPageBase(start: "NextPage", totalCount: 2)

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.removeMemberships(uuid: "TestUser", channels: [firstMembership]) { result in
      switch result {
      case let .success((memberships, nextPage)):
        XCTAssertEqual(memberships.compactMap { try? $0.transcode() }, [firstMembership, lastMembership])
        XCTAssertEqual(try? nextPage?.transcode(), page)
      case let .failure(error):
        XCTFail("Fetch Memberships request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Fetch Members Tests

extension ObjectsMembershipsRouterTests {
  func testFetchMembers_Router() {
    let router = ObjectsMembershipsRouter(
      .fetchMembers(channelMetadataId: "TestUser", customFields: [], totalCount: false,
                    filter: nil, sort: [], limit: nil, start: nil, end: nil),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Fetch the Membership Metadata of a Channel")
    XCTAssertEqual(router.category, "Fetch the Membership Metadata of a Channel")
    XCTAssertEqual(router.service, .objects)
  }

  func testFetchMembers_Router_ValidationError() {
    let router = ObjectsMembershipsRouter(
      .fetchMembers(channelMetadataId: "", customFields: [], totalCount: false,
                    filter: nil, sort: [], limit: nil, start: nil, end: nil),
      configuration: config
    )

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testFetchMember_Success() {
    let expectation = self.expectation(description: "Fetch Members Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_members_success"]),
          let uuidDate = DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z"),
          let firstDate = DateFormatter.iso8601.date(from: "2019-10-02T18:07:52.858703Z"),
          let lastDate = DateFormatter.iso8601.date(from: "2019-09-29T19:46:28.84402Z")
    else {
      return XCTFail("Could not create mock url session")
    }

    let firstUUID = PubNubUUIDMetadataBase(
      metadataId: "FirstUser", name: "First User", updated: uuidDate, eTag: "UserETag"
    )
    let lastUUID = PubNubUUIDMetadataBase(metadataId: "LastUser")

    let firstMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: firstUUID.metadataId, channelMetadataId: "TestChannel",
      status: "Test Status",
      uuid: firstUUID,
      updated: firstDate, eTag: "FirstETag"
    )
    let lastMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: "LastUser", channelMetadataId: "TestChannel",
      status: "Test Status",
      uuid: lastUUID,
      custom: ["starred": true],
      updated: lastDate, eTag: "LastETag"
    )

    let page = PubNubHashedPageBase(start: "NextPage", totalCount: 2)

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.fetchMembers(channel: "TestChannel") { result in
      switch result {
      case let .success((memberships, nextPage)):
        let membs1: [PubNubMembershipMetadataBase] = memberships.compactMap { try? $0.transcode() }
        let membs2 = [firstMembership, lastMembership]
        print("MEMBS 1: \(membs1)")
        print("MEMBS 2: \(membs2)")
        XCTAssertEqual(memberships.compactMap { try? $0.transcode() }, [firstMembership, lastMembership])
        XCTAssertEqual(try? nextPage?.transcode(), page)
      case let .failure(error):
        XCTFail("Fetch Memberships request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchMember_Success_Empty() {
    let expectation = self.expectation(description: "Fetch Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_uuid_all_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    let testPage = PubNubHashedPageBase(start: "NextPage")

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.fetchMembers(channel: "TestChannel") { result in
      switch result {
      case let .success((memberships, nextPage)):
        XCTAssertTrue(memberships.isEmpty)
        XCTAssertEqual(try? nextPage?.transcode(), testPage)

      case let .failure(error):
        XCTFail("Fetch Memberships request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Set Members Tests

extension ObjectsMembershipsRouterTests {
  func testMembersSet_Router() {
    let router = ObjectsMembershipsRouter(
      .setMembers(channelMetadataId: "TestUUID", customFields: [], totalCount: true,
                  changes: .init(set: [], delete: []),
                  filter: "filter", sort: ["sort"], limit: 100, start: "Next", end: "last"),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Set the Membership Metadata of a Channel")
    XCTAssertEqual(router.category, "Set the Membership Metadata of a Channel")
    XCTAssertEqual(router.service, .objects)
  }

  func testMembersSet_Router_ValidationError() {
    let router = ObjectsMembershipsRouter(
      .setMembers(channelMetadataId: "", customFields: [], totalCount: true,
                  changes: .init(set: [], delete: []),
                  filter: "filter", sort: ["sort"], limit: 100, start: "Next", end: "last"),
      configuration: config
    )

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testMember_Set_Success() {
    let expectation = self.expectation(description: "Set Members Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_members_success"]),
          let uuidDate = DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z"),
          let firstDate = DateFormatter.iso8601.date(from: "2019-10-02T18:07:52.858703Z"),
          let lastDate = DateFormatter.iso8601.date(from: "2019-09-29T19:46:28.84402Z")
    else {
      return XCTFail("Could not create mock url session")
    }

    let firstUUID = PubNubUUIDMetadataBase(
      metadataId: "FirstUser", name: "First User", updated: uuidDate, eTag: "UserETag"
    )
    let lastUUID = PubNubUUIDMetadataBase(metadataId: "LastUser")

    let firstMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: firstUUID.metadataId, channelMetadataId: "TestChannel",
      status: "Test Status",
      uuid: firstUUID,
      updated: firstDate, eTag: "FirstETag"
    )
    let lastMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: "LastUser", channelMetadataId: "TestChannel",
      status: "Test Status",
      uuid: lastUUID,
      custom: ["starred": true],
      updated: lastDate, eTag: "LastETag"
    )

    let page = PubNubHashedPageBase(start: "NextPage", totalCount: 2)

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.setMembers(channel: "TestChannel", uuids: [firstMembership]) { result in
      switch result {
      case let .success((memberships, nextPage)):
        XCTAssertEqual(memberships.compactMap { try? $0.transcode() }, [firstMembership, lastMembership])
        XCTAssertEqual(try? nextPage?.transcode(), page)
      case let .failure(error):
        XCTFail("Fetch Memberships request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testMember_Remove_Success() {
    let expectation = self.expectation(description: "Remove Members Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_members_success"]),
          let uuidDate = DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z"),
          let firstDate = DateFormatter.iso8601.date(from: "2019-10-02T18:07:52.858703Z"),
          let lastDate = DateFormatter.iso8601.date(from: "2019-09-29T19:46:28.84402Z")
    else {
      return XCTFail("Could not create mock url session")
    }

    let firstUUID = PubNubUUIDMetadataBase(
      metadataId: "FirstUser", name: "First User", updated: uuidDate, eTag: "UserETag"
    )
    let lastUUID = PubNubUUIDMetadataBase(metadataId: "LastUser")

    let firstMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: firstUUID.metadataId, channelMetadataId: "TestChannel",
      status: "Test Status",
      uuid: firstUUID,
      updated: firstDate, eTag: "FirstETag"
    )
    let lastMembership = PubNubMembershipMetadataBase(
      uuidMetadataId: "LastUser", channelMetadataId: "TestChannel",
      status: "Test Status",
      uuid: lastUUID,
      custom: ["starred": true],
      updated: lastDate, eTag: "LastETag"
    )

    let page = PubNubHashedPageBase(start: "NextPage", totalCount: 2)

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.setMembers(channel: "TestChannel", uuids: [firstMembership]) { result in
      switch result {
      case let .success((memberships, nextPage)):
        XCTAssertEqual(memberships.compactMap { try? $0.transcode() }, [firstMembership, lastMembership])
        XCTAssertEqual(try? nextPage?.transcode(), page)
      case let .failure(error):
        XCTFail("Fetch Memberships request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // swiftlint:disable:next file_length
}
