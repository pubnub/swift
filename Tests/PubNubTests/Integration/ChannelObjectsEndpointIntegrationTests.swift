//
//  ChannelObjectsEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNub
import XCTest

class ChannelObjectsEndpointIntegrationTests: XCTestCase {
  let config = PubNubConfiguration(from: Bundle(for: ChannelObjectsEndpointIntegrationTests.self))

  func testFetchAllEndpoint() {
    let fetchAllExpect = expectation(description: "Fetch All Expectation")
    let client = PubNub(configuration: config)

    client.allChannelMetadata(sort: [.init(property: .name)]) { result in
      switch result {
      case let .success((channels, nextPage)):
        XCTAssertTrue(nextPage?.totalCount ?? 0 >= channels.count)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      fetchAllExpect.fulfill()
    }

    wait(for: [fetchAllExpect], timeout: 10.0)
  }

  func testCreateAndFetchEndpoint() {
    let fetchExpect = expectation(description: "Fetch Expectation")

    let client = PubNub(configuration: config)

    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testCreateAndFetchEndpoint", name: "Swift ITest"
    )

    client.set(channel: testChannel) { _ in
      client.fetch(channel: testChannel.metadataId) { result in
        switch result {
        case let .success(channel):
          XCTAssertEqual(channel.metadataId, testChannel.metadataId)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        fetchExpect.fulfill()
      }
    }

    wait(for: [fetchExpect], timeout: 10.0)
  }

  func testDeleteAndCreateEndpoint() {
    let fetchExpect = expectation(description: "Create User Expectation")

    let client = PubNub(configuration: config)

    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testDeleteAndCreateEndpoint", name: "Swift ITest"
    )

    client.remove(channel: testChannel.metadataId) { _ in
      client.set(channel: testChannel) { result in
        switch result {
        case let .success(channel):
          XCTAssertEqual(channel.metadataId, testChannel.metadataId)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        fetchExpect.fulfill()
      }
    }

    wait(for: [fetchExpect], timeout: 10.0)
  }

  func testCreateAndDeleteEndpoint() {
    let fetchExpect = expectation(description: "Delete Expectation")

    let client = PubNub(configuration: config)

    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testCreateAndDeleteEndpoint", name: "Swift ITest"
    )

    client.set(channel: testChannel) { _ in
      client.remove(channel: testChannel.metadataId) { result in
        switch result {
        case let .success(metadataId):
          XCTAssertEqual(metadataId, testChannel.metadataId)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        fetchExpect.fulfill()
      }
    }

    wait(for: [fetchExpect], timeout: 10.0)
  }

  func testFetchMembers() {
    let fetchMembershipExpect = expectation(description: "Fetch Membership Expectation")

    let client = PubNub(configuration: config)

    let testUser = PubNubUUIDMetadataBase(
      metadataId: "testFetchMembersUUID", name: "Swift ITest"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testFetchMembersChannel", name: "Swift ITest"
    )
    let membership = PubNubMembershipMetadataBase(
      uuidMetadataId: testUser.metadataId,
      channelMetadataId: testChannel.metadataId,
      uuid: testUser, channel: testChannel
    )

    client.set(uuid: testUser) { _ in
      client.set(channel: testChannel) { _ in
        client.setMembers(channel: testChannel.metadataId, uuids: [membership]) { _ in
          client.fetchMembers(
            channel: testChannel.metadataId,
            include: .init(uuidFields: true, uuidCustomFields: true)
          ) { result in
            switch result {
            case let .success((memberships, _)):
              XCTAssertTrue(
                memberships.contains(
                  where: { $0.channelMetadataId == testChannel.metadataId && $0.uuidMetadataId == testUser.metadataId }
                )
              )
            case let .failure(error):
              XCTFail("Failed due to error: \(error)")
            }
            fetchMembershipExpect.fulfill()
          }
        }
      }
    }

    wait(for: [fetchMembershipExpect], timeout: 10.0)
  }

  func testManageMembers() {
    let fetchMembershipExpect = expectation(description: "Fetch Membership Expectation")

    let client = PubNub(configuration: config)

    let testUser = PubNubUUIDMetadataBase(
      metadataId: "testManageMembersUUID", name: "Swift ITest"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testManageMembersChannel", name: "Swift ITest"
    )
    let membership = PubNubMembershipMetadataBase(
      uuidMetadataId: testUser.metadataId,
      channelMetadataId: testChannel.metadataId,
      uuid: testUser, channel: testChannel
    )

    client.set(uuid: testUser) { _ in
      client.set(channel: testChannel) { _ in
        client.manageMembers(
          channel: testChannel.metadataId,
          setting: [membership],
          removing: [],
          include: .init(uuidFields: true, uuidCustomFields: true),
          sort: [.init(property: .object(.id)), .init(property: .updated)]
        ) { result in
          switch result {
          case let .success((memberships, _)):
            XCTAssertTrue(
              memberships.contains(
                where: { $0.channelMetadataId == testChannel.metadataId && $0.uuidMetadataId == testUser.metadataId }
              )
            )
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          fetchMembershipExpect.fulfill()
        }
      }
    }

    wait(for: [fetchMembershipExpect], timeout: 10.0)
  }
}
