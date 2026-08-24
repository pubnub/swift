//
//  DataSyncUserEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import XCTest

class DataSyncUserEndpointIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: DataSyncUserEndpointIntegrationTests.self)
  let userClassVersion = 1

  func testCreateAndFetchUser() throws {
    let fetchExpect = expectation(description: "Fetch User Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userId = randomString()
    let payload = TestUserPayload(fullName: "Swift ITest User", email: "swift.itest@example.com")

    client.dataSync.createUser(
      classVersion: userClassVersion,
      id: userId,
      status: "active",
      payload: payload
    ) { [unowned client] createResult in
      switch createResult {
      case let .success(createdUser):
        XCTAssertEqual(createdUser.id, userId)
        XCTAssertFalse(createdUser.eTag.isEmpty)

        client.dataSync.getUser(userId) { fetchResult in
          switch fetchResult {
          case let .success(user):
            XCTAssertEqual(user.id, userId)
            XCTAssertEqual(user.status, "active")
            XCTAssertEqual(user.classVersion, self.userClassVersion)
            XCTAssertEqual(user.eTag, createdUser.eTag)
            XCTAssertPayload(user.payload, equals: payload)
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          fetchExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        fetchExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.dataSync.removeUser(
          userId,
          completion: $0
        )
      }
    }

    wait(for: [fetchExpect], timeout: 10.0)
  }

  func testSetUserReplacesPayloadWholesale() throws {
    let replaceExpect = expectation(description: "Replace User Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userId = randomString()

    client.dataSync.createUser(
      classVersion: userClassVersion,
      id: userId,
      status: "active",
      payload: TestUserPayload(fullName: "Swift ITest User", email: "swift.itest@example.com")
    ) { [unowned client] createResult in
      switch createResult {
      case let .success(createdUser):
        // The replacement omits `email`, which must therefore be cleared rather than preserved
        let replacementPayload = TestUserPayload(fullName: "Swift ITest User Renamed")

        client.dataSync.setUser(
          userId,
          classVersion: self.userClassVersion,
          status: "inactive",
          payload: replacementPayload
        ) { replaceResult in
          switch replaceResult {
          case let .success(replacedUser):
            XCTAssertEqual(replacedUser.id, userId)
            XCTAssertEqual(replacedUser.status, "inactive")
            XCTAssertPayload(replacedUser.payload, equals: replacementPayload)
            XCTAssertNotEqual(replacedUser.eTag, createdUser.eTag)
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          replaceExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        replaceExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.dataSync.removeUser(
          userId,
          completion: $0
        )
      }
    }

    wait(for: [replaceExpect], timeout: 10.0)
  }

  func testUpdateUserAppliesOperationsAndKeepsUntouchedFields() throws {
    let patchExpect = expectation(description: "Patch User Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userId = randomString()

    client.dataSync.createUser(
      classVersion: userClassVersion,
      id: userId,
      status: "active",
      payload: TestUserPayload(fullName: "Swift ITest User", email: "swift.itest@example.com")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        let expectedPayload = TestUserPayload(
          fullName: "Swift ITest User",
          email: "swift.patched@example.com",
          nickname: "Swifty"
        )

        client.dataSync.updateUser(
          userId,
          operations: [
            .replace(path: "/payload/email", value: "swift.patched@example.com"),
            .add(path: "/payload/nickname", value: "Swifty")
          ]
        ) { patchResult in
          switch patchResult {
          case let .success(patchedUser):
            XCTAssertPayload(patchedUser.payload, equals: expectedPayload)
            XCTAssertEqual(patchedUser.status, "active")
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          patchExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        patchExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.dataSync.removeUser(
          userId,
          completion: $0
        )
      }
    }

    wait(for: [patchExpect], timeout: 10.0)
  }

  func testSetUserWithStaleEtagFails() throws {
    let replaceExpect = expectation(description: "Replace User Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userId = randomString()

    client.dataSync.createUser(
      classVersion: userClassVersion,
      id: userId,
      status: "active",
      payload: TestUserPayload(fullName: "Swift ITest User")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        client.dataSync.setUser(
          userId,
          classVersion: self.userClassVersion,
          status: "inactive",
          payload: TestUserPayload(fullName: "Swift ITest User Renamed"),
          ifMatchesEtag: "stale-etag"
        ) { replaceResult in
          switch replaceResult {
          case .success:
            XCTFail("Test should fail")
          case let .failure(error):
            XCTAssertNotNil(error.pubNubError)
            XCTAssertEqual(error.pubNubError?.reason, .preconditionFailed)
          }
          replaceExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        replaceExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.dataSync.removeUser(
          userId,
          completion: $0
        )
      }
    }

    wait(for: [replaceExpect], timeout: 10.0)
  }

  func testGetUsersReturnsCreatedUsers() throws {
    let listExpect = expectation(description: "List Users Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userIds = [randomString(), randomString(), randomString()]

    createUsers(
      client: client,
      userIds: userIds
    )

    client.dataSync.getUsers { result in
      switch result {
      case let .success((users, _)):
        let fetchedIds = Set(users.map { $0.id })
        XCTAssertTrue(Set(userIds).isSubset(of: fetchedIds))
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      for userId in userIds {
        waitForCompletion {
          client.dataSync.removeUser(
            userId,
            completion: $0
          )
        }
      }
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testGetUsersPagesWithCursor() throws {
    let listExpect = expectation(description: "List Users Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userIds = [randomString(), randomString()]

    createUsers(
      client: client,
      userIds: userIds
    )

    client.dataSync.getUsers(limit: 1) { firstResult in
      switch firstResult {
      case let .success((firstPage, next)):
        XCTAssertEqual(firstPage.count, 1)
        XCTAssertEqual(next?.limit, 1)
        XCTAssertNotNil(next?.cursor)
        XCTAssertTrue(next?.hasNext ?? false)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      for userId in userIds {
        waitForCompletion {
          client.dataSync.removeUser(
            userId,
            completion: $0
          )
        }
      }
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testRemoveUserThenFetchFails() throws {
    let removeExpect = expectation(description: "Remove User Expectation")
    let client = PubNub(configuration: try dataSyncConfiguration(from: testsBundle))
    let userId = randomString()

    client.dataSync.createUser(
      classVersion: userClassVersion,
      id: userId,
      status: "active",
      payload: TestUserPayload(fullName: "Swift ITest User")
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        client.dataSync.removeUser(userId) { removeResult in
          switch removeResult {
          case .success:
            client.dataSync.getUser(userId) { fetchResult in
              switch fetchResult {
              case .success:
                XCTFail("Test should fail")
              case let .failure(error):
                XCTAssertNotNil(error.pubNubError)
                XCTAssertEqual(error.pubNubError?.reason, .resourceNotFound)
              }
              removeExpect.fulfill()
            }
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
            removeExpect.fulfill()
          }
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        removeExpect.fulfill()
      }
    }

    // No cleanup: removing the user is the subject of this test
    wait(for: [removeExpect], timeout: 10.0)
  }
}

// MARK: - Test Data

private struct TestUserPayload: JSONCodable, Equatable {
  let fullName: String?
  let email: String?
  let nickname: String?

  init(fullName: String? = nil, email: String? = nil, nickname: String? = nil) {
    self.fullName = fullName
    self.email = email
    self.nickname = nickname
  }
}

private extension DataSyncUserEndpointIntegrationTests {
  func createUsers(client: PubNub, userIds: [String]) {
    let setupExpect = expectation(description: "Create Test Users Expectation")
    setupExpect.expectedFulfillmentCount = 1
    setupExpect.assertForOverFulfill = true

    func createNext(_ remainingIds: [String]) {
      guard let userId = remainingIds.first else {
        setupExpect.fulfill(); return
      }

      client.dataSync.createUser(
        classVersion: userClassVersion,
        id: userId,
        status: "active",
        payload: TestUserPayload(fullName: userId)
      ) { result in
        switch result {
        case .success:
          createNext(Array(remainingIds.dropFirst()))
        case let .failure(error):
          XCTFail("Failed to setup test user \(userId): \(error)")
        }
      }
    }

    createNext(userIds)

    wait(for: [setupExpect], timeout: 15.0)
  }
}
