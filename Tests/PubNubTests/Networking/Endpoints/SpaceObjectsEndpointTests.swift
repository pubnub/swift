//
//  SpaceObjectsEndpointTests.swift
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
final class SpaceObjectsEndpointTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")
  let fetchAllSpaces = Endpoint.objectsSpaceFetchAll(include: nil, limit: nil, start: nil, end: nil, count: nil)
  let fetchSpace = Endpoint.objectsSpaceFetch(spaceID: "SomeSpace", include: nil)
  let testSpace = SpaceObject(name: "TestSpace")
  let invalidSpace = SpaceObject(name: "")

  // MARK: - Fetch All Tests

  func testFetchAll_Endpoint() {
    let endpoint = Endpoint.objectsSpaceFetchAll(include: .custom, limit: 100, start: "Start", end: "End", count: true)

    XCTAssertEqual(endpoint.description, "Fetch All Space Objects")
    XCTAssertEqual(endpoint.category, .objectsSpaceFetchAll)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testFetchAll_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsSpaceFetchAll(include: .custom, limit: 100, start: "Start", end: "End", count: true)

    XCTAssertEqual(endpoint.associatedValue["include"] as? Endpoint.IncludeField, .custom)
    XCTAssertEqual(endpoint.associatedValue["limit"] as? Int, 100)
    XCTAssertEqual(endpoint.associatedValue["start"] as? String, "Start")
    XCTAssertEqual(endpoint.associatedValue["end"] as? String, "End")
    XCTAssertEqual(endpoint.associatedValue["count"] as? Bool, true)
  }

  func testFetchAll_Success() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetchAll_success"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-08-18T11:25:55.44977Z"),
      let lastCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-08-18T11:25:59.326105Z") else {
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .forbidden))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .tooManyRequests))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .internalServiceError))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .serviceUnavailable))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Fetch Tests

  func testFetch_Endpoint() {
    let endpoint = Endpoint.objectsSpaceFetch(spaceID: "OtherSpace", include: .custom)

    XCTAssertEqual(endpoint.description, "Fetch Space Object")
    XCTAssertEqual(endpoint.category, .objectsSpaceFetch)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testFetch_Endpoint_ValidationError() {
    let endpoint = Endpoint.objectsSpaceFetch(spaceID: "", include: .custom)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testFetch_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsSpaceFetch(spaceID: "OtherSpace", include: .custom)

    XCTAssertEqual(endpoint.associatedValue["spaceID"] as? String, "OtherSpace")
    XCTAssertEqual(endpoint.associatedValue["include"] as? Endpoint.IncludeField, .custom)
  }

  func testFetch_Success() {
    let expectation = self.expectation(description: "Fetch Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetch_success"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
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
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertTrue(firstSpace.isEqual(payload.space))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .forbidden))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .resourceNotFound))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .tooManyRequests))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .internalServiceError))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .serviceUnavailable))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Create Tests

  func testCreate_Endpoint() {
    let endpoint = Endpoint.objectsSpaceCreate(space: testSpace, include: .custom)

    XCTAssertEqual(endpoint.description, "Create Space Object")
    XCTAssertEqual(endpoint.category, .objectsSpaceCreate)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testCreate_Endpoint_ValidationError() {
    let endpoint = Endpoint.objectsSpaceCreate(space: invalidSpace, include: .custom)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testCreate_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsSpaceCreate(space: testSpace, include: .custom)

    XCTAssertTrue(testSpace.isEqual(endpoint.associatedValue["space"] as? PubNubSpace))
    XCTAssertEqual(endpoint.associatedValue["include"] as? Endpoint.IncludeField, .custom)
  }

  func testCreate_Success() {
    let expectation = self.expectation(description: "Create Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetch_success"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
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
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertTrue(firstSpace.isEqual(payload.space))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .badRequest))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .forbidden))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .conflict))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .unsupportedType))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .tooManyRequests))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .internalServiceError))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .create(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .serviceUnavailable))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Update Tests

  func testUpdate_Endpoint() {
    let endpoint = Endpoint.objectsSpaceUpdate(space: testSpace, include: .custom)

    XCTAssertEqual(endpoint.description, "Update Space Object")
    XCTAssertEqual(endpoint.category, .objectsSpaceUpdate)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testUpdate_Endpoint_ValidationError() {
    let endpoint = Endpoint.objectsSpaceUpdate(space: invalidSpace, include: .custom)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testUpdate_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsSpaceUpdate(space: testSpace, include: .custom)

    XCTAssertTrue(testSpace.isEqual(endpoint.associatedValue["space"] as? PubNubSpace))
    XCTAssertEqual(endpoint.associatedValue["include"] as? Endpoint.IncludeField, .custom)
  }

  func testUpdate_Success() {
    let expectation = self.expectation(description: "Update Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetch_success"]),
      let firstCreatedDate = Constant.iso8601DateFormatter.date(from: "2019-09-03T02:47:38.609257Z") else {
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
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertTrue(firstSpace.isEqual(payload.space))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .badRequest))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .forbidden))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .conflict))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .preconditionFailed))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .unsupportedType))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .tooManyRequests))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .internalServiceError))
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

    let firstSpace = SpaceObject(name: "Test Space", id: "TestSpace",
                                 created: firstCreatedDate,
                                 eTag: "AfuB8q7/s+qCwAE")

    PubNub(configuration: config, session: sessions.session)
      .update(space: firstSpace, include: .custom) { result in
        switch result {
        case .success:
          XCTFail("Request should fail.")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .serviceUnavailable))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Delete Tests

  func testDelete_Endpoint() {
    let endpoint = Endpoint.objectsSpaceDelete(spaceID: "TestSpace", include: .custom)

    XCTAssertEqual(endpoint.description, "Delete Space Object")
    XCTAssertEqual(endpoint.category, .objectsSpaceDelete)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testDelete_Endpoint_ValidationError() {
    let endpoint = Endpoint.objectsSpaceFetch(spaceID: "", include: .custom)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testDelete_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsSpaceDelete(spaceID: "TestSpace", include: .custom)

    XCTAssertEqual(endpoint.associatedValue["spaceID"] as? String, "TestSpace")
    XCTAssertEqual(endpoint.associatedValue["include"] as? Endpoint.IncludeField, .custom)
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .forbidden))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .preconditionFailed))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .tooManyRequests))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .internalServiceError))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .serviceUnavailable))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Fetch Memberships Tests

  func testMembershipFetch_Endpoint() {
    let endpoint = Endpoint.objectsSpaceMemberships(spaceID: "TestSpace",
                                                    include: [],
                                                    limit: nil, start: nil, end: nil, count: nil)

    XCTAssertEqual(endpoint.description, "Fetch Space's Memberships")
    XCTAssertEqual(endpoint.category, .objectsSpaceMemberships)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testMembershipFetch_Endpoint_ValidationError() {
    let endpoint = Endpoint.objectsSpaceMemberships(spaceID: "",
                                                    include: [],
                                                    limit: nil, start: nil, end: nil, count: nil)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testMembershipFetch_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsSpaceMemberships(spaceID: "TestSpace",
                                                    include: [.customSpace],
                                                    limit: 100, start: "Start", end: "End", count: true)

    XCTAssertEqual(endpoint.associatedValue.count, 6)
    XCTAssertEqual(endpoint.associatedValue["spaceID"] as? String, "TestSpace")
    XCTAssertEqual(endpoint.associatedValue["include"] as? [Endpoint.IncludeField], [.customSpace])
    XCTAssertEqual(endpoint.associatedValue["limit"] as? Int, 100)
    XCTAssertEqual(endpoint.associatedValue["start"] as? String, "Start")
    XCTAssertEqual(endpoint.associatedValue["end"] as? String, "End")
    XCTAssertEqual(endpoint.associatedValue["count"] as? Bool, true)
  }

  func testMembershipFetch_Success() {
    let expectation = self.expectation(description: "Fetch Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetchMemberships_success"]),
      let spaceDate = Constant.iso8601DateFormatter.date(from: "2019-09-29T13:07:45.807503Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "First User", id: "FirstUser", created: spaceDate, eTag: "UserETag")

    PubNub(configuration: config, session: sessions.session)
      .fetchMemberships(spaceID: "TestSpace") { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertEqual(payload.next, "NextPage")
          XCTAssertEqual(payload.totalCount, 2)

          XCTAssertEqual(payload.memberships.first?.id, firstUser.id)
          XCTAssertEqual(payload.memberships.first?.customType.isEmpty, true)
          XCTAssertEqual(payload.memberships.first?.eTag, "FirstETag")
          XCTAssertEqual(payload.memberships.first?.created,
                         Constant.iso8601DateFormatter.date(from: "2019-09-29T13:07:57.589822Z"))
          XCTAssertTrue(firstUser.isEqual(payload.memberships.first?.user))

          XCTAssertEqual(payload.memberships.last?.id, "LastUser")
          XCTAssertEqual(payload.memberships.last?.customType, ["starred": .init(boolValue: true)])
          XCTAssertEqual(payload.memberships.last?.eTag, "LastETag")
          XCTAssertEqual(payload.memberships.last?.created,
                         Constant.iso8601DateFormatter.date(from: "2019-09-29T19:13:43.964451Z"))
          XCTAssertNil(payload.memberships.last?.user)

        case let .failure(error):
          XCTFail("Fetch Memberships request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testMembershipFetch_Success_Empty() {
    let expectation = self.expectation(description: "Fetch Memberships Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetchAll_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchMemberships(spaceID: "TestSpace") { result in
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
    let endpoint = Endpoint.objectsSpaceMembershipsUpdate(spaceID: "TestSpace",
                                                          add: [], update: [], remove: [],
                                                          include: [],
                                                          limit: nil, start: nil, end: nil, count: nil)

    XCTAssertEqual(endpoint.description, "Update Space's Memberships")
    XCTAssertEqual(endpoint.category, .objectsSpaceMembershipsUpdate)
    XCTAssertEqual(endpoint.operationCategory, .objects)
    XCTAssertNil(endpoint.validationError)
  }

  func testMembershipUpdate_Endpoint_ValidationError() {
    let endpoint = Endpoint.objectsSpaceMembershipsUpdate(spaceID: "",
                                                          add: [], update: [], remove: [],
                                                          include: [],
                                                          limit: nil, start: nil, end: nil, count: nil)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testMembershipUpdate_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.objectsSpaceMembershipsUpdate(spaceID: "TestSpace",
                                                          add: [], update: [], remove: [],
                                                          include: [.customSpace],
                                                          limit: 100, start: "Start", end: "End", count: true)

    XCTAssertEqual(endpoint.associatedValue.count, 9)
    XCTAssertEqual(endpoint.associatedValue["spaceID"] as? String, "TestSpace")
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

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_spaces_fetchMemberships_success"]),
      let spaceDate = Constant.iso8601DateFormatter.date(from: "2019-09-29T13:07:45.807503Z") else {
      return XCTFail("Could not create mock url session")
    }

    let firstUser = UserObject(name: "First User",
                               id: "FirstUser",
                               created: spaceDate,
                               eTag: "UserETag")

    PubNub(configuration: config, session: sessions.session)
      .updateMemberships(spaceID: "TestSpace", adding: [firstUser]) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.status, 200)
          XCTAssertEqual(payload.next, "NextPage")
          XCTAssertEqual(payload.totalCount, 2)

          XCTAssertEqual(payload.memberships.first?.id, firstUser.id)
          XCTAssertEqual(payload.memberships.first?.customType.isEmpty, true)
          XCTAssertEqual(payload.memberships.first?.eTag, "FirstETag")
          XCTAssertEqual(payload.memberships.first?.created,
                         Constant.iso8601DateFormatter.date(from: "2019-09-29T13:07:57.589822Z"))
          XCTAssertTrue(firstUser.isEqual(payload.memberships.first?.user))

          XCTAssertEqual(payload.memberships.last?.id, "LastUser")
          XCTAssertEqual(payload.memberships.last?.customType, ["starred": .init(boolValue: true)])
          XCTAssertEqual(payload.memberships.last?.eTag, "LastETag")
          XCTAssertEqual(payload.memberships.last?.created,
                         Constant.iso8601DateFormatter.date(from: "2019-09-29T19:13:43.964451Z"))
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
