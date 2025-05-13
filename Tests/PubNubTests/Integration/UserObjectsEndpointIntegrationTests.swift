//
//  UserObjectsEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import XCTest

class UserObjectsEndpointIntegrationTests: XCTestCase {
  let config = PubNubConfiguration(from: Bundle(for: UserObjectsEndpointIntegrationTests.self))
  
  func testFetchAllEndpoint() {
    let fetchAllExpect = expectation(description: "Fetch All Expectation")
    let client = PubNub(configuration: config)
    let expectedUsers = setupTestUsers(client: client)
    
    client.allUserMetadata(filter: "id LIKE 'swift-*'") { result in
      switch result {
      case let .success((users, _)):
        let expectedIds = expectedUsers.map { $0.metadataId }.sorted()
        let actualIds = users.map { $0.metadataId }.sorted()
        XCTAssertEqual(expectedIds, actualIds)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      fetchAllExpect.fulfill()
    }
    
    defer {
      for user in expectedUsers {
        waitForCompletion {
          client.removeUserMetadata(
            user.metadataId,
            completion: $0
          )
        }
      }
    }
    
    wait(for: [fetchAllExpect], timeout: 10.0)
  }
  
  func testUserCreateAndFetchEndpoint() {
    let fetchExpect = expectation(description: "Fetch User Expectation")
    let client = PubNub(configuration: config)
    let testUser = PubNubUserMetadataBase(metadataId: "testUserCreateAndFetchEndpoint", name: "Swift ITest")
    
    client.setUserMetadata(testUser) { setResult in
      client.fetchUserMetadata(testUser.metadataId) { result in
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
    
    defer {
      waitForCompletion {
        client.removeUserMetadata(
          testUser.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [fetchExpect], timeout: 10.0)
  }
  
  func testUserCreateAndDeleteEndpoint() {
    let fetchExpect = expectation(description: "Fetch User Expectation")
    let client = PubNub(configuration: config)
    let testUser = PubNubUserMetadataBase(metadataId: "testUserCreateAndDeleteEndpoint", name: "Swift ITest")
    
    client.setUserMetadata(testUser) { _ in
      client.removeUserMetadata(testUser.metadataId) { result in
        switch result {
        case let .success(userMetadataId):
          XCTAssertTrue(userMetadataId == testUser.metadataId)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        fetchExpect.fulfill()
      }
    }
    
    defer {
      waitForCompletion {
        client.removeUserMetadata(
          testUser.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [fetchExpect], timeout: 10.0)
  }
  
  func testFetchNotExistingUser() {
    let fetchExpect = expectation(description: "Fetch User Expectation")
    let client = PubNub(configuration: config)
    let testUser = PubNubUserMetadataBase(metadataId: "testFetchNotExistingUser", name: "Swift ITest")
    
    client.fetchUserMetadata(testUser.metadataId) { result in
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
        client.removeUserMetadata(
          testUser.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [fetchExpect], timeout: 10.0)
  }
  
  func testSetUserWithEntityTag() {
    let setExpect = expectation(description: "Delete User Expectation")
    let client = PubNub(configuration: config)
    
    var testUser = PubNubUserMetadataBase(
      metadataId: randomString(),
      name: "Swift ITest",
      externalId: "ABC",
      profileURL: "https://example.com"
    )
    
    client.setUserMetadata(testUser) { [unowned client] firstResult in
      // Update the user metadata
      testUser.profileURL = "https://example2.com"
      testUser.externalId = "XYZ"
      // Set the user metadata with the ifMatchesEtag parameter
      client.setUserMetadata(testUser, ifMatchesEtag: "12345") { result in
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
    
    waitForCompletion {
      client.removeUserMetadata(
        testUser.metadataId,
        completion: $0
      )
    }
    
    wait(for: [setExpect], timeout: 10.0)
  }
  
  func testUserFetchMemberships() {
    let fetchMembershipExpect = expectation(description: "Fetch Membership Expectation")
    let client = PubNub(configuration: config)
    
    let testUser = PubNubUserMetadataBase(
      metadataId: "testUserFetchMemberships",
      name: "Swift ITest"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testUserFetchMembershipsSpace",
      name: "Swift Membership ITest"
    )
    
    let membership = PubNubMembershipMetadataBase(
      userMetadataId: testUser.metadataId,
      channelMetadataId: testChannel.metadataId,
      user: testUser,
      channel: testChannel
    )
    
    client.setUserMetadata(testUser) { [unowned client] _ in
      client.setChannelMetadata(testChannel) { _ in
        client.setMemberships(userId: testUser.metadataId, channels: [membership]) { _ in
          client.fetchMemberships(
            userId: testUser.metadataId,
            include: .init(channelFields: true, channelCustomFields: true),
            sort: [.init(property: .object(.id), ascending: false), .init(property: .updated)]
          ) { result in
            switch result {
            case let .success((memberships, _)):
              XCTAssertEqual(memberships.count, 1)
              XCTAssertTrue(memberships.allSatisfy {
                  $0.channelMetadataId == testChannel.metadataId && $0.userMetadataId == testUser.metadataId
                }
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
        client.removeMemberships(
          userId: testUser.metadataId,
          channels: [membership],
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
          testChannel.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [fetchMembershipExpect], timeout: 10.0)
  }
  
  func testUpdateMembership() {
    let updateMembershipExpect = expectation(description: "Update Membership Expectation")
    let client = PubNub(configuration: config)
    
    let testUser = PubNubUserMetadataBase(
      metadataId: "testUpdateMemberships",
      name: "Swift ITest"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testUpdateMembershipsSpace",
      name: "Swift Membership ITest"
    )
    let membership = PubNubMembershipMetadataBase(
      userMetadataId: testUser.metadataId,
      channelMetadataId: testChannel.metadataId,
      user: testUser,
      channel: testChannel
    )
    
    client.setUserMetadata(testUser) { [unowned client] _ in
      client.setChannelMetadata(testChannel) { _ in
        client.setMemberships(userId: testUser.metadataId, channels: [membership]) { result in
          switch result {
          case let .success((memberships, _)):
            XCTAssertEqual(memberships.count, 1)
            XCTAssertTrue(
              memberships.allSatisfy {
                $0.channelMetadataId == testChannel.metadataId && $0.userMetadataId == testUser.metadataId
              }
            )
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          updateMembershipExpect.fulfill()
        }
      }
    }
    
    defer {
      waitForCompletion {
        client.removeMemberships(
          userId: testUser.metadataId,
          channels: [membership],
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
          testChannel.metadataId,
          completion: $0
        )
      }
    }
    
    wait(for: [updateMembershipExpect], timeout: 10.0)
  }
  
  func testRemoveMembership() {
    let removeMembershipExpect = expectation(description: "Remove Membership Expectation")
    let client = PubNub(configuration: config)
    
    let testUser = PubNubUserMetadataBase(
      metadataId: "testUpdateMemberships",
      name: "Swift ITest"
    )
    let testChannel = PubNubChannelMetadataBase(
      metadataId: "testUpdateMembershipsSpace",
      name: "Swift Membership ITest"
    )
    let membership = PubNubMembershipMetadataBase(
      userMetadataId: testUser.metadataId,
      channelMetadataId: testChannel.metadataId,
      user: testUser,
      channel: testChannel
    )
    
    client.setUserMetadata(testUser) { [unowned client] _ in
      client.setChannelMetadata(testChannel) { _ in
        client.removeMemberships(userId: testUser.metadataId, channels: [membership]) { result in
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
    
    defer {
      waitForCompletion {
        client.removeMemberships(
          userId: testUser.metadataId,
          channels: [membership],
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
          testChannel.metadataId,
          completion: $0
        )
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

private extension UserObjectsEndpointIntegrationTests {
  func userStubs() -> [PubNubUserMetadataBase] {
    [
      PubNubUserMetadataBase(
        metadataId: randomString(),
        name: "Test User One",
        profileURL: "https://example.com/user1",
        custom: ["role": "admin", "department": "engineering"]
      ),
      PubNubUserMetadataBase(
        metadataId: randomString(),
        name: "Test User Two",
        profileURL: "https://example.com/user2",
        custom: ["role": "user", "department": "marketing"]
      ),
      PubNubUserMetadataBase(
        metadataId: randomString(),
        name: "Test User Three",
        profileURL: "https://example.com/user3",
        custom: ["role": "manager", "department": "sales"]
      ),
      PubNubUserMetadataBase(
        metadataId: randomString(),
        name: "Test User Four",
        profileURL: "https://example.com/user4",
        custom: ["role": "developer", "department": "mobile"]
      ),
      PubNubUserMetadataBase(
        metadataId: randomString(),
        name: "Test User Five",
        profileURL: "https://example.com/user5",
        custom: ["role": "designer", "department": "ux"]
      ),
      PubNubUserMetadataBase(
        metadataId: randomString(),
        name: "Test User Six",
        profileURL: "https://example.com/user6",
        custom: ["role": "qa", "department": "testing"]
      )
    ]
  }
  
  func setupTestUsers(client: PubNub) -> [PubNubUserMetadata] {
    let setupExpect = expectation(description: "Setup Test Users Expectation")
    let testUsers = userStubs()
    
    testUsers.enumerated().forEach { index, user in
      client.setUserMetadata(user) { result in
        if case .failure(let error) = result {
          XCTFail("Failed to setup test user \(user.metadataId): \(error)")
        }
        if index == testUsers.count - 1 {
          setupExpect.fulfill()
        }
      }
    }
    
    wait(
      for: [setupExpect],
      timeout: 10.0
    )
    
    return testUsers
  }
}
