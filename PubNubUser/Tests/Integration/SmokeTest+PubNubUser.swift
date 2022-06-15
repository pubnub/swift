//
//  SmokeTest+PubNubUser.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
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
@testable import PubNubUser

import XCTest

class PubNubUserInterfaceITests: XCTestCase {
  let testUser = PubNubUser(
    id: "TestUserId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    externalId: "TestExternalID",
    profileURL: URL(string: "http://example.com"),
    email: "TestEmail",
    custom: UserCustom(value: "TestValue")
  )

  let testUpdatedUser = PubNubUser(
    id: "TestUserId",
    name: "UpdatedName",
    type: "UpdatedType",
    status: "UpdatedStatus",
    externalId: "UpdatedExternalID",
    profileURL: URL(string: "http://updated.example.com"),
    email: "UpdatedEmail",
    custom: UserCustom(value: "UpdatedValue")
  )
  var createdUser: PubNubUser?
  var updatedUser: PubNubUser?

  let config = PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "itest-swift-userId"
  )

  func testUser_Smoke() throws {
    let expectation = XCTestExpectation(description: "Smoke Test User APIs")

    let createdEventExpectation = XCTestExpectation(description: "Created Event Listener")
    let updatedEventExpectation = XCTestExpectation(description: "Updated Event Listener")
    let removedEventExpectation = XCTestExpectation(description: "Removed Event Listener")
    let pubnub = PubNub(configuration: config)

    pubnub.subscribe(to: [testUser.id])

    // Smoke Test Events
    let listener = eventListener_Users(
      createdEventExpectation,
      updatedEventExpectation,
      removedEventExpectation
    )

    pubnub.add(listener)

    // Validate Outputs
    pubnub.createUser(
      userId: testUser.id,
      name: testUser.name,
      type: testUser.type,
      status: testUser.status,
      externalId: testUser.externalId,
      profileUrl: testUser.profileURL,
      email: testUser.email,
      custom: testUser.custom
    ) { [unowned self] result in
      do {
        switch result {
        case let .success(user):
          // Sync Server Set Fields
          createdUser = testUser
          createdUser?.updated = user.updated
          createdUser?.eTag = user.eTag

          XCTAssertEqual(user, createdUser)

          self.fetchUsers_Smoke(pubnub, user, expectation)

        case let .failure(error):
          XCTFail("Failed due to error \(error)")
          expectation.fulfill()
        }
      }
    }

    wait(
      for: [
        createdEventExpectation,
        updatedEventExpectation,
        expectation,
        removedEventExpectation
      ],
      timeout: 10.0
    )
  }

  func eventListener_Users(
    _ createdEventExpectation: XCTestExpectation,
    _ updatedEventExpectation: XCTestExpectation,
    _ removedEventExpectation: XCTestExpectation
  ) -> PubNubUserListener {
    let listener = PubNubUserListener()

    listener.didReceiveUserEvent = { [unowned self] event in
      switch event {
      case let .userUpdated(patcher):
        if let updatedUser = updatedUser {
          XCTAssertEqual(updatedUser, createdUser?.apply(patcher))
          updatedEventExpectation.fulfill()
        } else {
          XCTAssertEqual(testUser.apply(patcher), createdUser)
          createdEventExpectation.fulfill()
        }
      case let .userRemoved(user):
        XCTAssertEqual(user.id, testUser.id)
        removedEventExpectation.fulfill()
      }
    }

    return listener
  }

  func fetchUsers_Smoke(
    _ pubnub: PubNub,
    _ testUser: PubNubUser,
    _ expectation: XCTestExpectation
  ) {
    pubnub.fetchUsers { [unowned self] result in
      switch result {
      case let .success((users, next)):
        XCTAssertTrue(users.contains(testUser))
        XCTAssertNotNil(next)

        updateUser_Smoke(pubnub, expectation)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
        expectation.fulfill()
      }
    }
  }

  func updateUser_Smoke(
    _ pubnub: PubNub,
    _ expectation: XCTestExpectation
  ) {
    pubnub.updateUser(
      userId: testUpdatedUser.id,
      name: testUpdatedUser.name,
      type: testUpdatedUser.type,
      status: testUpdatedUser.status,
      externalId: testUpdatedUser.externalId,
      profileUrl: testUpdatedUser.profileURL,
      email: testUpdatedUser.email,
      custom: testUpdatedUser.custom
    ) { [unowned self] result in
      switch result {
      case let .success(user):
        // Sync Server Set Fields
        updatedUser = testUpdatedUser
        updatedUser?.updated = user.updated
        updatedUser?.eTag = user.eTag

        XCTAssertEqual(user, updatedUser)

        self.fetchUser_Smoke(pubnub, user, expectation)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
        expectation.fulfill()
      }
    }
  }

  func fetchUser_Smoke(
    _ pubnub: PubNub,
    _ fetchedUser: PubNubUser,
    _ expectation: XCTestExpectation
  ) {
    pubnub.fetchUser(userId: fetchedUser.id) { [unowned self] result in
      switch result {
      case let .success(user):
        XCTAssertEqual(user, fetchedUser)

        self.removeUser_Smoke(pubnub, expectation)
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
        expectation.fulfill()
      }
    }
  }

  func removeUser_Smoke(
    _ pubnub: PubNub,
    _ expectation: XCTestExpectation
  ) {
    pubnub.removeUser(userId: testUser.id) { [unowned self] result in
      switch result {
      case .success:
        pubnub.fetchUser(userId: testUser.id) { result in
          switch result {
          case .success:
            XCTFail("User was not successfully removed")
          case let .failure(error):
            XCTAssertEqual(error.pubNubError?.reason, .resourceNotFound)
            expectation.fulfill()
          }
        }
      case let .failure(error):
        XCTFail("Failed due to error \(error)")
        expectation.fulfill()
      }
    }
  }
}
