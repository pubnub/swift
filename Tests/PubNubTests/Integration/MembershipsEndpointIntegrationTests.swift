//
//  MembershipEndpointIntegrationTests.swift
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

class MembershipsEndpointIntegrationTests: XCTestCase {
  let config = PubNubConfiguration(from: Bundle(for: MembershipsEndpointIntegrationTests.self))
  
  func testFetchMemberships() {
    let fetchMembershipsExpect = expectation(description: "Fetch Membership Expectation")
    let client = PubNub(configuration: config)
    let userId = randomString()
    let channels = [randomString(), randomString()]
    let memberships = setUpMembershipTestData(client: client, userId: userId, channelIds: channels)
    
    client.fetchMemberships(
      userId: userId,
      include: .init(channelFields: true, channelCustomFields: true)
    ) { result in
      switch result {
      case let .success((memberships, _)):
        XCTAssertEqual(memberships.count, 2)
        XCTAssertTrue(memberships.allSatisfy { Set(channels).contains($0.channelMetadataId) && $0.userMetadataId == userId })
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      fetchMembershipsExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeMemberships(
          userId: userId,
          channels: memberships,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeUserMetadata(
          userId,
          completion: $0
        )
      }
      
      for membership in memberships {
        waitForCompletion {
          client.removeChannelMetadata(
            membership.channelMetadataId,
            completion: $0
          )
        }
      }
    }
    
    wait(for: [fetchMembershipsExpect], timeout: 10.0)
  }
  
  func testFetchMembershipsWithPaginationParameters() {
    let fetchMembershipsExpect = expectation(description: "Fetch Membership Expectation")
    let client = PubNub(configuration: config)
    let userId = randomString()
    let channels = [randomString(), randomString()]
    let expectedMemberships = setUpMembershipTestData(client: client, userId: userId, channelIds: channels)
    
    client.fetchMemberships(
      userId: userId,
      include: .init(channelFields: true, channelCustomFields: true),
      limit: 1
    ) { [unowned client] result in
      switch result {
      case let .success((membershipsFromFirstPage, page)):
        // Verify the first page contains the expected number of memberships
        XCTAssertEqual(membershipsFromFirstPage.count, 1)
        XCTAssertTrue(membershipsFromFirstPage.allSatisfy { Set(channels).contains($0.channelMetadataId) && $0.userMetadataId == userId })
        // Fetch the next page
        client.fetchMemberships(
          userId: userId,
          include: .init(channelFields: true, channelCustomFields: true),
          page: page
        ) { result in
          switch result {
          case let .success((membershipsFromSecondPage, _)):
            XCTAssertEqual(membershipsFromSecondPage.count, expectedMemberships.count - membershipsFromFirstPage.count)
            XCTAssertTrue(membershipsFromSecondPage.allSatisfy { Set(channels).contains($0.channelMetadataId) && $0.userMetadataId == userId })
            // Verify that all expected membership IDs are present in the fetched results
            let allFetchedMemberships = membershipsFromFirstPage + membershipsFromSecondPage
            let fetchedChannelIds = Set(allFetchedMemberships.map { $0.channelMetadataId })
            let expectedChannelIds = Set(expectedMemberships.map { $0.channelMetadataId })
            XCTAssertEqual(fetchedChannelIds, expectedChannelIds)
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          fetchMembershipsExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
    }
    
    defer {
      waitForCompletion {
        client.removeMemberships(
          userId: userId,
          channels: expectedMemberships,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeUserMetadata(
          userId,
          completion: $0
        )
      }
      
      for membership in expectedMemberships {
        waitForCompletion {
          client.removeChannelMetadata(
            membership.channelMetadataId,
            completion: $0
          )
        }
      }
    }
    
    wait(for: [fetchMembershipsExpect], timeout: 10.0)
  }
  
  func testFetchMembershipsWithFilterParameter() {
    let fetchMembershipsExpect = expectation(description: "Fetch Membership Expectation")
    let client = PubNub(configuration: config)
    let userId = randomString()
    let memberships = setUpMembershipTestData(client: client, userId: userId, channelIds: [randomString(), randomString()])
    
    client.fetchMemberships(
      userId: userId,
      include: .init(channelFields: true, channelCustomFields: true),
      filter: "channel.id == '\(memberships.first?.channelMetadataId ?? String())'"
    ) { result in
      switch result {
      case let .success((actualMemberships, _)):
        XCTAssertEqual(actualMemberships.count, 1)
        XCTAssertEqual(actualMemberships.first?.channelMetadataId, memberships.first?.channelMetadataId)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      fetchMembershipsExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeMemberships(
          userId: userId,
          channels: memberships,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeUserMetadata(
          userId,
          completion: $0
        )
      }
      
      for membership in memberships {
        waitForCompletion {
          client.removeChannelMetadata(
            membership.channelMetadataId,
            completion: $0
          )
        }
      }
    }
    
    wait(for: [fetchMembershipsExpect], timeout: 10.0)
  }
  
  func testRemoveMembership() {
    let removeMembershipExpect = expectation(description: "Remove Membership Expectation")
    let client = PubNub(configuration: config)
    let userId = randomString()
    let channelId = randomString()
    let memberships = setUpMembershipTestData(client: client, userId: userId, channelIds: [channelId])
    
    client.removeMemberships(
      userId: userId,
      channels: [PubNubMembershipMetadataBase(userMetadataId: userId, channelMetadataId: channelId)]
    ) { result in
      switch result {
      case let .success((memberships, _)):
        XCTAssertTrue(memberships.isEmpty)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      removeMembershipExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeMemberships(
          userId: userId,
          channels: memberships,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeUserMetadata(
          userId,
          completion: $0
        )
      }
      
      for membership in memberships {
        waitForCompletion {
          client.removeChannelMetadata(
            membership.channelMetadataId,
            completion: $0
          )
        }
      }
    }
    
    wait(for: [removeMembershipExpect], timeout: 10.0)
  }
  
  func testManageMemberships() {
    let manageMembershipExpect = expectation(description: "Manage Membership Expectation")
    let client = PubNub(configuration: config)
    
    let testUser = PubNubUserMetadataBase(
      metadataId: "testManageMemberships",
      name: "Swift ITest"
    )
    let testChannel1 = PubNubChannelMetadataBase(
      metadataId: "testManageMembershipsSpace1",
      name: "Swift Membership ITest 1"
    )
    let testChannel2 = PubNubChannelMetadataBase(
      metadataId: "testManageMembershipsSpace2",
      name: "Swift Membership ITest 2"
    )
    let testChannel3 = PubNubChannelMetadataBase(
      metadataId: "testManageMembershipsSpace3",
      name: "Swift Membership ITest 3"
    )
    
    let membership1 = PubNubMembershipMetadataBase(
      userMetadataId: testUser.metadataId,
      channelMetadataId: testChannel1.metadataId,
      user: testUser,
      channel: testChannel1
    )
    let membership2 = PubNubMembershipMetadataBase(
      userMetadataId: testUser.metadataId,
      channelMetadataId: testChannel2.metadataId,
      user: testUser,
      channel: testChannel2
    )
    let membership3 = PubNubMembershipMetadataBase(
      userMetadataId: testUser.metadataId,
      channelMetadataId: testChannel3.metadataId,
      user: testUser,
      channel: testChannel3
    )
    
    // First set up initial memberships
    client.setUserMetadata(testUser) { [unowned client] _ in
      client.setChannelMetadata(testChannel1) { _ in
        client.setChannelMetadata(testChannel2) { _ in
          client.setChannelMetadata(testChannel3) { _ in
            client.setMemberships(userId: testUser.metadataId, channels: [membership1, membership2]) { _ in
              client.manageMemberships(
                userId: testUser.metadataId,
                setting: [membership3],
                removing: [membership1]
              ) { result in
                switch result {
                case let .success((memberships, _)):
                  XCTAssertEqual(memberships.count, 2)
                  XCTAssertTrue(memberships.contains { $0.channelMetadataId == testChannel2.metadataId })
                  XCTAssertTrue(memberships.contains { $0.channelMetadataId == testChannel3.metadataId })
                  XCTAssertFalse(memberships.contains { $0.channelMetadataId == testChannel1.metadataId })
                case let .failure(error):
                  XCTFail("Failed due to error: \(error)")
                }
                manageMembershipExpect.fulfill()
              }
            }
          }
        }
      }
    }
    
    defer {
      waitForCompletion {
        client.removeMemberships(
          userId: testUser.metadataId,
          channels: [membership1, membership2, membership3],
          completion: $0
        )
      }
      waitForCompletion {
        client.removeUserMetadata(
          testUser.metadataId,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeChannelMetadata(
          testChannel1.metadataId,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeChannelMetadata(
          testChannel2.metadataId,
          completion: $0
        )
      }
      waitForCompletion {
        client.removeChannelMetadata(
          testChannel3.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [manageMembershipExpect], timeout: 10.0)
  }
}

private extension MembershipsEndpointIntegrationTests {
  func setUpMembershipTestData(client: PubNub, userId: String, channelIds: [String]) -> [PubNubMembershipMetadata] {
    let setupExpect = expectation(description: "Setup Membership Test Data")
    setupExpect.expectedFulfillmentCount = 1
    setupExpect.assertForOverFulfill = true
    
    let testUser = PubNubUserMetadataBase(metadataId: userId, name: userId)
    let channelMetadataArray = channelIds.map { PubNubChannelMetadataBase(metadataId: $0, name: $0) }
    var membershipsToReturn: [PubNubMembershipMetadata] = []
    
    // Step 1: Create user
    client.setUserMetadata(testUser) { [unowned client, unowned self] userResult in
      // Step 2: Create channels
      setupChannels(client: client, channels: channelMetadataArray) {
        // Step 3: Create memberships
        client.setMemberships(
          userId: userId,
          channels: channelMetadataArray.map { PubNubMembershipMetadataBase(userMetadataId: userId, channelMetadataId: $0.metadataId) },
          include: .init(channelFields: true, channelCustomFields: true)
        ) {
          switch $0 {
          case let .success((memberships, _)):
            membershipsToReturn = memberships
            setupExpect.fulfill()
          case let .failure(error):
            XCTFail("Failed to setup memberships: \(error)")
          }
        }
      }
    }
    
    // Wait for memberships to be set up
    wait(for: [setupExpect], timeout: 15.0)
    
    // Return the memberships to the caller
    return membershipsToReturn
  }
  
  private func setupChannels(
    client: PubNub,
    channels: [PubNubChannelMetadataBase],
    completion: @escaping () -> Void
  ) {
    func setupNext(_ remainingChannels: [PubNubChannelMetadataBase]) {
      if let channel = remainingChannels.first {
        client.setChannelMetadata(channel) { result in
          switch result {
          case .success:
            setupNext(Array(remainingChannels.dropFirst()))
          case let .failure(error):
            XCTFail("Failed to setup channel \(channel.metadataId): \(error)")
          }
        }
      } else {
        completion()
      }
    }
    
    setupNext(channels)
  }
}
