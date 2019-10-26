//
//  SpaceObjectsEndpointIntegrationTests.swift
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

class SpaceObjectsEndpointIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: SpaceObjectsEndpointIntegrationTests.self)

  func testFetchAllEndpoint() {
    let fetchAllExpect = expectation(description: "Fetch All Expectation")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    client.fetchSpaces(include: .custom, limit: 100, count: true) { result in
      switch result {
      case let .success(response):
        XCTAssertTrue(response.totalCount ?? 0 >= response.spaces.count)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      fetchAllExpect.fulfill()
    }

    wait(for: [fetchAllExpect], timeout: 1000.0)
  }

  func testCreateAndFetchEndpoint() {
    let fetchExpect = expectation(description: "Fetch Expectation")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let space = SpaceObject(name: "Swift ITest", id: "SwiftITest")

    client.create(space: space, include: .custom) { response in
      client.fetch(spaceID: space.id) { result in
        switch result {
        case let .success(response):
          XCTAssertEqual(response.id, "SwiftITest")
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

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let space = SpaceObject(name: "Swift ITest", id: "SwiftITest")

    client.delete(spaceID: space.id) { _ in
      client.create(space: space, include: .custom) { result in
        switch result {
        case let .success(response):
          XCTAssertEqual(response.id, "SwiftITest")
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        fetchExpect.fulfill()
      }
    }

    wait(for: [fetchExpect], timeout: 10.0)
  }

  func testCreateAndUpdateEndpoint() {
    let fetchExpect = expectation(description: "Update Expectation")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let space = SpaceObject(name: "Swift ITest", id: "SwiftITest")

    client.create(space: space, include: .custom) { response in
      client.update(space: space, include: .custom) { result in
        switch result {
        case let .success(response):
          XCTAssertEqual(response.id, "SwiftITest")
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

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let space = SpaceObject(name: "Swift ITest", id: "SwiftITest")

    client.create(space: space, include: .custom) { response in
      client.delete(spaceID: space.id) { result in
        switch result {
        case let .success(response):
          XCTAssertTrue(response.message == .acknowledge)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        fetchExpect.fulfill()
      }
    }

    wait(for: [fetchExpect], timeout: 10.0)
  }

  func testFetchMemberships() {
    let fetchMembershipExpect = expectation(description: "Fetch Membership Expectation")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let user = UserObject(name: "Swift ITest", id: "SwiftITest")
    let space = SpaceObject(name: "Swift Membership ITest", id: "SwiftMembershipITest")

    client.create(user: user, include: .custom) { _ in
      client.create(space: space, include: .custom) { _ in
        client.fetchMembers(spaceID: space.id, include: [.custom, .customUser]) { result in
          switch result {
          case let .success(response):
            XCTAssertEqual(response.status, 200)
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          fetchMembershipExpect.fulfill()
        }
      }
    }

    wait(for: [fetchMembershipExpect], timeout: 10.0)
  }

  func testUpdateMemberships() {
    let fetchMembershipExpect = expectation(description: "Fetch Membership Expectation")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let user = UserObject(name: "Swift ITest", id: "SwiftITest")
    let space = SpaceObject(name: "Swift Membership ITest", id: "SwiftMembershipITest")

    client.create(user: user, include: .custom) { _ in
      client.create(space: space, include: .custom) { _ in
        client.modifyMembers(spaceID: space.id,
                             adding: [user],
                             removing: [user],
                             include: [.custom, .customUser]) { result in
          switch result {
          case let .success(response):
            XCTAssertEqual(response.status, 200)
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
