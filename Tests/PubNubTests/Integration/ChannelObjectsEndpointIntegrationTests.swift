//
//  ChannelObjectsEndpointIntegrationTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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
          removing: [membership],
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
