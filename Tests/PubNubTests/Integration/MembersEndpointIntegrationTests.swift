//
//  MembersEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import PubNubSDK
import XCTest

class MembersEndpointIntegrationTests: XCTestCase {
  let config = PubNubConfiguration(from: Bundle(for: MembersEndpointIntegrationTests.self))
  
  func testFetchMembers() {
    let fetchMembershipExpect = expectation(description: "Fetch Membership Expectation")
    let client = PubNub(configuration: config)
    let channelId = randomString()
    let userIds = [randomString(), randomString()]
    let members = setUpMembersTestData(client: client, channelId: channelId, userIds: userIds)
    
    client.fetchMembers(
      channel: channelId,
      include: .init(uuidFields: true, uuidCustomFields: true)
    ) { result in
      switch result {
      case let .success((memberships, _)):
        XCTAssertEqual(memberships.count, 2)
        XCTAssertTrue(memberships.allSatisfy { Set(userIds).contains($0.userMetadataId) && $0.channelMetadataId == channelId })
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      fetchMembershipExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeMembers(
          channel: channelId,
          users: members,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeChannelMetadata(
          channelId,
          completion: $0
        )
      }
      
      for member in members {
        waitForCompletion {
          client.removeUserMetadata(
            member.userMetadataId,
            completion: $0
          )
        }
      }
    }
    
    wait(for: [fetchMembershipExpect], timeout: 10.0)
  }
  
  func testFetchMembersWithPaginationParameters() {
    let fetchMembershipExpect = expectation(description: "Fetch Membership Expectation")
    let client = PubNub(configuration: config)
    let channelId = randomString()
    let userIds = [randomString(), randomString()]
    let expectedMembers = setUpMembersTestData(client: client, channelId: channelId, userIds: userIds)
    
    client.fetchMembers(
      channel: channelId,
      include: .init(uuidFields: true, uuidCustomFields: true),
      limit: 1
    ) { [unowned client] result in
      switch result {
      case let .success((membersFromFirstPage, page)):
        // Verify the first page contains the expected number of members
        XCTAssertEqual(membersFromFirstPage.count, 1)
        XCTAssertTrue(membersFromFirstPage.allSatisfy { Set(userIds).contains($0.userMetadataId) && $0.channelMetadataId == channelId })
        // Fetch the next page
        client.fetchMembers(
          channel: channelId,
          include: .init(uuidFields: true, uuidCustomFields: true),
          page: page
        ) { result in
          switch result {
          case let .success((membersFromSecondPage, _)):
            XCTAssertEqual(membersFromSecondPage.count, expectedMembers.count - membersFromFirstPage.count)
            XCTAssertTrue(membersFromSecondPage.allSatisfy { Set(userIds).contains($0.userMetadataId) && $0.channelMetadataId == channelId })
            // Verify that all expected member IDs are present in the fetched results
            let allFetchedMembers = membersFromFirstPage + membersFromSecondPage
            let fetchedMemberIds = Set(allFetchedMembers.map { $0.userMetadataId })
            let expectedMemberIds = Set(expectedMembers.map { $0.userMetadataId })
            XCTAssertEqual(fetchedMemberIds, expectedMemberIds)
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          fetchMembershipExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
    }
    
    defer {
      waitForCompletion {
        client.removeMembers(
          channel: channelId,
          users: expectedMembers,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeChannelMetadata(
          channelId,
          completion: $0
        )
      }
      
      for member in expectedMembers {
        waitForCompletion {
          client.removeUserMetadata(
            member.userMetadataId,
            completion: $0
          )
        }
      }
    }
    
    wait(for: [fetchMembershipExpect], timeout: 10.0)
  }
  
  func testFetchMembersWithFilterParameter() {
    let fetchMembershipExpect = expectation(description: "Fetch Membership Expectation")
    let client = PubNub(configuration: config)
    let channelId = randomString()
    let userIds = [randomString(), randomString()]
    let members = setUpMembersTestData(client: client, channelId: channelId, userIds: userIds)
    
    client.fetchMembers(
      channel: channelId,
      include: .init(uuidFields: true, uuidCustomFields: true),
      filter: "uuid.id == '\(members.first?.userMetadataId ?? String())'"
    ) { result in
      switch result {
      case let .success((actualMembers, _)):
        XCTAssertEqual(actualMembers.count, 1)
        XCTAssertEqual(actualMembers.first?.userMetadataId, members.first?.userMetadataId)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      fetchMembershipExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeMembers(
          channel: channelId,
          users: members,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeChannelMetadata(
          channelId,
          completion: $0
        )
      }
      
      for member in members {
        waitForCompletion {
          client.removeUserMetadata(
            member.userMetadataId,
            completion: $0
          )
        }
      }
    }
    
    wait(for: [fetchMembershipExpect], timeout: 10.0)
  }
  
  func testSetMembers() {
    let setMembersExpect = expectation(description: "Set Members Expectation")
    let client = PubNub(configuration: config)
    let channelId = randomString()
    let userIds = [randomString()]
    let members = setUpMembersTestData(client: client, channelId: channelId, userIds: userIds)
    
    // Test setting members with additional parameters
    client.setMembers(
      channel: channelId,
      users: members,
      include: .init(uuidFields: true, uuidCustomFields: true),
      sort: [.init(property: .object(.id))]
    ) { result in
      switch result {
      case let .success((memberships, _)):
        XCTAssertEqual(memberships.count, 1)
        XCTAssertTrue(memberships.allSatisfy { Set(userIds).contains($0.userMetadataId) && $0.channelMetadataId == channelId })
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      setMembersExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeMembers(
          channel: channelId,
          users: members,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeChannelMetadata(
          channelId,
          completion: $0
        )
      }
      
      for member in members {
        waitForCompletion {
          client.removeUserMetadata(
            member.userMetadataId,
            completion: $0
          )
        }
      }
    }
    
    wait(for: [setMembersExpect], timeout: 10.0)
  }
  
  func testRemoveMembers() {
    let removeMembersExpect = expectation(description: "Remove Members Expectation")
    let client = PubNub(configuration: config)
    let channelId = randomString()
    let userIds = [randomString()]
    let members = setUpMembersTestData(client: client, channelId: channelId, userIds: userIds)
    
    client.removeMembers(channel: channelId, users: members) { result in
      switch result {
      case let .success((memberships, _)):
        XCTAssertTrue(memberships.isEmpty)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      removeMembersExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeMembers(
          channel: channelId,
          users: members,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeChannelMetadata(
          channelId,
          completion: $0
        )
      }
      
      for member in members {
        waitForCompletion {
          client.removeUserMetadata(
            member.userMetadataId,
            completion: $0
          )
        }
      }
    }
    
    wait(for: [removeMembersExpect], timeout: 10.0)
  }
  
  func testManageMembers() {
    let manageMembersExpect = expectation(description: "Manage Members Expectation")
    let client = PubNub(configuration: config)
    
    let testUser1 = PubNubUserMetadataBase(
      metadataId: randomString(),
      name: "Swift ITest User 1"
    )
    let testUser2 = PubNubUserMetadataBase(
      metadataId: randomString(),
      name: "Swift ITest User 2"
    )
    let testUser3 = PubNubUserMetadataBase(
      metadataId: randomString(),
      name: "Swift ITest User 3"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: randomString(),
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
    client.setUserMetadata(testUser1) { [unowned client] _ in
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

private extension MembersEndpointIntegrationTests {
  func setUpMembersTestData(client: PubNub, channelId: String, userIds: [String]) -> [PubNubMembershipMetadata] {
    let setupExpect = expectation(description: "Setup Members Test Data")
    setupExpect.expectedFulfillmentCount = 1
    setupExpect.assertForOverFulfill = true
    
    let testChannel = PubNubChannelMetadataBase(metadataId: channelId, name: channelId)
    let userMetadataArray = userIds.map { PubNubUserMetadataBase(metadataId: $0, name: $0) }
    var membersToReturn: [PubNubMembershipMetadata] = []
    
    // Step 1: Create channel
    client.setChannelMetadata(testChannel) { [unowned client, unowned self] channelResult in
      // Step 2: Create users
      setupUsers(client: client, users: userMetadataArray) {
        // Step 3: Create members
        client.setMembers(
          channel: channelId,
          users: userMetadataArray.map { PubNubMembershipMetadataBase(userMetadataId: $0.metadataId, channelMetadataId: channelId) },
          include: .init(uuidFields: true, uuidCustomFields: true)
        ) {
          switch $0 {
          case let .success((members, _)):
            membersToReturn = members
            setupExpect.fulfill()
          case let .failure(error):
            XCTFail("Failed to setup members: \(error)")
          }
        }
      }
    }
    
    // Wait for members to be set up
    wait(for: [setupExpect], timeout: 15.0)
    
    // Return the members to the caller
    return membersToReturn
  }
  
  private func setupUsers(
    client: PubNub,
    users: [PubNubUserMetadataBase],
    completion: @escaping () -> Void
  ) {
    func setupNext(_ remainingUsers: [PubNubUserMetadataBase]) {
      if let user = remainingUsers.first {
        client.setUserMetadata(user) { result in
          switch result {
          case .success:
            setupNext(Array(remainingUsers.dropFirst()))
          case let .failure(error):
            XCTFail("Failed to setup user \(user.metadataId): \(error)")
          }
        }
      } else {
        completion()
      }
    }
    
    setupNext(users)
  }
}
