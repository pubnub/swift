//
//  PublishRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class PublishRouterTests: XCTestCase {
  let testMessage: AnyJSON = "Test Message"
  let testChannel = "TestChannel"
  let testFileId = "FileId"
  let testFilename = "exampe.txt"
  let testCustom = ["purpose": "file testing"]
}

// MARK: - Publish

extension PublishRouterTests {
  func test_PublishRouter_WithAuthKey_SetsExpectedQueryItems() throws {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")

    let router = PublishRouter(
      .publish(message: testMessage, channel: testChannel, customMessageType: nil, shouldStore: nil, ttl: nil, meta: nil),
      configuration: config
    )

    let queryItems = try router.queryItems.get()

    XCTAssertTrue(queryItems.contains(URLQueryItem(name: "auth", value: "auth-key")))
    XCTAssertEqual(router.endpoint.description, "Publish")
    XCTAssertEqual(router.category, "Publish")
    XCTAssertEqual(router.service, .publish)
  }

  func test_PublishRouter_WithEmptyMessage_ReturnsValidationError() throws {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")

    let router = PublishRouter(
      .publish(message: [], channel: testChannel, customMessageType: nil, shouldStore: nil, ttl: nil, meta: nil),
      configuration: config
    )

    let error = try XCTUnwrap(router.validationError as? PubNubError)
    XCTAssertEqual(error.reason, .missingRequiredParameter)
  }

  func test_Publish_WithValidMessage_ReturnsTimetoken() throws {
    let expectation = self.expectation(description: "Publish Response Received")
    let sessions = try MockURLSession.mockSession(for: ["publish_success"])
    let pubnub = TestPubNubFactory.make(authKey: "auth-key", authToken: "access-token", session: sessions.session)

    pubnub.publish(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case let .success(timetoken):
        XCTAssertEqual(timetoken, 15_644_265_196_692_560)
      case let .failure(error):
        XCTFail("Publish request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Publish_WhenMessageTooLarge_ReturnsMessageTooLongError() throws {
    let expectation = self.expectation(description: "Message Response Received")
    let sessions = try MockURLSession.mockSession(for: ["publish_message_too_large"])
    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)

    pubnub.publish(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Message request should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, PubNubError(.messageTooLong))
        XCTAssertTrue(error.pubNubError == .messageTooLong)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Publish_WithInvalidKey_ReturnsInvalidPublishKeyError() throws {
    let expectation = self.expectation(description: "Publish Response Received")
    let sessions = try MockURLSession.mockSession(for: ["publish_invalid_key"])
    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)

    pubnub.publish(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, PubNubError(.invalidPublishKey))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Publish_WhenURITooLong_ReturnsRequestURITooLongError() throws {
    let expectation = self.expectation(description: "Publish Response Received")
    let sessions = try MockURLSession.mockSession(for: ["requestURITooLong_Message"])
    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)

    pubnub.publish(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, PubNubError(.requestURITooLong))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Publish_WithMissingPublishKey_ReturnsMissingPublishKeyError() throws {
    let expectation = self.expectation(description: "Publish Response Received")
    let sessions = try MockURLSession.mockSession(for: ["publish_invalid_key"])
    let pubnub = TestPubNubFactory.make(publishKey: nil, subscribeKey: "NotARealKey", session: sessions.session)

    pubnub.publish(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, PubNubError(.missingPublishKey))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Publish_WithMissingSubscribeKey_ReturnsMissingSubscribeKeyError() throws {
    let expectation = self.expectation(description: "Publish Response Received")
    let sessions = try MockURLSession.mockSession(for: ["publish_invalid_key"])
    let pubnub = TestPubNubFactory.make(publishKey: "NotARealKey", subscribeKey: "", session: sessions.session)

    pubnub.publish(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, PubNubError(.missingSubscribeKey))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Publish_WithMissingPublishAndSubscribeKey_ReturnsMissingBothKeysError() throws {
    let expectation = self.expectation(description: "Publish Response Received")
    let sessions = try MockURLSession.mockSession(for: ["publish_invalid_key"])
    let pubnub = TestPubNubFactory.make(publishKey: nil, subscribeKey: "", session: sessions.session)

    pubnub.publish(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, PubNubError(.missingPublishAndSubscribeKey))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Compressed Publish

extension PublishRouterTests {
  func test_CompressedPublishRouter_WithValidConfig_SetsExpectedProperties() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")

    let router = PublishRouter(
      .compressedPublish(
        message: testMessage, channel: testChannel, customMessageType: nil,
        shouldStore: nil, ttl: nil, meta: nil
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Compressed Publish")
    XCTAssertEqual(router.category, "Compressed Publish")
    XCTAssertEqual(router.service, .publish)
  }

  func test_CompressedPublishRouter_WithEmptyMessage_ReturnsValidationError() throws {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")

    let router = PublishRouter(
      .compressedPublish(message: [], channel: testChannel, customMessageType: nil, shouldStore: nil, ttl: nil, meta: nil),
      configuration: config
    )

    let error = try XCTUnwrap(router.validationError as? PubNubError)
    XCTAssertEqual(error.reason, .missingRequiredParameter)
  }

  func test_CompressedPublish_WithValidMessage_ReturnsTimetoken() throws {
    let expectation = self.expectation(description: "Publish Response Received")
    let sessions = try MockURLSession.mockSession(for: ["publish_success"])
    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)

    pubnub.publish(channel: "Test", message: ["text": "Hello"], shouldCompress: true) { result in
      switch result {
      case let .success(timetoken):
        XCTAssertEqual(timetoken, 15_644_265_196_692_560)
      case let .failure(error):
        XCTFail("Publish request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - File

extension PublishRouterTests {
  func test_FilePublishRouter_WithValidPayload_SetsExpectedProperties() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")

    let router = PublishRouter(
      .file(
        message: FilePublishPayload(channel: testChannel, fileId: testFileId, filename: testFilename),
        customMessageType: nil, shouldStore: nil, ttl: nil, meta: nil
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Publish a File Message")
    XCTAssertEqual(router.category, "Publish a File Message")
    XCTAssertEqual(router.service, .publish)
  }

  func test_FilePublishRouter_WithNilMessageType_ExcludesTypeQueryItem() throws {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")

    let router = PublishRouter(
      .file(
        message: FilePublishPayload(channel: testChannel, fileId: testFileId, filename: testFilename),
        customMessageType: nil, shouldStore: nil, ttl: nil, meta: nil
      ),
      configuration: config
    )

    let queryItems = try router.queryItems.get()

    XCTAssertNil(queryItems.first(where: { $0.name == QueryKey.customMessageType.rawValue }))
  }

  func test_FilePublishRouter_WithCustomMessageType_IncludesTypeQueryItem() throws {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")

    let router = PublishRouter(
      .file(
        message: FilePublishPayload(channel: testChannel, fileId: testFileId, filename: testFilename),
        customMessageType: "type", shouldStore: nil, ttl: nil, meta: nil
      ),
      configuration: config
    )

    let queryItems = try router.queryItems.get()

    XCTAssertTrue(queryItems.contains(URLQueryItem(name: QueryKey.customMessageType.rawValue, value: "type")))
  }

  func test_FilePublishRouter_WithAdditionalDetails_MatchesDecodedPayload() throws {
    let file = FilePublishPayload(
      channel: "",
      fileId: testFileId, filename: testFilename,
      additionalDetails: testCustom
    )

    let jsonMessage = try ImportTestResource.importResource("publish_file_body_raw")
    let jsonFilePublish = try Constant.jsonDecoder.decode(FilePublishPayload.self, from: jsonMessage)

    XCTAssertEqual(file, jsonFilePublish)
  }

  func test_FilePublishRouter_WithEmptyChannel_ReturnsValidationError() throws {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")

    let router = PublishRouter(
      .file(
        message: FilePublishPayload(channel: "", fileId: testFileId, filename: testFilename),
        customMessageType: nil, shouldStore: nil, ttl: nil, meta: nil
      ),
      configuration: config
    )

    let error = try XCTUnwrap(router.validationError as? PubNubError)
    XCTAssertEqual(error.reason, .missingRequiredParameter)
  }

  func test_FilePublishRouter_WithEmptyFileId_ReturnsValidationError() throws {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")

    let router = PublishRouter(
      .file(
        message: FilePublishPayload(channel: testChannel, fileId: "", filename: testFilename),
        customMessageType: nil, shouldStore: nil, ttl: nil, meta: nil
      ),
      configuration: config
    )

    let error = try XCTUnwrap(router.validationError as? PubNubError)
    XCTAssertEqual(error.reason, .missingRequiredParameter)
  }

  func test_FilePublishRouter_WithEmptyFilename_ReturnsValidationError() throws {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")

    let router = PublishRouter(
      .file(
        message: FilePublishPayload(channel: testChannel, fileId: testFileId, filename: ""),
        customMessageType: nil, shouldStore: nil, ttl: nil, meta: nil
      ),
      configuration: config
    )

    let error = try XCTUnwrap(router.validationError as? PubNubError)
    XCTAssertEqual(error.reason, .missingRequiredParameter)
  }

  func test_FilePublish_WithValidPayload_ReturnsTimetoken() throws {
    let expectation = self.expectation(description: "Publish Response Received")
    let sessions = try MockURLSession.mockSession(for: ["publish_success"])
    let file = FilePublishPayload(channel: testChannel, fileId: testFileId, filename: testFilename)

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)

    pubnub.publish(file: file, request: .init(additionalMessage: ["text": "Hello"])) { result in
      switch result {
      case let .success(timetoken):
        XCTAssertEqual(timetoken, 15_644_265_196_692_560)
      case let .failure(error):
        XCTFail("Publish request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_FilePublish_WhenMessageTooLarge_ReturnsMessageTooLongError() throws {
    let expectation = self.expectation(description: "Message Response Received")
    let sessions = try MockURLSession.mockSession(for: ["publish_message_too_large"])
    let file = FilePublishPayload(channel: testChannel, fileId: testFileId, filename: testFilename)

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)

    pubnub.publish(file: file, request: .init(additionalMessage: ["text": "Hello"])) { result in
      switch result {
      case .success:
        XCTFail("Message request should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, PubNubError(.messageTooLong))
        XCTAssertTrue(error.pubNubError == .messageTooLong)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Fire

extension PublishRouterTests {
  func test_FireRouter_WithValidConfig_SetsExpectedProperties() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = PublishRouter(.fire(message: testMessage, channel: testChannel, meta: nil), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Fire")
    XCTAssertEqual(router.category, "Fire")
    XCTAssertEqual(router.service, .publish)
  }

  func test_FireRouter_WithEmptyMessage_ReturnsValidationError() throws {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = PublishRouter(.fire(message: [], channel: testChannel, meta: nil), configuration: config)

    let error = try XCTUnwrap(router.validationError as? PubNubError)
    XCTAssertEqual(error.reason, .missingRequiredParameter)
  }

  func test_Fire_WithValidMessage_ReturnsTimetoken() throws {
    let expectation = self.expectation(description: "Publish Response Received")
    let sessions = try MockURLSession.mockSession(for: ["publish_success"])
    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)

    pubnub.fire(channel: "Test", message: ["text": "Hello"], meta: ["metaKey": "metaValue"]) { result in
      switch result {
      case let .success(timetoken):
        XCTAssertEqual(timetoken, 15_644_265_196_692_560)
      case let .failure(error):
        XCTFail("Publish request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Signal

extension PublishRouterTests {
  func test_SignalRouter_WithValidConfig_SetsExpectedProperties() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = PublishRouter(.signal(message: testMessage, channel: testChannel, customMessageType: nil), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Signal")
    XCTAssertEqual(router.category, "Signal")
    XCTAssertEqual(router.service, .publish)
  }

  func test_SignalRouter_WithEmptyMessage_ReturnsValidationError() throws {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = PublishRouter(.signal(message: [], channel: testChannel, customMessageType: nil), configuration: config)

    let error = try XCTUnwrap(router.validationError as? PubNubError)
    XCTAssertEqual(error.reason, .missingRequiredParameter)
  }

  func test_Signal_WithValidMessage_ReturnsTimetoken() throws {
    let expectation = self.expectation(description: "Signal Response Received")
    let sessions = try MockURLSession.mockSession(for: ["publish_success"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)

    pubnub.signal(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case let .success(timetoken):
        XCTAssertEqual(timetoken, 15_644_265_196_692_560)
      case let .failure(error):
        XCTFail("Signal request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Signal_WithInvalidKey_ReturnsInvalidPublishKeyError() throws {
    let expectation = self.expectation(description: "Signal Response Received")
    let sessions = try MockURLSession.mockSession(for: ["publish_invalid_key"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)

    pubnub.signal(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Signal request should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, PubNubError(.invalidPublishKey))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Signal_WhenMessageTooLarge_ReturnsMessageTooLongError() throws {
    let expectation = self.expectation(description: "Signal Response Received")
    let sessions = try MockURLSession.mockSession(for: ["signal_message_too_large"])
    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)

    pubnub.signal(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Signal request should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, PubNubError(.messageTooLong))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_Signal_WhenURITooLong_ReturnsRequestURITooLongError() throws {
    let expectation = self.expectation(description: "Signal Response Received")
    let sessions = try MockURLSession.mockSession(for: ["requestURITooLong_Message"])
    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)

    pubnub.signal(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Signal request should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, PubNubError(.requestURITooLong))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
