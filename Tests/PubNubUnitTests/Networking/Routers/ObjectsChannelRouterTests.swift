//
//  ObjectsChannelRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

final class ObjectsChannelRouterTests: XCTestCase {
  let testChannel = PubNubChannelMetadataBase(name: "TestChannel")
  let invalidUser = PubNubChannelMetadataBase(name: "")
}

// MARK: - All Tests

extension ObjectsChannelRouterTests {
  func test_FetchAllChannels_RouterConfiguration_ReturnsCorrectEndpoint() {
    let config = TestPubNubFactory.makeConfig()

    let router = ObjectsChannelRouter(
      .all(
        include: [.custom], totalCount: true, filter: "filter",
        sort: ["sort"], limit: 100, start: "start", end: "end"
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Get All Metadata for Channels")
    XCTAssertEqual(router.category, "Get All Metadata for Channels")
    XCTAssertEqual(router.service, .objects)
  }

  func test_FetchAllChannels_RouterValidation_ReturnsNoEndpointTypeError() {
    let config = TestPubNubFactory.makeConfig()

    let router = ObjectsChannelRouter(
      .all(
        include: [.custom], totalCount: true, filter: "filter",
        sort: ["sort"], limit: 100, start: "start", end: "end"
      ),
      configuration: config
    )

    XCTAssertNotEqual(
      router.validationError?.pubNubError,
      PubNubError(.invalidEndpointType, router: router)
    )
  }

  func test_FetchAllChannels_WithValidConfig_ReturnsChannels() throws {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")

    let sessions = try MockURLSession.mockSession(for: ["objects_channel_all_success"])
    let firstDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-08-18T11:25:55.44977Z"))
    let lastDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-08-18T11:25:59.326105Z"))

    let firstTest = PubNubChannelMetadataBase(
      metadataId: "WGWPWPJBRJ", name: "HNNCTGRURF",
      updated: firstDate, eTag: "AY/Cz7edr46A3wE"
    )
    let lastTest = PubNubChannelMetadataBase(
      metadataId: "OSPULBRLGN", name: "VDUVIGRMWF", channelDescription: "Test Description",
      custom: ["info": "JMGXDNYF"],
      updated: lastDate, eTag: "AeH55Y3T0a78Ew"
    )
    let page = PubNubHashedPageBase(
      start: "NextPage",
      end: "PrevPage",
      totalCount: 2
    )

    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_FetchAllChannels_WhenEmpty_ReturnsEmptyList() throws {
    let expectation = self.expectation(description: "Fetch All Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_channel_all_success_empty"])

    let testPage = PubNubHashedPageBase(totalCount: 0)
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_FetchAllChannels_WhenForbidden_ReturnsForbiddenError() throws {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_403"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_FetchAllChannels_WhenTooManyRequests_ReturnsTooManyRequestsError() throws {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_429"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_FetchAllChannels_WhenInternalServerError_ReturnsInternalServiceError() throws {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_500"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_FetchAllChannels_WhenServiceUnavailable_ReturnsServiceUnavailableError() throws {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_503"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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
  func test_FetchChannel_RouterConfiguration_ReturnsCorrectEndpoint() {
    let config = TestPubNubFactory.makeConfig()

    let router = ObjectsChannelRouter(
      .fetch(metadataId: "OtherUser", include: [.custom]),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Fetch Metadata for a Channel")
    XCTAssertEqual(router.category, "Fetch Metadata for a Channel")
    XCTAssertEqual(router.service, .objects)
  }

  func test_FetchChannel_RouterValidationWithEmptyId_ReturnsNoEndpointTypeError() {
    let config = TestPubNubFactory.makeConfig()

    let router = ObjectsChannelRouter(
      .fetch(metadataId: "", include: [.custom]),
      configuration: config
    )

    XCTAssertNotEqual(
      router.validationError?.pubNubError,
      PubNubError(.invalidEndpointType, router: router)
    )
  }

  func test_FetchChannel_WithValidConfig_ReturnsChannel() throws {
    let expectation = self.expectation(description: "Fetch Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_channel_fetch_success"])
    let firstDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z"))

    let testObject = PubNubChannelMetadataBase(
      metadataId: "TestChannel", name: "Test Channel",
      type: "Test Type", status: "Test Status", channelDescription: "Test Description",
      custom: ["string": "String", "int": 1, "double": 1.1, "bool": true],
      updated: firstDate, eTag: "AfuB8q7/s+qCwAE"
    )

    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.fetchChannelMetadata("TestChannel") { result in
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

  func test_FetchChannel_WhenForbidden_ReturnsForbiddenError() throws {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_403"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.fetchChannelMetadata("TestChannel") { result in
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

  func test_FetchChannel_WhenNotFound_ReturnsResourceNotFoundError() throws {
    let expectation = self.expectation(description: "404 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_404"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.fetchChannelMetadata("TestChannel") { result in
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

  func test_FetchChannel_WhenTooManyRequests_ReturnsTooManyRequestsError() throws {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_429"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.fetchChannelMetadata("TestChannel") { result in
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

  func test_FetchChannel_WhenInternalServerError_ReturnsInternalServiceError() throws {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_500"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.fetchChannelMetadata("TestChannel") { result in
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

  func test_FetchChannel_WhenServiceUnavailable_ReturnsServiceUnavailableError() throws {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_503"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.fetchChannelMetadata("TestChannel") { result in
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
  func test_SetChannel_RouterConfiguration_ReturnsCorrectEndpoint() {
    let config = TestPubNubFactory.makeConfig()

    let router = ObjectsChannelRouter(
      .set(metadata: testChannel, include: [.custom]),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Set Metadata for a Channel")
    XCTAssertEqual(router.category, "Set Metadata for a Channel")
    XCTAssertEqual(router.service, .objects)
  }

  func test_SetChannel_RouterValidationWithInvalidChannel_ReturnsNoEndpointTypeError() {
    let config = TestPubNubFactory.makeConfig()

    let router = ObjectsChannelRouter(
      .set(metadata: invalidUser, include: [.custom]),
      configuration: config
    )

    XCTAssertNotEqual(
      router.validationError?.pubNubError,
      PubNubError(.invalidEndpointType, router: router)
    )
  }

  func test_SetChannel_WithValidConfig_ReturnsSuccess() throws {
    let expectation = self.expectation(description: "Create Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_channel_fetch_success"])
    let firstDate = try XCTUnwrap(DateFormatter.iso8601.date(from: "2019-09-03T02:47:38.609257Z"))

    let testObject = PubNubChannelMetadataBase(
      metadataId: "TestChannel", name: "Test Channel",
      type: "Test Type", status: "Test Status", channelDescription: "Test Description",
      custom: ["string": "String", "int": 1, "double": 1.1, "bool": true],
      updated: firstDate, eTag: "AfuB8q7/s+qCwAE"
    )

    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.setChannelMetadata(testChannel) { result in
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

  func test_SetChannel_WhenBadRequest_ReturnsBadRequestError() throws {
    let expectation = self.expectation(description: "400 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_400"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.setChannelMetadata(testChannel) { result in
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

  func test_SetChannel_WhenForbidden_ReturnsForbiddenError() throws {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_403"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.setChannelMetadata(testChannel) { result in
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

  func test_SetChannel_WhenConflict_ReturnsConflictError() throws {
    let expectation = self.expectation(description: "409 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_409"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.setChannelMetadata(testChannel) { result in
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

  func test_SetChannel_WhenUnsupportedType_ReturnsUnsupportedTypeError() throws {
    let expectation = self.expectation(description: "415 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_415"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.setChannelMetadata(testChannel) { result in
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

  func test_SetChannel_WhenTooManyRequests_ReturnsTooManyRequestsError() throws {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_429"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.setChannelMetadata(testChannel) { result in
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

  func test_SetChannel_WhenInternalServerError_ReturnsInternalServiceError() throws {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_500"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.setChannelMetadata(testChannel) { result in
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

  func test_SetChannel_WhenServiceUnavailable_ReturnsServiceUnavailableError() throws {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_503"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.setChannelMetadata(testChannel) { result in
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
  func test_RemoveChannel_RouterConfiguration_ReturnsCorrectEndpoint() {
    let config = TestPubNubFactory.makeConfig()
    let router = ObjectsChannelRouter(.remove(metadataId: "TestChannel"), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Remove Metadata from a Channel")
    XCTAssertEqual(router.category, "Remove Metadata from a Channel")
    XCTAssertEqual(router.service, .objects)
  }

  func test_RemoveChannel_RouterValidationWithEmptyId_ReturnsNoEndpointTypeError() {
    let config = TestPubNubFactory.makeConfig()
    let router = ObjectsChannelRouter(.remove(metadataId: ""), configuration: config)

    XCTAssertNotEqual(
      router.validationError?.pubNubError,
      PubNubError(.invalidEndpointType, router: router)
    )
  }

  func test_RemoveChannel_WithValidConfig_ReturnsSuccess() throws {
    let expectation = self.expectation(description: "Delete Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_channel_remove_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_RemoveChannel_WhenForbidden_ReturnsForbiddenError() throws {
    let expectation = self.expectation(description: "403 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_403"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_RemoveChannel_WhenPreconditionFailed_ReturnsPreconditionFailedError() throws {
    let expectation = self.expectation(description: "412 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_412"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_RemoveChannel_WhenTooManyRequests_ReturnsTooManyRequestsError() throws {
    let expectation = self.expectation(description: "429 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_429"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_RemoveChannel_WhenInternalServerError_ReturnsInternalServiceError() throws {
    let expectation = self.expectation(description: "500 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_500"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_RemoveChannel_WhenServiceUnavailable_ReturnsServiceUnavailableError() throws {
    let expectation = self.expectation(description: "503 Error Endpoint Expectation")
    let sessions = try MockURLSession.mockSession(for: ["objects_error_503"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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
}
