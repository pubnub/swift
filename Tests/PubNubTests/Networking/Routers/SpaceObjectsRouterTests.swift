//
//  SpaceObjectsRouterTests.swift
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
final class SpaceObjectsRouterTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")
  let testSpace = SpaceObject(name: "TestSpace")
  let invalidSpace = SpaceObject(name: "")
}

// MARK: - Fetch All Tests

extension SpaceObjectsRouterTests {
  func testFetchAll_Router() {
    let router = SpaceObjectsRouter(.fetchAll(include: .custom, limit: 100, start: "Start", end: "End", count: true), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Fetch All Space Objects")
    XCTAssertEqual(router.category, "Fetch All Space Objects")
    XCTAssertEqual(router.service, .objects)
  }

  func testFetchAll_Router_ValidationError() {
    let router = SpaceObjectsRouter(.fetchAll(include: .custom, limit: 100, start: "Start", end: "End", count: true), configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))
  }

  func testFetchAll_Success() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetchAll_success"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-08-18T11:25:55.44977Z"),
      let lastCreatedDate = DateFormatter.iso8601.date(from: "2019-08-18T11:25:59.326105Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "HNNCTGRURF", id: "WGWPWPJBRJ",
                                 created: firstCreatedDate,
                                 eTag: "AY/Cz7edr46A3wE")
    let lastSpace = SpaceObject(name: "VDUVIGRMWF", id: "OSPULBRLGN",
                                spaceDescription: "Test Description",
                                custom: ["info": "JMGXDNYF"],
                                created: lastCreatedDate,
                                eTag: "AeH55Y3T0a78Ew")

    PubNub(configuration: config, session: sessions.session)
      .fetchSpaces(include: .custom) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.next, "NextPage")
          XCTAssertEqual(payload.prev, "PrevPage")
          XCTAssertEqual(payload.status, 200)
          XCTAssertEqual(payload.totalCount, 2)

          XCTAssertTrue(firstSpace.isEqual(payload.spaces.first))
          XCTAssertTrue(lastSpace.isEqual(payload.spaces.last))

        case let .failure(error):
          XCTFail("Fetch All request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchAll_Success_empty() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetchAll_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchSpaces(include: .custom) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertEqual(payload.totalCount, 0)
          XCTAssertTrue(payload.spaces.isEmpty)
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
      .fetchSpaces(include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.forbidden))
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
      .fetchSpaces(include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.tooManyRequests))
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
      .fetchSpaces(include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.internalServiceError))
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
      .fetchSpaces(include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.serviceUnavailable))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Fetch Tests

extension SpaceObjectsRouterTests {
  func testFetch_Router() {
    let router = SpaceObjectsRouter(.fetch(spaceID: "OtherSpace", include: .custom), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Fetch Space Object")
    XCTAssertEqual(router.category, "Fetch Space Object")
    XCTAssertEqual(router.service, .objects)
  }

  func testFetch_Router_ValidationError() {
    let router = SpaceObjectsRouter(.fetch(spaceID: "", include: .custom), configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testFetch_Success() {
    let expectation = self.expectation(description: "Fetch Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetch_success"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 spaceDescription: "Test Description",
                                 custom: ["string": "String", "int": 1, "double": 1.1, "bool": true],
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .fetch(spaceID: "TestSpace") { result in
        switch result {
        case let .success(space):
          XCTAssertTrue(firstSpace.isEqual(space))
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
      .fetch(spaceID: "TestSpace") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.forbidden))
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
      .fetch(spaceID: "TestSpace") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.resourceNotFound))
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
      .fetch(spaceID: "TestSpace") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.tooManyRequests))
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
      .fetch(spaceID: "TestSpace") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.internalServiceError))
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
      .fetch(spaceID: "TestSpace") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.serviceUnavailable))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Create Tests

extension SpaceObjectsRouterTests {
  func testCreate_Router() {
    let router = SpaceObjectsRouter(.create(space: testSpace, include: .custom), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Create Space Object")
    XCTAssertEqual(router.category, "Create Space Object")
    XCTAssertEqual(router.service, .objects)
  }

  func testCreate_Router_ValidationError() {
    let router = SpaceObjectsRouter(.create(space: invalidSpace, include: .custom), configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testCreate_Success() {
    let expectation = self.expectation(description: "Create Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetch_success"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 spaceDescription: "Test Description",
                                 custom: ["string": "String", "int": 1, "double": 1.1, "bool": true],
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case let .success(space):
          XCTAssertTrue(firstSpace.isEqual(space))
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
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.badRequest))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_403() {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_403"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.forbidden))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_409() {
    let expectation = self.expectation(description: "409 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_409"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.conflict))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_415() {
    let expectation = self.expectation(description: "415 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_415"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.unsupportedType))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_429() {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_429"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.tooManyRequests))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_500() {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_500"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.internalServiceError))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCreate_error_503() {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_503"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.serviceUnavailable))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Update Tests

extension SpaceObjectsRouterTests {
  func testUpdate_Router() {
    let router = SpaceObjectsRouter(.update(space: testSpace, include: .custom), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Update Space Object")
    XCTAssertEqual(router.category, "Update Space Object")
    XCTAssertEqual(router.service, .objects)
  }

  func testUpdate_Router_ValidationError() {
    let router = SpaceObjectsRouter(.update(space: invalidSpace, include: .custom), configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testUpdate_Success() {
    let expectation = self.expectation(description: "Update Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetch_success"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 spaceDescription: "Test Description",
                                 custom: ["string": "String", "int": 1, "double": 1.1, "bool": true],
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace) { result in
        switch result {
        case let .success(space):
          XCTAssertTrue(firstSpace.isEqual(space))
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
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.badRequest))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_403() {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_403"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.forbidden))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_404() {
    let expectation = self.expectation(description: "409 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_409"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.conflict))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_412() {
    let expectation = self.expectation(description: "412 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_412"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.preconditionFailed))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_415() {
    let expectation = self.expectation(description: "415 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_415"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.unsupportedType))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_429() {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_429"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.tooManyRequests))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_500() {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_500"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.internalServiceError))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdate_error_503() {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_503"]),
      let firstCreatedDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.serviceUnavailable))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Delete Tests

extension SpaceObjectsRouterTests {
  func testDelete_Router() {
    let router = SpaceObjectsRouter(.delete(spaceID: "TestSpace"), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Delete Space Object")
    XCTAssertEqual(router.category, "Delete Space Object")
    XCTAssertEqual(router.service, .objects)
  }

  func testDelete_Router_ValidationError() {
    let router = SpaceObjectsRouter(.delete(spaceID: ""), configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testDelete_Success() {
    let expectation = self.expectation(description: "Delete Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetch_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .delete(spaceID: "TestSpace") { result in
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
      .delete(spaceID: "TestSpace") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.forbidden))
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
      .delete(spaceID: "TestSpace") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.preconditionFailed))
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
      .delete(spaceID: "TestSpace") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.tooManyRequests))
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
      .delete(spaceID: "TestSpace") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.internalServiceError))
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
      .delete(spaceID: "TestSpace") { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(.serviceUnavailable))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Fetch Memberships Tests

extension SpaceObjectsRouterTests {
  func testFetchMembership_Router() {
    let router = SpaceObjectsRouter(
      .fetchMembers(spaceID: "TestSpace", include: [], limit: nil, start: nil, end: nil, count: nil),
      configuration: config)

    XCTAssertEqual(router.endpoint.description, "Fetch Space's Members")
    XCTAssertEqual(router.category, "Fetch Space's Members")
    XCTAssertEqual(router.service, .objects)
  }

  func testFetchMembership_Router_ValidationError() {
    let router = SpaceObjectsRouter(
      .fetchMembers(spaceID: "", include: [], limit: nil, start: nil, end: nil, count: nil),
      configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testFetchMembership_Success() {
    let expectation = self.expectation(description: "Fetch Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetchMemberships_success"]),
      let spaceDate = DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "First User", id: "FirstUser", created: spaceDate, eTag: "UserETag")

    PubNub(configuration: config, session: sessions.session)
      .fetchMembers(spaceID: "TestSpace") { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertEqual(payload.next, "NextPage")
          XCTAssertEqual(payload.totalCount, 2)

          XCTAssertEqual(payload.memberships.first?.id, firstUser.id)
          XCTAssertEqual(payload.memberships.first?.customType.isEmpty, true)
          XCTAssertEqual(payload.memberships.first?.eTag, "FirstETag")
          XCTAssertEqual(payload.memberships.first?.created,
                         DateFormatter.iso8601.date(from: "2019-09-29T13:07:57.589822Z"))
          XCTAssertTrue(firstUser.isEqual(payload.memberships.first?.user))

          XCTAssertEqual(payload.memberships.last?.id, "LastUser")
          XCTAssertEqual(payload.memberships.last?.customType, ["starred": .init(boolValue: true)])
          XCTAssertEqual(payload.memberships.last?.eTag, "LastETag")
          XCTAssertEqual(payload.memberships.last?.created,
                         DateFormatter.iso8601.date(from: "2019-09-29T19:13:43.964451Z"))
          XCTAssertNil(payload.memberships.last?.user)

        case let .failure(error):
          XCTFail("Fetch Memberships request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchMembership_Success_Empty() {
    let expectation = self.expectation(description: "Fetch Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetchAll_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchMembers(spaceID: "TestSpace") { result in
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
}

// MARK: - Update Memberships Tests

extension SpaceObjectsRouterTests {
  func testMembershipUpdate_Router() {
    let router = SpaceObjectsRouter(
      .modifyMembers(spaceID: "TestSpace",
                     adding: [], updating: [], removing: [], include: [],
                     limit: nil, start: nil, end: nil, count: nil),
      configuration: config)

    XCTAssertEqual(router.endpoint.description, "Modify Space's Members")
    XCTAssertEqual(router.category, "Modify Space's Members")
    XCTAssertEqual(router.service, .objects)
  }

  func testMembershipUpdate_Router_ValidationError() {
    let router = SpaceObjectsRouter(
      .modifyMembers(spaceID: "TestSpace",
                     adding: [], updating: [], removing: [], include: [],
                     limit: nil, start: nil, end: nil, count: nil),
      configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testMembershipUpdate_Success() {
    let expectation = self.expectation(description: "Update Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetchMemberships_success"]),
      let spaceDate = DateFormatter.iso8601.date(from: "2019-09-29T13:07:45.807503Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "First User",
                               id: "FirstUser",
                               created: spaceDate,
                               eTag: "UserETag")

    PubNub(configuration: config, session: sessions.session)
      .modifyMembers(spaceID: "TestSpace", adding: [firstUser]) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertEqual(payload.next, "NextPage")
          XCTAssertEqual(payload.totalCount, 2)

          XCTAssertEqual(payload.memberships.first?.id, firstUser.id)
          XCTAssertEqual(payload.memberships.first?.customType.isEmpty, true)
          XCTAssertEqual(payload.memberships.first?.eTag, "FirstETag")
          XCTAssertEqual(payload.memberships.first?.created,
                         DateFormatter.iso8601.date(from: "2019-09-29T13:07:57.589822Z"))
          XCTAssertTrue(firstUser.isEqual(payload.memberships.first?.user))

          XCTAssertEqual(payload.memberships.last?.id, "LastUser")
          XCTAssertEqual(payload.memberships.last?.customType, ["starred": .init(boolValue: true)])
          XCTAssertEqual(payload.memberships.last?.eTag, "LastETag")
          XCTAssertEqual(payload.memberships.last?.created,
                         DateFormatter.iso8601.date(from: "2019-09-29T19:13:43.964451Z"))
          XCTAssertNil(payload.memberships.last?.user)

        case let .failure(error):
          XCTFail("Update Memberships request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // swiftlint:disable:next file_length
}
