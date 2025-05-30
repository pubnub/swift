//
//  ChannelObjectsEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
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

    client.setChannelMetadata(testChannel) { _ in
      client.fetchChannelMetadata(testChannel.metadataId) { result in
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

    client.removeChannelMetadata(testChannel.metadataId) { _ in
      client.setChannelMetadata(testChannel) { result in
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

    client.setChannelMetadata(testChannel) { _ in
      client.removeChannelMetadata(testChannel.metadataId) { result in
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

    let testUser = PubNubUserMetadataBase(
      metadataId: "testFetchMembersUUID", name: "Swift ITest"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testFetchMembersChannel", name: "Swift ITest"
    )
    let membership = PubNubMembershipMetadataBase(
      userMetadataId: testUser.metadataId,
      channelMetadataId: testChannel.metadataId,
      user: testUser,
      channel: testChannel
    )

    client.setUserMetadata(testUser) { _ in
      client.setChannelMetadata(testChannel) { _ in
        client.setMembers(channel: testChannel.metadataId, users: [membership]) { _ in
          client.fetchMembers(
            channel: testChannel.metadataId,
            include: .init(uuidFields: true, uuidCustomFields: true)
          ) { result in
            switch result {
            case let .success((memberships, _)):
              XCTAssertTrue(
                memberships.contains(
                  where: { $0.channelMetadataId == testChannel.metadataId && $0.userMetadataId == testUser.metadataId }
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

    let testUser = PubNubUserMetadataBase(
      metadataId: "testManageMembersUUID", name: "Swift ITest"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testManageMembersChannel", name: "Swift ITest"
    )
    let membership = PubNubMembershipMetadataBase(
      userMetadataId: testUser.metadataId,
      channelMetadataId: testChannel.metadataId,
      user: testUser,
      channel: testChannel
    )

    client.setUserMetadata(testUser) { _ in
      client.setChannelMetadata(testChannel) { _ in
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
                where: { $0.channelMetadataId == testChannel.metadataId && $0.userMetadataId == testUser.metadataId }
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
