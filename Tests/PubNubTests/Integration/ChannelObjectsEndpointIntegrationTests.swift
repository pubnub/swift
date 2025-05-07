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
    let expectedChannels = setupTestChannels(client: client)
    
    client.allChannelMetadata(filter: "id LIKE 'swift-*'") { result in
      switch result {
      case let .success((channels, _)):
        let expectedIds = expectedChannels.map { $0.metadataId }.sorted()
        let actualIds = channels.map { $0.metadataId }.sorted()
        XCTAssertEqual(expectedIds, actualIds)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      fetchAllExpect.fulfill()
    }
    
    defer {
      for channel in expectedChannels {
        waitForCompletion {
          client.removeChannelMetadata(
            channel.metadataId,
            completion: $0
          )
        }
      }
    }
    
    wait(for: [fetchAllExpect], timeout: 10.0)
  }
  
  func testCreateAndFetchEndpoint() {
    let fetchExpect = expectation(description: "Fetch Expectation")
    let client = PubNub(configuration: config)
    let testChannel = PubNubChannelMetadataBase(metadataId: "testCreateAndFetchEndpoint", name: "Swift ITest")
    
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
    
    defer {
      waitForCompletion {
        client.removeChannelMetadata(
          testChannel.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [fetchExpect], timeout: 10.0)
  }
  
  func testDeleteAndCreateEndpoint() {
    let fetchExpect = expectation(description: "Create User Expectation")
    let client = PubNub(configuration: config)
    let testChannel = PubNubChannelMetadataBase(metadataId: "testDeleteAndCreateEndpoint", name: "Swift ITest")
    
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
    
    defer {
      waitForCompletion {
        client.removeChannelMetadata(
          testChannel.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [fetchExpect], timeout: 10.0)
  }
  
  func testFetchNotExistingChannel() {
    let fetchExpect = expectation(description: "Fetch Channel Expectation")
    let client = PubNub(configuration: config)
    let testChannel = PubNubChannelMetadataBase(metadataId: "testFetchNotExistingChannel", name: "Swift ITest")
    
    client.fetchChannelMetadata(testChannel.metadataId) { result in
      switch result {
      case .success:
        XCTFail("Test should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError?.reason, .resourceNotFound)
      }
      fetchExpect.fulfill()
    }
    
    
    defer {
      waitForCompletion {
        client.removeChannelMetadata(
          testChannel.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [fetchExpect], timeout: 10.0)
  }
  
  func testSetChannelWithEntityTag() {
    let setExpect = expectation(description: "Set Channel Expectation")
    let client = PubNub(configuration: config)
    
    var testChannel = PubNubChannelMetadataBase(
      metadataId: "testChannelWithEntityTag",
      name: "Swift ITest",
      custom: ["type": "public"]
    )
    
    client.setChannelMetadata(testChannel) { firstResult in
      // Update the channel metadata
      testChannel.custom = ["type": "private"]
      // Set the channel metadata with the ifMatchesEtag parameter
      client.setChannelMetadata(testChannel, ifMatchesEtag: "12345") { result in
        switch result {
        case .success:
          XCTFail("Test should fail")
        case let .failure(error):
          XCTAssertNotNil(error.pubNubError)
          XCTAssertEqual(error.pubNubError?.reason, .preconditionFailed)
        }
        setExpect.fulfill()
      }
    }
    
    defer {
      waitForCompletion {
        client.removeChannelMetadata(
          testChannel.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [setExpect], timeout: 10.0)
  }
  
  func testFetchMembers() {
    let fetchMembershipExpect = expectation(description: "Fetch Membership Expectation")
    let client = PubNub(configuration: config)
    
    let testUser = PubNubUserMetadataBase(
      metadataId: "testFetchMembersUUID",
      name: "Swift ITest"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testFetchMembersChannel",
      name: "Swift ITest"
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
    
    defer {
      waitForCompletion {
        client.removeMembers(
          channel: testChannel.metadataId,
          users: [membership],
          completion: $0
        )
      }
      waitForCompletion {
        client.removeUserMetadata(
          testChannel.metadataId,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeChannelMetadata(
          testChannel.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [fetchMembershipExpect], timeout: 10.0)
  }
  
  func testSetMembers() {
    let fetchMembershipExpect = expectation(description: "Fetch Membership Expectation")
    let client = PubNub(configuration: config)
    
    let testUser = PubNubUserMetadataBase(
      metadataId: "testManageMembersUUID",
      name: "Swift ITest"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testManageMembersChannel",
      name: "Swift ITest"
    )
    let membership = PubNubMembershipMetadataBase(
      userMetadataId: testUser.metadataId,
      channelMetadataId: testChannel.metadataId,
      user: testUser,
      channel: testChannel
    )
    
    client.setUserMetadata(testUser) { _ in
      client.setChannelMetadata(testChannel) { _ in
        client.setMembers(
          channel: testChannel.metadataId,
          users: [membership],
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
    
    defer {
      waitForCompletion {
        client.removeMembers(
          channel: testChannel.metadataId,
          users: [membership],
          completion: $0
        )
      }
      waitForCompletion {
        client.removeUserMetadata(
          testChannel.metadataId,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeChannelMetadata(
          testChannel.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [fetchMembershipExpect], timeout: 10.0)
  }
  
  func testRemoveMembers() {
    let removeMembershipExpect = expectation(description: "Remove Members Expectation")
    let client = PubNub(configuration: config)
    
    let testUser = PubNubUserMetadataBase(
      metadataId: "testRemoveMembersUUID",
      name: "Swift ITest"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testRemoveMembersChannel",
      name: "Swift ITest"
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
          client.removeMembers(channel: testChannel.metadataId, users: [membership]) { result in
            switch result {
            case let .success((memberships, _)):
              XCTAssertTrue(memberships.isEmpty)
            case let .failure(error):
              XCTFail("Failed due to error: \(error)")
            }
            removeMembershipExpect.fulfill()
          }
        }
      }
    }
    
    defer {
      waitForCompletion {
        client.removeMembers(
          channel: testChannel.metadataId,
          users: [membership],
          completion: $0
        )
      }
      waitForCompletion {
        client.removeUserMetadata(
          testChannel.metadataId,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeChannelMetadata(
          testChannel.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [removeMembershipExpect], timeout: 10.0)
  }
  
  func testManageMembers() {
    let manageMembersExpect = expectation(description: "Manage Members Expectation")
    let client = PubNub(configuration: config)
    
    let testUser1 = PubNubUserMetadataBase(
      metadataId: "testManageMembersUser1",
      name: "Swift ITest User 1"
    )
    let testUser2 = PubNubUserMetadataBase(
      metadataId: "testManageMembersUser2",
      name: "Swift ITest User 2"
    )
    let testUser3 = PubNubUserMetadataBase(
      metadataId: "testManageMembersUser3",
      name: "Swift ITest User 3"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testManageMembersChannel",
      name: "Swift ITest Channel"
    )
    
    let membership1 = PubNubMembershipMetadataBase(
      userMetadataId: testUser1.metadataId,
      channelMetadataId: testChannel.metadataId,
      user: testUser1,
      channel: testChannel
    )
    let membership2 = PubNubMembershipMetadataBase(
      userMetadataId: testUser2.metadataId,
      channelMetadataId: testChannel.metadataId,
      user: testUser2,
      channel: testChannel
    )
    let membership3 = PubNubMembershipMetadataBase(
      userMetadataId: testUser3.metadataId,
      channelMetadataId: testChannel.metadataId,
      user: testUser3,
      channel: testChannel
    )
    
    // First set up initial members
    client.setUserMetadata(testUser1) { _ in
      client.setUserMetadata(testUser2) { _ in
        client.setUserMetadata(testUser3) { _ in
          client.setChannelMetadata(testChannel) { _ in
            client.setMembers(channel: testChannel.metadataId, users: [membership1, membership2]) { _ in
              client.manageMembers(
                channel: testChannel.metadataId,
                setting: [membership3],
                removing: [membership1]
              ) { result in
                switch result {
                case let .success((memberships, _)):
                  XCTAssertEqual(memberships.count, 2)
                  XCTAssertTrue(memberships.contains { $0.userMetadataId == testUser2.metadataId })
                  XCTAssertTrue(memberships.contains { $0.userMetadataId == testUser3.metadataId })
                  XCTAssertFalse(memberships.contains { $0.userMetadataId == testUser1.metadataId })
                case let .failure(error):
                  XCTFail("Failed due to error: \(error)")
                }
                manageMembersExpect.fulfill()
              }
            }
          }
        }
      }
    }
    
    defer {
      waitForCompletion {
        client.removeMembers(
          channel: testChannel.metadataId,
          users: [membership1, membership2, membership3],
          completion: $0
        )
      }
      waitForCompletion {
        client.removeUserMetadata(
          testUser1.metadataId,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeUserMetadata(
          testUser2.metadataId,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeUserMetadata(
          testUser3.metadataId,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeChannelMetadata(
          testChannel.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [manageMembersExpect], timeout: 10.0)
  }
}

private extension ChannelObjectsEndpointIntegrationTests {
  func channelStubs() -> [PubNubChannelMetadataBase] {
    [
      PubNubChannelMetadataBase(
        metadataId: "swift-channel-1",
        name: "Test Channel One",
        custom: ["type": "public", "category": "general"]
      ),
      PubNubChannelMetadataBase(
        metadataId: "swift-channel-2",
        name: "Test Channel Two",
        custom: ["type": "private", "category": "support"]
      ),
      PubNubChannelMetadataBase(
        metadataId: "swift-channel-3",
        name: "Test Channel Three",
        custom: ["type": "public", "category": "announcements"]
      ),
      PubNubChannelMetadataBase(
        metadataId: "swift-channel-4",
        name: "Test Channel Four",
        custom: ["type": "private", "category": "development"]
      ),
      PubNubChannelMetadataBase(
        metadataId: "swift-channel-5",
        name: "Test Channel Five",
        custom: ["type": "public", "category": "marketing"]
      ),
      PubNubChannelMetadataBase(
        metadataId: "swift-channel-6",
        name: "Test Channel Six",
        custom: ["type": "private", "category": "sales"]
      )
    ]
  }
  
  func setupTestChannels(client: PubNub) -> [PubNubChannelMetadata] {
    let setupExpect = expectation(description: "Setup Test Channels Expectation")
    let testChannels = channelStubs()
    
    testChannels.enumerated().forEach { index, channel in
      client.setChannelMetadata(channel) { result in
        if case .failure(let error) = result {
          XCTFail("Failed to setup test channel \(channel.metadataId): \(error)")
        }
        if index == testChannels.count - 1 {
          setupExpect.fulfill()
        }
      }
    }
    
    wait(
      for: [setupExpect],
      timeout: 10.0
    )
    
    return testChannels
  }
}
