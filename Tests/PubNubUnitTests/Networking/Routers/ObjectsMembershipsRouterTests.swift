//
//  ObjectsMembershipsRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

final class ObjectsMembershipsRouterTests: XCTestCase {
  let config = TestPubNubFactory.makeConfig()
  let testChannel = PubNubChannelMetadataBase(name: "TestChannel")
  let testUser = PubNubUserMetadataBase(name: "TestUser")
}

// MARK: - Fetch Memberships Tests

extension ObjectsMembershipsRouterTests {
  func test_FetchMemberships_RouterConfiguration_ReturnsCorrectEndpoint() {
    let router = ObjectsMembershipsRouter(
      .fetchMemberships(
        uuidMetadataId: "TestUser", customFields: [],
        totalCount: false, filter: nil, sort: [], limit: nil, start: nil, end: nil
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Fetch the Membership Metadata for a UUID")
    XCTAssertEqual(router.category, "Fetch the Membership Metadata for a UUID")
    XCTAssertEqual(router.service, .objects)
  }

  func test_FetchMemberships_RouterValidationWithEmptyId_ReturnsNoEndpointTypeError() {
    let router = ObjectsMembershipsRouter(
      .fetchMemberships(
        uuidMetadataId: "", customFields: [], totalCount: false,
        filter: nil, sort: [], limit: nil, start: nil, end: nil
      ),
      configuration: config
    )

    XCTAssertNotEqual(
      router.validationError?.pubNubError,
      PubNubError(.invalidEndpointType, router: router)
    )
  }

  func test_FetchMemberships_WithValidConfig_ReturnsMemberships() throws {
    let expectation = self.expectation(description: "Fetch Memberships Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["objects_membership_success"])
    let channeDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z"))
    let firstDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-10-02T18:07:52.858703Z"))
    let lastDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-29T19:46:28.84402Z"))

    let firstChannel = PubNubChannelMetadataBase(
      metadataId: "FirstChannel", name: "First Channel",
      channelDescription: "Channel Description", updated: channeDate, eTag: "ChanneleTag"
    )
    let lastChannel = PubNubChannelMetadataBase(
      metadataId: "LastChannel"
    )
    let firstMembership = PubNubMembershipMetadataBase(
      userMetadataId: "TestUser", channelMetadataId: firstChannel.metadataId,
      channel: firstChannel,
      updated: firstDate, eTag: "FirstETag"
    )
    let lastMembership = PubNubMembershipMetadataBase(
      userMetadataId: "TestUser", channelMetadataId: "LastChannel",
      channel: lastChannel,
      updated: lastDate, eTag: "LastETag"
    )

    let page = PubNubHashedPageBase(start: "NextPage", totalCount: 2)
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.fetchMemberships(userId: "TestUser") { result in
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

  func test_FetchMemberships_WhenEmpty_ReturnsEmptyList() throws {
    let expectation = self.expectation(description: "Fetch Memberships Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_uuid_all_success_empty"])
    let testPage = PubNubHashedPageBase(start: "NextPage")

    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.fetchMemberships(userId: "TestUser") { result in
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
  func test_SetMemberships_RouterConfiguration_ReturnsCorrectEndpoint() {
    let router = ObjectsMembershipsRouter(
      .setMemberships(
        uuidMetadataId: "TestUUID", customFields: [], totalCount: true, changes: .init(set: [], delete: []),
        filter: "filter", sort: ["sort"], limit: 100, start: "Next", end: "last"
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Set the Membership Metadata for a UUID")
    XCTAssertEqual(router.category, "Set the Membership Metadata for a UUID")
    XCTAssertEqual(router.service, .objects)
  }

  func test_SetMemberships_RouterValidationWithEmptyId_ReturnsNoEndpointTypeError() {
    let router = ObjectsMembershipsRouter(
      .setMemberships(
        uuidMetadataId: "", customFields: [], totalCount: true, changes: .init(set: [], delete: []),
        filter: "filter", sort: ["sort"], limit: 100, start: "Next", end: "last"
      ),
      configuration: config
    )

    XCTAssertNotEqual(
      router.validationError?.pubNubError,
      PubNubError(.invalidEndpointType, router: router)
    )
  }

  func test_SetMemberships_WithValidConfig_ReturnsMemberships() throws {
    let expectation = self.expectation(description: "Update Memberships Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["objects_membership_success"])
    let channeDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z"))
    let firstDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-10-02T18:07:52.858703Z"))
    let lastDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-29T19:46:28.84402Z"))

    let firstChannel = PubNubChannelMetadataBase(
      metadataId: "FirstChannel", name: "First Channel",
      channelDescription: "Channel Description", updated: channeDate, eTag: "ChanneleTag"
    )
    let lastChannel = PubNubChannelMetadataBase(
      metadataId: "LastChannel"
    )
    let firstMembership = PubNubMembershipMetadataBase(
      userMetadataId: "TestUser", channelMetadataId: firstChannel.metadataId,
      channel: firstChannel,
      updated: firstDate, eTag: "FirstETag"
    )
    let lastMembership = PubNubMembershipMetadataBase(
      userMetadataId: "TestUser", channelMetadataId: "LastChannel",
      channel: lastChannel,
      updated: lastDate, eTag: "LastETag"
    )

    let page = PubNubHashedPageBase(start: "NextPage", totalCount: 2)
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.setMemberships(userId: "TestUser", channels: [firstMembership]) { result in
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

  func test_RemoveMemberships_WithValidConfig_ReturnsMemberships() throws {
    let expectation = self.expectation(description: "Update Memberships Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["objects_membership_success"])
    let channeDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z"))
    let firstDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-10-02T18:07:52.858703Z"))
    let lastDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-29T19:46:28.84402Z"))

    let firstChannel = PubNubChannelMetadataBase(
      metadataId: "FirstChannel", name: "First Channel",
      channelDescription: "Channel Description", updated: channeDate, eTag: "ChanneleTag"
    )
    let lastChannel = PubNubChannelMetadataBase(
      metadataId: "LastChannel"
    )
    let firstMembership = PubNubMembershipMetadataBase(
      userMetadataId: "TestUser", channelMetadataId: firstChannel.metadataId,
      channel: firstChannel,
      updated: firstDate, eTag: "FirstETag"
    )
    let lastMembership = PubNubMembershipMetadataBase(
      userMetadataId: "TestUser", channelMetadataId: "LastChannel",
      channel: lastChannel,
      updated: lastDate, eTag: "LastETag"
    )

    let page = PubNubHashedPageBase(start: "NextPage", totalCount: 2)
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.removeMemberships(userId: "TestUser", channels: [firstMembership]) { result in
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
  func test_FetchMembers_RouterConfiguration_ReturnsCorrectEndpoint() {
    let router = ObjectsMembershipsRouter(
      .fetchMembers(
        channelMetadataId: "TestUser", customFields: [], totalCount: false, filter: nil,
        sort: [], limit: nil, start: nil, end: nil
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Fetch the Membership Metadata of a Channel")
    XCTAssertEqual(router.category, "Fetch the Membership Metadata of a Channel")
    XCTAssertEqual(router.service, .objects)
  }

  func test_FetchMembers_RouterValidationWithEmptyId_ReturnsNoEndpointTypeError() {
    let router = ObjectsMembershipsRouter(
      .fetchMembers(
        channelMetadataId: "", customFields: [], totalCount: false, filter: nil,
        sort: [], limit: nil, start: nil, end: nil
      ),
      configuration: config
    )

    XCTAssertNotEqual(
      router.validationError?.pubNubError,
      PubNubError(.invalidEndpointType, router: router)
    )
  }

  func test_FetchMembers_WithValidConfig_ReturnsMembers() throws {
    let expectation = self.expectation(description: "Fetch Members Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["objects_members_success"])
    let uuidDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z"))
    let firstDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-10-02T18:07:52.858703Z"))
    let lastDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-29T19:46:28.84402Z"))

    let firstUser = PubNubUserMetadataBase(
      metadataId: "FirstUser", name: "First User", updated: uuidDate, eTag: "UserETag"
    )
    let lastUser = PubNubUserMetadataBase(
      metadataId: "LastUser"
    )

    let firstMembership = PubNubMembershipMetadataBase(
      userMetadataId: firstUser.metadataId, channelMetadataId: "TestChannel",
      status: "Test Status",
      user: firstUser,
      updated: firstDate, eTag: "FirstETag"
    )
    let lastMembership = PubNubMembershipMetadataBase(
      userMetadataId: "LastUser", channelMetadataId: "TestChannel",
      status: "Test Status",
      user: lastUser,
      custom: ["starred": true],
      updated: lastDate, eTag: "LastETag"
    )

    let page = PubNubHashedPageBase(start: "NextPage", totalCount: 2)
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_FetchMembers_WhenEmpty_ReturnsEmptyList() throws {
    let expectation = self.expectation(description: "Fetch Memberships Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["objects_uuid_all_success_empty"])

    let testPage = PubNubHashedPageBase(start: "NextPage")
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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
  func test_SetMembers_RouterConfiguration_ReturnsCorrectEndpoint() {
    let router = ObjectsMembershipsRouter(
      .setMembers(
        channelMetadataId: "TestUUID", customFields: [], totalCount: true, changes: .init(set: [], delete: []),
        filter: "filter", sort: ["sort"], limit: 100, start: "Next", end: "last"
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Set the Membership Metadata of a Channel")
    XCTAssertEqual(router.category, "Set the Membership Metadata of a Channel")
    XCTAssertEqual(router.service, .objects)
  }

  func test_SetMembers_RouterValidationWithEmptyId_ReturnsNoEndpointTypeError() {
    let router = ObjectsMembershipsRouter(
      .setMembers(
        channelMetadataId: "", customFields: [], totalCount: true, changes: .init(set: [], delete: []),
        filter: "filter", sort: ["sort"], limit: 100, start: "Next", end: "last"
      ),
      configuration: config
    )

    XCTAssertNotEqual(
      router.validationError?.pubNubError,
      PubNubError(.invalidEndpointType, router: router)
    )
  }

  func test_SetMembers_WithValidConfig_ReturnsMembers() throws {
    let expectation = self.expectation(description: "Set Members Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["objects_members_success"])
    let uuidDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z"))
    let firstDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-10-02T18:07:52.858703Z"))
    let lastDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-29T19:46:28.84402Z"))

    let firstUser = PubNubUserMetadataBase(
      metadataId: "FirstUser", name: "First User", updated: uuidDate, eTag: "UserETag"
    )
    let lastUser = PubNubUserMetadataBase(
      metadataId: "LastUser"
    )
    let firstMembership = PubNubMembershipMetadataBase(
      userMetadataId: firstUser.metadataId, channelMetadataId: "TestChannel",
      status: "Test Status",
      user: firstUser,
      updated: firstDate, eTag: "FirstETag"
    )
    let lastMembership = PubNubMembershipMetadataBase(
      userMetadataId: "LastUser", channelMetadataId: "TestChannel",
      status: "Test Status",
      user: lastUser,
      custom: ["starred": true],
      updated: lastDate, eTag: "LastETag"
    )

    let page = PubNubHashedPageBase(start: "NextPage", totalCount: 2)
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_RemoveMembers_WithValidConfig_ReturnsMembers() throws {
    let expectation = self.expectation(description: "Remove Members Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["objects_members_success"])
    let uuidDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z"))
    let firstDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-10-02T18:07:52.858703Z"))
    let lastDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-29T19:46:28.84402Z"))

    let firstUser = PubNubUserMetadataBase(
      metadataId: "FirstUser", name: "First User", updated: uuidDate, eTag: "UserETag"
    )
    let lastUser = PubNubUserMetadataBase(
      metadataId: "LastUser"
    )
    let firstMembership = PubNubMembershipMetadataBase(
      userMetadataId: firstUser.metadataId, channelMetadataId: "TestChannel",
      status: "Test Status",
      user: firstUser,
      updated: firstDate, eTag: "FirstETag"
    )
    let lastMembership = PubNubMembershipMetadataBase(
      userMetadataId: "LastUser", channelMetadataId: "TestChannel",
      status: "Test Status",
      user: lastUser,
      custom: ["starred": true],
      updated: lastDate, eTag: "LastETag"
    )

    let page = PubNubHashedPageBase(start: "NextPage", totalCount: 2)
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.removeMembers(channel: "TestChannel", uuids: [firstMembership]) { result in
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
