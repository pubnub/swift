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
    let expectedUsers = createTestUsers(client: client)
    
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

  func testFetchAllEndpointWithSortParameter() {
    let fetchAllExpect = expectation(description: "Fetch All Expectation")
    let client = PubNub(configuration: config)
    let expectedUsers = createTestUsers(client: client)
    
    client.allUserMetadata(
      filter: "id LIKE 'swift-*'",
      sort: [.init(property: .name, ascending: false)]
    ) { result in
      switch result {
      case let .success((users, _)):
        let expSortedUsers = expectedUsers.sorted(by: { $0.name ?? "" > $1.name ?? "" })
        XCTAssertEqual(expSortedUsers.map { $0.metadataId } , users.map { $0.metadataId })
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
  
  func testFetchAllEndpointWithPaginationParameters() {
    let fetchAllExpect = expectation(description: "Fetch All with Limit Expectation")
    let client = PubNub(configuration: config)
    let expectedUsers = createTestUsers(client: client)
    let limit = 3
    
    // First page
    client.allUserMetadata(
      filter: "id LIKE 'swift-*'",
      limit: limit
    ) { [unowned client] firstCallResult in
      switch firstCallResult {
      case let .success((users, page)):
        // Verify first page contains expected number of users
        XCTAssertEqual(users.count, limit)
        // Fetch second page using the next cursor
        client.allUserMetadata(
          filter: "id LIKE 'swift-*'",
          page: page
        ) { secondCallResult in
          switch secondCallResult {
          case let .success((secondUserArray, _)):
            XCTAssertEqual(secondUserArray.count, expectedUsers.count - limit)
            let firstPageIds = Set(users.map { $0.metadataId })
            let secondPageIds = Set(secondUserArray.map { $0.metadataId })
            let allFetchedIds = firstPageIds.union(secondPageIds)
            XCTAssertEqual(allFetchedIds, Set(expectedUsers.map { $0.metadataId }))
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          fetchAllExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
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
    
    wait(for: [fetchAllExpect], timeout: 15.0)
  }
  
  func testUserCreateAndFetchEndpoint() {
    let fetchExpect = expectation(description: "Fetch User Expectation")
    let client = PubNub(configuration: config)
    let testUser = PubNubUserMetadataBase(metadataId: randomString(), name: "Swift ITest")
    
    client.setUserMetadata(testUser) { [unowned client] setResult in
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
    let testUser = PubNubUserMetadataBase(metadataId: randomString(), name: "Swift ITest")
    
    client.setUserMetadata(testUser) { [unowned client] _ in
      client.removeUserMetadata(testUser.metadataId) { result in
        switch result {
        case let .success(userMetadataId):
          XCTAssertEqual(userMetadataId, testUser.metadataId)
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
    let testUser = PubNubUserMetadataBase(metadataId: randomString(), name: "Swift ITest")
    
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
}

private extension UserObjectsEndpointIntegrationTests {  
  func createTestUsers(client: PubNub) -> [PubNubUserMetadata] {
    let setupExpect = expectation(description: "Create Test Users Expectation")
    let testUsers = userStubs()

    setupExpect.expectedFulfillmentCount = testUsers.count
    setupExpect.assertForOverFulfill = true
    
    func createNext(_ remainingUsers: [PubNubUserMetadataBase]) {
      if let user = remainingUsers.first {
        client.setUserMetadata(user) { result in
          switch result {
          case .success:
            createNext(Array(remainingUsers.dropFirst()))
          case let .failure(error):
            XCTFail("Failed to setup test user \(user.metadataId): \(error)")
          }
          setupExpect.fulfill()
        }
      }
    }
    
    createNext(testUsers)
    // Wait for all users to be created
    wait(for: [setupExpect], timeout: 10.0)
    
    return testUsers
  }

  func userStubs() -> [PubNubUserMetadataBase] {
    [
      PubNubUserMetadataBase(
        metadataId: randomString(),
        name: "Test User One",
        status: "online",
        profileURL: "https://example.com/user1",
        custom: ["role": "admin", "department": "engineering"]
      ),
      PubNubUserMetadataBase(
        metadataId: randomString(),
        name: "Test User Two",
        status: "online",
        profileURL: "https://example.com/user2",
        custom: ["role": "user", "department": "marketing"]
      ),
      PubNubUserMetadataBase(
        metadataId: randomString(),
        name: "Test User Three",
        status: "offline",
        profileURL: "https://example.com/user3",
        custom: ["role": "manager", "department": "sales"]
      ),
      PubNubUserMetadataBase(
        metadataId: randomString(),
        name: "Test User Four",
        status: "archived",
        profileURL: "https://example.com/user4",
        custom: ["role": "developer", "department": "mobile"]
      ),
      PubNubUserMetadataBase(
        metadataId: randomString(),
        name: "Test User Five",
        status: "offline",
        profileURL: "https://example.com/user5",
        custom: ["role": "designer", "department": "ux"]
      ),
      PubNubUserMetadataBase(
        metadataId: randomString(),
        name: "Test User Six",
        status: "archived",
        profileURL: "https://example.com/user6",
        custom: ["role": "qa", "department": "testing"]
      )
    ]
  }
}
