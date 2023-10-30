//
//  UUIDObjectsEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNub
import XCTest

class UUIDObjectsEndpointIntegrationTests: XCTestCase {
  let config = PubNubConfiguration(from: Bundle(for: UUIDObjectsEndpointIntegrationTests.self))

  func testFetchAllEndpoint() {
    let fetchAllExpect = expectation(description: "Fetch All Expectation")

    let client = PubNub(configuration: config)

    client.allUUIDMetadata(sort: [.init(property: .updated)]) { result in
      switch result {
      case let .success((users, nextPage)):
        XCTAssertTrue(nextPage?.totalCount ?? 0 >= users.count)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      fetchAllExpect.fulfill()
    }

    wait(for: [fetchAllExpect], timeout: 10.0)
  }

  func testUserCreateAndFetchEndpoint() {
    let fetchExpect = expectation(description: "Fetch User Expectation")

    let client = PubNub(configuration: config)

    let testUser = PubNubUUIDMetadataBase(
      metadataId: "testUserCreateAndFetchEndpoint", name: "Swift ITest", profileURL: "http://example.com"
    )

    client.set(uuid: testUser) { _ in
      client.fetch(uuid: testUser.metadataId) { result in
        switch result {
        case let .success(user):
          XCTAssertEqual(user.metadataId, testUser.metadataId)
          XCTAssertEqual(user.profileURL, testUser.profileURL)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        fetchExpect.fulfill()
      }
    }

    wait(for: [fetchExpect], timeout: 10.0)
  }

  func testUserDeleteAndCreateEndpoint() {
    let fetchExpect = expectation(description: "Create User Expectation")

    let client = PubNub(configuration: config)

    let testUser = PubNubUUIDMetadataBase(
      metadataId: "testUserDeleteAndCreateEndpoint", name: "Swift ITest"
    )

    client.remove(uuid: testUser.metadataId) { _ in
      client.set(uuid: testUser) { result in
        switch result {
        case let .success(user):
          XCTAssertEqual(user.metadataId, testUser.metadataId)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        fetchExpect.fulfill()
      }
    }

    wait(for: [fetchExpect], timeout: 10.0)
  }

  func testUserCreateAndDeleteEndpoint() {
    let fetchExpect = expectation(description: "Delete User Expectation")

    let client = PubNub(configuration: config)

    let testUser = PubNubUUIDMetadataBase(
      metadataId: "testUserCreateAndDeleteEndpoint", name: "Swift ITest"
    )

    client.set(uuid: testUser) { _ in
      client.remove(uuid: testUser.metadataId) { result in
        switch result {
        case let .success(userMetadataId):
          XCTAssertTrue(userMetadataId == testUser.metadataId)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        fetchExpect.fulfill()
      }
    }

    wait(for: [fetchExpect], timeout: 10.0)
  }

  func testUserFetchMemberships() {
    let fetchMembershipExpect = expectation(description: "Fetch Membership Expectation")

    let client = PubNub(configuration: config)

    let testUser = PubNubUUIDMetadataBase(
      metadataId: "testUserFetchMemberships", name: "Swift ITest"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testUserFetchMembershipsSpace", name: "Swift Membership ITest"
    )
    let membership = PubNubMembershipMetadataBase(
      uuidMetadataId: testUser.metadataId,
      channelMetadataId: testChannel.metadataId,
      uuid: testUser, channel: testChannel
    )

    client.set(uuid: testUser) { _ in
      client.set(channel: testChannel) { _ in
        client.setMemberships(uuid: testUser.metadataId, channels: [membership]) { _ in
          client.fetchMemberships(
            uuid: testUser.metadataId,
            include: .init(channelFields: true, channelCustomFields: true),
            sort: [.init(property: .object(.id), ascending: false), .init(property: .updated)]
          ) { result in
            switch result {
            case let .success((memberships, _)):
              XCTAssertTrue(
                memberships.contains(where: {
                  $0.channelMetadataId == testChannel.metadataId && $0.uuidMetadataId == testUser.metadataId
                }
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

  func testUpdateMemberships() {
    let updateMembershipExpect = expectation(description: "Update Membership Expectation")

    let client = PubNub(configuration: config)

    let testUser = PubNubUUIDMetadataBase(
      metadataId: "testUpdateMemberships", name: "Swift ITest"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testUpdateMembershipsSpace", name: "Swift Membership ITest"
    )
    let membership = PubNubMembershipMetadataBase(
      uuidMetadataId: testUser.metadataId,
      channelMetadataId: testChannel.metadataId,
      uuid: testUser, channel: testChannel
    )

    client.set(uuid: testUser) { _ in
      client.set(channel: testChannel) { _ in
        client.manageMemberships(
          uuid: testUser.metadataId,
          setting: [membership],
          removing: [membership]
        ) { result in
          switch result {
          case let .success((memberships, _)):
            XCTAssertTrue(
              memberships.contains(where: {
                $0.channelMetadataId == testChannel.metadataId && $0.uuidMetadataId == testUser.metadataId
              }
              )
            )
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          updateMembershipExpect.fulfill()
        }
      }
    }

    wait(for: [updateMembershipExpect], timeout: 10.0)
  }
}
