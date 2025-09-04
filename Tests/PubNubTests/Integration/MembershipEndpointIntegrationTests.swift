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

class MembershipEndpointIntegrationTests: XCTestCase {
  let config = PubNubConfiguration(from: Bundle(for: MembershipEndpointIntegrationTests.self))
  
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
  
  func testFetchMembershipsWithAdditionalParameters() {
    let fetchMembershipsExpect = expectation(description: "Fetch Membership Expectation")
    let client = PubNub(configuration: config)
    let userId = randomString()
    let channels = [randomString(), randomString()]
    let expectedMemberships = setUpMembershipTestData(client: client, userId: userId, channelIds: channels)
    
    client.fetchMemberships(
      userId: userId,
      include: .init(channelFields: true, channelCustomFields: true),
      sort: [.init(property: .object(.name), ascending: false)],
      limit: 1
    ) { result in
      switch result {
      case let .success((membershipsFromFirstPage, page)):
        // Verify the first page contains the expected number of memberships
        XCTAssertEqual(membershipsFromFirstPage.count, 1)
        XCTAssertEqual(membershipsFromFirstPage.first?.channelMetadataId, channels.sorted(by: >).first)
        XCTAssertTrue(membershipsFromFirstPage.allSatisfy { Set(channels).contains($0.channelMetadataId) && $0.userMetadataId == userId })
        // Fetch the next page
        client.fetchMemberships(
          userId: userId,
          include: .init(channelFields: true, channelCustomFields: true),
          limit: 1,
          page: page
        ) { result in
          switch result {
          case let .success((membershipsFromSecondPage, _)):
            XCTAssertEqual(membershipsFromSecondPage.count, expectedMemberships.count - membershipsFromFirstPage.count)
            XCTAssertTrue(membershipsFromSecondPage.allSatisfy { Set(channels).contains($0.channelMetadataId) && $0.userMetadataId == userId })
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
    let userId = randomString()
    
    let testChannel1 = randomString()
    let testChannel2 = randomString()
    let testChannel3 = randomString()
    let memberships = setUpMembershipTestData(client: client, userId: userId, channelIds: [testChannel1, testChannel2, testChannel3])
    
    client.manageMemberships(
      userId: userId,
      setting: [PubNubMembershipMetadataBase(userMetadataId: userId, channelMetadataId: testChannel3)],
      removing: [PubNubMembershipMetadataBase(userMetadataId: userId, channelMetadataId: testChannel1)]
    ) { result in
      switch result {
      case let .success((memberships, _)):
        XCTAssertEqual(memberships.count, 2)
        XCTAssertTrue(memberships.contains { $0.channelMetadataId == testChannel2 })
        XCTAssertTrue(memberships.contains { $0.channelMetadataId == testChannel3 })
        XCTAssertFalse(memberships.contains { $0.channelMetadataId == testChannel1 })
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      manageMembershipExpect.fulfill()
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
    
    wait(for: [manageMembershipExpect], timeout: 10.0)
  }
}

private extension MembershipEndpointIntegrationTests {
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
        client.setMemberships(userId: userId, channels: channelMetadataArray.map { PubNubMembershipMetadataBase(userMetadataId: userId, channelMetadataId: $0.metadataId) }) {
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
