//
//  UserObjectsEndpointTests.swift
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

@testable import PubNub
import XCTest

// swiftlint:disable:next type_body_length
final class UserObjectsEndpointTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")
  let fetchAllUsers = Endpoint.objectsUserFetchAll(include: nil, limit: nil, start: nil, end: nil, count: nil)
  let fetchUser = Endpoint.objectsUserFetch(userID: "SomeUser", include: nil)
  let testUser = UserObject(name: "TestUser")
  let invalidUser = UserObject(name: "")

  // MARK: - Fetch All Tests

  func testFetchAll_Endpoint() {
    let endpoint = Endpoint.objectsUserFetchAll(include: .custom, limit: 100, start: "Start", end: "End", count: true)

    XCTAssertEqual(endpoint.description, "Fetch All User Objects")
    XCTAssertEqual(endpoint.rawValue, .objectsUserFetchAll)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testFetchAll_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsUserFetchAll(include: .custom, limit: 100, start: "Start", end: "End", count: true)

    XCTAssertEqual(endpoint.associatedValue["include"] as? Endpoint.IncludeField, .custom)
    XCTAssertEqual(endpoint.associatedValue["limit"] as? Int, 100)
    XCTAssertEqual(endpoint.associatedValue["start"] as? String, "Start")
    XCTAssertEqual(endpoint.associatedValue["end"] as? String, "End")
    XCTAssertEqual(endpoint.associatedValue["count"] as? Bool, true)
  }

  func testFetchAll_Success() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_users_fetchAll_success"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-08-18T11:25:55.44977Z"),
      let lastCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-08-18T11:25:59.326105Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "HNNCTGRURF", id: "WGWPWPJBRJ", created: firstCreatedDate, eTag: "AY/Cz7edr46A3wE")
    let lastUser = UserObject(name: "VDUVIGRMWF", id: "OSPULBRLGN",
                              custom: ["info": "JMGXDNYF"],
                              created: lastCreatedDate, eTag: "AeH55Y3T0a78Ew")

    PubNub(configuration: config, session: sessions.session)
      .fetchUsers(include: .custom) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.next, "NextPage")
          XCTAssertEqual(payload.prev, "PrevPage")
          XCTAssertEqual(payload.status, 200)
          XCTAssertEqual(payload.totalCount, 2)

          XCTAssertTrue(firstUser.isEqual(payload.users.first))
          XCTAssertTrue(lastUser.isEqual(payload.users.last))

        case let .failure(error):
          XCTFail("Fetch All request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 100.0)
  }

  func testFetchAll_Success_empty() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_users_fetchAll_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchUsers(include: .custom) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertTrue(payload.users.isEmpty)
        case let .failure(error):
          XCTFail("Fetch All request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchAll_error_403() {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_403"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchUsers(include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.forbidden, self.fetchAllUsers, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchAll_error_429() {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_429"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchUsers(include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.tooManyRequests, self.fetchAllUsers, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchAll_error_500() {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_500"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchUsers(include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.internalServiceError,
                                                    self.fetchAllUsers,
                                                    task.mockRequest,
                                                    response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchAll_error_503() {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_503"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchUsers(include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.serviceUnavailable, self.fetchAllUsers, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Fetch Tests

  func testFetch_Endpoint() {
    let endpoint = Endpoint.objectsUserFetch(userID: "OtherUser", include: .custom)

    XCTAssertEqual(endpoint.description, "Fetch User Object")
    XCTAssertEqual(endpoint.rawValue, .objectsUserFetch)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testFetch_Endpoint_ValidationError() {
    let endpoint = Endpoint.objectsUserFetch(userID: "", include: .custom)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError,
                      PNError.invalidEndpointType(endpoint))
  }

  func testFetch_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsUserFetch(userID: "OtherUser", include: .custom)

    XCTAssertEqual(endpoint.associatedValue["userID"] as? String, "OtherUser")
    XCTAssertEqual(endpoint.associatedValue["include"] as? Endpoint.IncludeField, .custom)
  }

  func testFetch_Success() {
    let expectation = self.expectation(description: "Fetch Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_users_fetch_success"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser",
                               custom: ["string": "String", "int": 1, "double": 1.1, "bool": true],
                               created: firstCreatedDate,
                               eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .fetch(userID: "TestUser") { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertTrue(firstUser.isEqual(payload.user))
        case let .failure(error):
          XCTFail("Fetch request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetch_error_403() {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_403"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetch(userID: "TestUser") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.forbidden, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetch_error_404() {
    let expectation = self.expectation(description: "404 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_404"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetch(userID: "TestUser") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.resourceNotFound, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetch_error_429() {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_429"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetch(userID: "TestUser") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.tooManyRequests, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetch_error_500() {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_500"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetch(userID: "TestUser") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.internalServiceError, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetch_error_503() {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_503"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetch(userID: "TestUser") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.serviceUnavailable, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Create Tests

  func testCreate_Endpoint() {
    let endpoint = Endpoint.objectsUserCreate(user: testUser, include: .custom)

    XCTAssertEqual(endpoint.description, "Create User Object")
    XCTAssertEqual(endpoint.rawValue, .objectsUserCreate)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testCreate_Endpoint_ValidationError() {
    let endpoint = Endpoint.objectsUserCreate(user: invalidUser, include: .custom)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError,
                      PNError.invalidEndpointType(endpoint))
  }

  func testCreate_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsUserCreate(user: testUser, include: .custom)

    XCTAssertTrue(testUser.isEqual(endpoint.associatedValue["user"] as? PubNubUser))
    XCTAssertEqual(endpoint.associatedValue["include"] as? Endpoint.IncludeField, .custom)
  }

  func testCreate_Success() {
    let expectation = self.expectation(description: "Create Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_users_fetch_success"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser",
                               custom: ["string": "String", "int": 1, "double": 1.1, "bool": true],
                               created: firstCreatedDate,
                               eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(user: firstUser, include: .custom) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertTrue(firstUser.isEqual(payload.user))
        case let .failure(error):
          XCTFail("Create request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_400() {
    let expectation = self.expectation(description: "400 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_400"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.badRequest, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_403() {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_403"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.forbidden, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_409() {
    let expectation = self.expectation(description: "409 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_409"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.conflict, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_415() {
    let expectation = self.expectation(description: "415 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_415"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.unsupportedType, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_429() {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_429"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.tooManyRequests, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_500() {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_500"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.internalServiceError, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_503() {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_503"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.serviceUnavailable, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Update Tests

  func testUpdate_Endpoint() {
    let endpoint = Endpoint.objectsUserUpdate(user: testUser, include: .custom)

    XCTAssertEqual(endpoint.description, "Update User Object")
    XCTAssertEqual(endpoint.rawValue, .objectsUserUpdate)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testUpdate_Endpoint_ValidationError() {
    let endpoint = Endpoint.objectsUserUpdate(user: invalidUser, include: .custom)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError,
                      PNError.invalidEndpointType(endpoint))
  }

  func testUpdate_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsUserUpdate(user: testUser, include: .custom)

    XCTAssertTrue(testUser.isEqual(endpoint.associatedValue["user"] as? PubNubUser))
    XCTAssertEqual(endpoint.associatedValue["include"] as? Endpoint.IncludeField, .custom)
  }

  func testUpdate_Success() {
    let expectation = self.expectation(description: "Update Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_users_fetch_success"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser",
                               custom: ["string": "String", "int": 1, "double": 1.1, "bool": true],
                               created: firstCreatedDate,
                               eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(user: firstUser) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertTrue(firstUser.isEqual(payload.user))
        case let .failure(error):
          XCTFail("Update request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_400() {
    let expectation = self.expectation(description: "400 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_400"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.badRequest, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_403() {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_403"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.forbidden, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_404() {
    let expectation = self.expectation(description: "409 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_409"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.conflict, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_412() {
    let expectation = self.expectation(description: "412 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_412"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.preconditionFailed, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_415() {
    let expectation = self.expectation(description: "415 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_415"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.unsupportedType, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_429() {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_429"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.tooManyRequests, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_500() {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_500"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.internalServiceError, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_503() {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_503"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "Test User", id: "TestUser", created: firstCreatedDate, eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(user: firstUser, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.serviceUnavailable, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Delete Tests

  func testDelete_Endpoint() {
    let endpoint = Endpoint.objectsUserDelete(userID: "TestUser", include: .custom)

    XCTAssertEqual(endpoint.description, "Delete User Object")
    XCTAssertEqual(endpoint.rawValue, .objectsUserDelete)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testDelete_Endpoint_ValidationError() {
    let endpoint = Endpoint.objectsUserFetch(userID: "", include: .custom)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError,
                      PNError.invalidEndpointType(endpoint))
  }

  func testDelete_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsUserDelete(userID: "TestUser", include: .custom)

    XCTAssertEqual(endpoint.associatedValue["userID"] as? String, "TestUser")
    XCTAssertEqual(endpoint.associatedValue["include"] as? Endpoint.IncludeField, .custom)
  }

  func testDelete_Success() {
    let expectation = self.expectation(description: "Delete Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_users_fetch_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .delete(userID: "TestUser") { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
        case let .failure(error):
          XCTFail("Delete request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testDelete_error_403() {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_403"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .delete(userID: "TestUser") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.forbidden, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testDelete_error_412() {
    let expectation = self.expectation(description: "412 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_412"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .delete(userID: "TestUser") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.preconditionFailed, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testDelete_error_429() {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_429"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .delete(userID: "TestUser") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.tooManyRequests, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testDelete_error_500() {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_500"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .delete(userID: "TestUser") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.internalServiceError, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testDelete_error_503() {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_503"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .delete(userID: "TestUser") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first,
            let response = task.mockResponse else {
            return XCTFail("Could not get task")
          }

          let pubNubError = PNError.endpointFailure(.serviceUnavailable, self.fetchUser, task.mockRequest, response)

          XCTAssertEqual(error.pubNubError, pubNubError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Fetch Memberships Tests

  func testMembershipFetch_Endpoint() {
    let endpoint = Endpoint.objectsUserMemberships(userID: "TestUser",
                                                   include: [],
                                                   limit: nil, start: nil, end: nil, count: nil)

    XCTAssertEqual(endpoint.description, "Fetch User's Memberships")
    XCTAssertEqual(endpoint.rawValue, .objectsUserMemberships)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testMembershipFetch_Endpoint_ValidationError() {
    let endpoint = Endpoint.objectsUserMemberships(userID: "",
                                                   include: [],
                                                   limit: nil, start: nil, end: nil, count: nil)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError,
                      PNError.invalidEndpointType(endpoint))
  }

  func testMembershipFetch_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsUserMemberships(userID: "TestUser",
                                                   include: [.customSpace],
                                                   limit: 100, start: "Start", end: "End", count: true)

    XCTAssertEqual(endpoint.associatedValue.count, 6)
    XCTAssertEqual(endpoint.associatedValue["userID"] as? String, "TestUser")
    XCTAssertEqual(endpoint.associatedValue["include"] as? [Endpoint.IncludeField], [.customSpace])
    XCTAssertEqual(endpoint.associatedValue["limit"] as? Int, 100)
    XCTAssertEqual(endpoint.associatedValue["start"] as? String, "Start")
    XCTAssertEqual(endpoint.associatedValue["end"] as? String, "End")
    XCTAssertEqual(endpoint.associatedValue["count"] as? Bool, true)
  }

  func testMembershipFetch_Success() {
    let expectation = self.expectation(description: "Fetch Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_users_fetchMemberships_success"]),
      let spaceDate = Constant.iso8601DateFormatter.date(from: "2019-09-29T13:07:45.807503Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "First Space",
                                 id: "FirstSpace",
                                 spaceDescription: "Space Description",
                                 created: spaceDate,
                                 eTag: "SpaceETag")

    PubNub(configuration: config, session: sessions.session)
      .fetchMemberships(userID: "TestUser") { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertEqual(payload.next, "NextPage")
          XCTAssertEqual(payload.totalCount, 2)

          XCTAssertEqual(payload.memberships.first?.id, firstSpace.id)
          XCTAssertEqual(payload.memberships.first?.customType.isEmpty, true)
          XCTAssertEqual(payload.memberships.first?.eTag, "FirstETag")
          XCTAssertEqual(payload.memberships.first?.created,
                         Constant.iso8601DateFormatter.date(from: "2019-09-29T13:07:57.589822Z"))
          XCTAssertTrue(firstSpace.isEqual(payload.memberships.first?.space))

          XCTAssertEqual(payload.memberships.last?.id, "LastSpace")
          XCTAssertEqual(payload.memberships.last?.customType, ["starred": .init(boolValue: true)])
          XCTAssertEqual(payload.memberships.last?.eTag, "LastETag")
          XCTAssertEqual(payload.memberships.last?.created,
                         Constant.iso8601DateFormatter.date(from: "2019-09-29T19:13:43.964451Z"))
          XCTAssertNil(payload.memberships.last?.space)

        case let .failure(error):
          XCTFail("Fetch Memberships request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testMembershipFetch_Success_Empty() {
    let expectation = self.expectation(description: "Fetch Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_users_fetchAll_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchMemberships(userID: "TestUser") { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertEqual(payload.memberships.isEmpty, true)

        case let .failure(error):
          XCTFail("Fetch Memberships request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Update Memberships Tests

  func testMembershipUpdate_Endpoint() {
    let endpoint = Endpoint.objectsUserMembershipsUpdate(userID: "TestUser",
                                                         add: [], update: [], remove: [],
                                                         include: [],
                                                         limit: nil, start: nil, end: nil, count: nil)

    XCTAssertEqual(endpoint.description, "Update User's Memberships")
    XCTAssertEqual(endpoint.rawValue, .objectsUserMembershipsUpdate)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testMembershipUpdate_Endpoint_ValidationError() {
    let endpoint = Endpoint.objectsUserMembershipsUpdate(userID: "",
                                                         add: [], update: [], remove: [],
                                                         include: [],
                                                         limit: nil, start: nil, end: nil, count: nil)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError,
                      PNError.invalidEndpointType(endpoint))
  }

  func testMembershipUpdate_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsUserMembershipsUpdate(userID: "TestUser",
                                                         add: [], update: [], remove: [],
                                                         include: [.customSpace],
                                                         limit: 100, start: "Start", end: "End", count: true)

    XCTAssertEqual(endpoint.associatedValue.count, 9)
    XCTAssertEqual(endpoint.associatedValue["userID"] as? String, "TestUser")
    XCTAssertEqual((endpoint.associatedValue["add"] as? [ObjectIdentifiable])?.isEmpty, true)
    XCTAssertEqual((endpoint.associatedValue["update"] as? [ObjectIdentifiable])?.isEmpty, true)
    XCTAssertEqual((endpoint.associatedValue["remove"] as? [ObjectIdentifiable])?.isEmpty, true)
    XCTAssertEqual(endpoint.associatedValue["include"] as? [Endpoint.IncludeField], [.customSpace])
    XCTAssertEqual(endpoint.associatedValue["limit"] as? Int, 100)
    XCTAssertEqual(endpoint.associatedValue["start"] as? String, "Start")
    XCTAssertEqual(endpoint.associatedValue["end"] as? String, "End")
    XCTAssertEqual(endpoint.associatedValue["count"] as? Bool, true)
  }

  func testMembershipUpdate_Success() {
    let expectation = self.expectation(description: "Update Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_users_fetchMemberships_success"]),
      let spaceDate = Constant.iso8601DateFormatter.date(from: "2019-09-29T13:07:45.807503Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "First Space",
                                 id: "FirstSpace",
                                 spaceDescription: "Space Description",
                                 created: spaceDate,
                                 eTag: "SpaceETag")

    PubNub(configuration: config, session: sessions.session)
      .updateMemberships(userID: "TestUser", adding: [firstSpace]) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertEqual(payload.next, "NextPage")
          XCTAssertEqual(payload.totalCount, 2)

          XCTAssertEqual(payload.memberships.first?.id, firstSpace.id)
          XCTAssertEqual(payload.memberships.first?.customType.isEmpty, true)
          XCTAssertEqual(payload.memberships.first?.eTag, "FirstETag")
          XCTAssertEqual(payload.memberships.first?.created,
                         Constant.iso8601DateFormatter.date(from: "2019-09-29T13:07:57.589822Z"))
          XCTAssertTrue(firstSpace.isEqual(payload.memberships.first?.space))

          XCTAssertEqual(payload.memberships.last?.id, "LastSpace")
          XCTAssertEqual(payload.memberships.last?.customType, ["starred": .init(boolValue: true)])
          XCTAssertEqual(payload.memberships.last?.eTag, "LastETag")
          XCTAssertEqual(payload.memberships.last?.created,
                         Constant.iso8601DateFormatter.date(from: "2019-09-29T19:13:43.964451Z"))
          XCTAssertNil(payload.memberships.last?.space)

        case let .failure(error):
          XCTFail("Update Memberships request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // swiftlint:disable:next file_length
}
