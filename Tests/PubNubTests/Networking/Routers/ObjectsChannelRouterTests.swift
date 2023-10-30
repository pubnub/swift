//
//  ObjectsChannelRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class ObjectsChannelRouterTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString", userId: UUID().uuidString)
  let testChannel = PubNubChannelMetadataBase(name: "TestChannel")
  let invalidUser = PubNubChannelMetadataBase(name: "")
}

// MARK: - All Tests

extension ObjectsChannelRouterTests {
  func testAll_Router() {
    let router = ObjectsChannelRouter(
      .all(customFields: true, totalCount: true, filter: "filter",
           sort: ["sort"], limit: 100, start: "start", end: "end"),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Get All Metadata for Channels")
    XCTAssertEqual(router.category, "Get All Metadata for Channels")
    XCTAssertEqual(router.service, .objects)
  }

  func testAll_Router_ValidationError() {
    let router = ObjectsChannelRouter(
      .all(customFields: true, totalCount: true, filter: "filter",
           sort: ["sort"], limit: 100, start: "start", end: "end"),
      configuration: config
    )

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testAll_Success() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_channel_all_success"]),
          let firstDate = DateFormatter.iso8601.date(from: "2019-08-18T11:25:55.44977Z"),
          let lastDate = DateFormatter.iso8601.date(from: "2019-08-18T11:25:59.326105Z")
    else {
      return XCTFail("Could not create mock url session")
    }

    let firstTest = PubNubChannelMetadataBase(
      metadataId: "WGWPWPJBRJ", name: "HNNCTGRURF",
      updated: firstDate, eTag: "AY/Cz7edr46A3wE"
    )
    let lastTest = PubNubChannelMetadataBase(
      metadataId: "OSPULBRLGN", name: "VDUVIGRMWF", channelDescription: "Test Description",
      custom: ["info": "JMGXDNYF"],
      updated: lastDate, eTag: "AeH55Y3T0a78Ew"
    )
    let page = PubNubHashedPageBase(start: "NextPage", end: "PrevPage", totalCount: 2)

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.allChannelMetadata { result in
      switch result {
      case let .success((metadataObjects, nextPage)):
        XCTAssertEqual(metadataObjects.compactMap { try? $0.transcode() }, [firstTest, lastTest])
        XCTAssertEqual(try? nextPage?.transcode(), page)
      case let .failure(error):
        XCTFail("Fetch All request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testAll_Success_empty() {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_channel_all_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    let testPage = PubNubHashedPageBase(totalCount: 0)

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.allChannelMetadata { result in
      switch result {
      case let .success((metadataObjects, nextPage)):
        XCTAssertTrue(metadataObjects.isEmpty)
        XCTAssertEqual(try? nextPage?.transcode(), testPage)
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

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.allChannelMetadata { result in
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

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.allChannelMetadata { result in
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

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.allChannelMetadata { result in
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

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.allChannelMetadata { result in
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

extension ObjectsChannelRouterTests {
  func testFetch_Router() {
    let router = ObjectsChannelRouter(.fetch(metadataId: "OtherUser", customFields: true),
                                      configuration: config)

    XCTAssertEqual(router.endpoint.description, "Fetch Metadata for a Channel")
    XCTAssertEqual(router.category, "Fetch Metadata for a Channel")
    XCTAssertEqual(router.service, .objects)
  }

  func testFetch_Router_ValidationError() {
    let router = ObjectsChannelRouter(.fetch(metadataId: "", customFields: true), configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testFetch_Success() {
    let expectation = self.expectation(description: "Fetch Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_channel_fetch_success"]),
          let firstDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z")
    else {
      return XCTFail("Could not create mock url session")
    }

    let testObject = PubNubChannelMetadataBase(
      metadataId: "TestChannel", name: "Test Channel",
      type: "Test Type", status: "Test Status", channelDescription: "Test Description",
      custom: ["string": "String", "int": 1, "double": 1.1, "bool": true],
      updated: firstDate, eTag: "AfuB8q7/s+qCwAE"
    )

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.fetch(channel: "TestChannel") { result in
      switch result {
      case let .success(responseObject):
        XCTAssertEqual(try? responseObject.transcode(), testObject)
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

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.fetch(channel: "TestChannel") { result in
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

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.fetch(channel: "TestChannel") { result in
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

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.fetch(channel: "TestChannel") { result in
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

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.fetch(channel: "TestChannel") { result in
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

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.fetch(channel: "TestChannel") { result in
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

// MARK: - Set Tests

extension ObjectsChannelRouterTests {
  func testSet_Router() {
    let router = ObjectsChannelRouter(.set(metadata: testChannel, customFields: true), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Set Metadata for a Channel")
    XCTAssertEqual(router.category, "Set Metadata for a Channel")
    XCTAssertEqual(router.service, .objects)
  }

  func testSet_Router_ValidationError() {
    let router = ObjectsChannelRouter(.set(metadata: invalidUser, customFields: true), configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testSet_Success() {
    let expectation = self.expectation(description: "Create Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_channel_fetch_success"]),
          let firstDate = DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z")
    else {
      return XCTFail("Could not create mock url session")
    }

    let testObject = PubNubChannelMetadataBase(
      metadataId: "TestChannel", name: "Test Channel",
      type: "Test Type", status: "Test Status", channelDescription: "Test Description",
      custom: ["string": "String", "int": 1, "double": 1.1, "bool": true],
      updated: firstDate, eTag: "AfuB8q7/s+qCwAE"
    )

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.set(channel: testChannel) { result in
      switch result {
      case let .success(responseObject):
        XCTAssertEqual(try? responseObject.transcode(), testObject)
      case let .failure(error):
        XCTFail("Create request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testSet_error_400() {
    let expectation = self.expectation(description: "400 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_400"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.set(channel: testChannel) { result in
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

  func testSet_error_403() {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_403"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.set(channel: testChannel) { result in
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

  func testSet_error_409() {
    let expectation = self.expectation(description: "409 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_409"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.set(channel: testChannel) { result in
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

  func testSet_error_415() {
    let expectation = self.expectation(description: "415 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_415"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.set(channel: testChannel) { result in
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

  func testSet_error_429() {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_429"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.set(channel: testChannel) { result in
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

  func testSet_error_500() {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_500"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.set(channel: testChannel) { result in
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

  func testSet_error_503() {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_503"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.set(channel: testChannel) { result in
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

// MARK: - Remove Tests

extension ObjectsChannelRouterTests {
  func testRemove_Router() {
    let router = ObjectsChannelRouter(.remove(metadataId: "TestChannel"), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Remove Metadata from a Channel")
    XCTAssertEqual(router.category, "Remove Metadata from a Channel")
    XCTAssertEqual(router.service, .objects)
  }

  func testRemove_Router_ValidationError() {
    let router = ObjectsChannelRouter(.remove(metadataId: ""), configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError,
                      PubNubError(.invalidEndpointType, router: router))
  }

  func testRemove_Success() {
    let expectation = self.expectation(description: "Delete Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_channel_remove_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.remove(channel: "TestChannel") { result in
      switch result {
      case let .success(metadataId):
        XCTAssertEqual(metadataId, "TestChannel")
      case let .failure(error):
        XCTFail("Delete request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testRemove_error_403() {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_403"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.remove(channel: "TestChannel") { result in
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

  func testRemove_error_412() {
    let expectation = self.expectation(description: "412 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_412"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.remove(channel: "TestChannel") { result in
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

  func testRemove_error_429() {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_429"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.remove(channel: "TestChannel") { result in
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

  func testRemove_error_500() {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_500"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.remove(channel: "TestChannel") { result in
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

  func testRemove_error_503() {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: ["objects_error_503"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.remove(channel: "TestChannel") { result in
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

  // swiftlint:disable:next file_length
}
