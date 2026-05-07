//
//  HistoryRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

final class HistoryRouterTests: XCTestCase {
  let testChannel = "TestChannel"
  let testSingleChannel = ["TestChannel"]
  let testMultiChannels = ["TestChannel", "OtherTestChannel"]
}

// MARK: - Fetch History

extension HistoryRouterTests {
  func test_FetchHistoryRouter_WithAuthToken_SetsExpectedQueryItems() throws {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key", authToken: "access-token")
    let router = HistoryRouter(
      .fetch(
        channels: testMultiChannels, max: nil, start: nil, end: nil,
        includeMeta: false, includeMessageType: false,
        includeCustomMessageType: false, includeUUID: false
      ),
      configuration: config
    )

    let queryItems = try router.queryItems.get()

    XCTAssertEqual(router.endpoint.description, "Fetch Message History")
    XCTAssertEqual(router.category, "Fetch Message History")
    XCTAssertEqual(router.service, .history)
    XCTAssertNotNil(config.authKey)
    XCTAssertNotNil(config.authToken)
    XCTAssertTrue(queryItems.contains(URLQueryItem(name: "auth", value: "access-token")))
  }

  func test_FetchHistoryRouter_WithEmptyChannels_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = HistoryRouter(
      .fetch(
        channels: [], max: nil, start: nil, end: nil,
        includeMeta: false, includeMessageType: false,
        includeCustomMessageType: false, includeUUID: false
      ),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelArray)
  }

  func test_FetchHistoryRouter_WithMultipleChannels_ReturnsFirstChannel() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = HistoryRouter(
      .fetch(
        channels: testMultiChannels, max: nil, start: nil, end: nil,
        includeMeta: false, includeMessageType: false,
        includeCustomMessageType: false, includeUUID: false
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.firstChannel, testChannel)
  }

  func test_FetchHistory_WithSingleChannel_ReturnsMessages() throws {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    let sessions = try MockURLSession.mockSession(for: ["messageHistory_Fetch_success"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)
    pubnub.fetchMessageHistory(for: testSingleChannel) { result in
      switch result {
      case let .success((messagesByChannel, next)):
        XCTAssertEqual(messagesByChannel.keys.count, 1)
        let channelMessages = messagesByChannel[self.testChannel]
        XCTAssertNotNil(channelMessages)
        XCTAssertNil(channelMessages?.first?.metadata)
        XCTAssertEqual(next?.start, 15_653_750_239_963_666)
      case let .failure(error):
        XCTFail("Fetch History  request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_FetchHistory_WithIncludeMeta_ReturnsMessagesWithMetadata() throws {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    let sessions = try MockURLSession.mockSession(for: ["messageHistory_Fetch_success_withMeta"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)
    pubnub.fetchMessageHistory(for: testMultiChannels) { result in
      switch result {
      case let .success((messagesByChannel, next)):
        XCTAssertEqual(messagesByChannel.keys.count, 1)
        let channelMessages = messagesByChannel[self.testChannel]
        XCTAssertNotNil(channelMessages)
        XCTAssertNotNil(channelMessages?.first?.metadata)
        XCTAssertEqual(next?.start, 15_654_070_724_737_575)
      case let .failure(error):
        XCTFail("Fetch History  request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_FetchHistory_WithMultipleChannels_ReturnsMessagesForAllChannels() throws {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    let sessions = try MockURLSession.mockSession(for: ["messageHistory_Fetch_success_multipleChannels"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)
    pubnub.fetchMessageHistory(for: testMultiChannels) { result in
      switch result {
      case let .success((messagesByChannel, next)):
        XCTAssertEqual(messagesByChannel.keys.count, 2)
        let channelMessages = messagesByChannel[self.testChannel]
        XCTAssertNotNil(channelMessages)
        XCTAssertNotNil(channelMessages?.first?.metadata)
        XCTAssertEqual(next?.start, 15_654_070_724_737_575)
      case let .failure(error):
        XCTFail("Fetch History request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_FetchHistory_WithEncryptedMessages_ReturnsDecryptedPayload() throws {
    let expectation = self.expectation(description: "HereNow Response Received")

    let sessions = try MockURLSession.mockSession(for: ["messageHistory_Fetch_success_encrypted"])

    let pubnub = TestPubNubFactory.make(
      authKey: "auth-key",
      cryptoModule: CryptoModule.legacyCryptoModule(with: "SomeTestString", withRandomIV: false),
      session: sessions.session
    )
    pubnub.fetchMessageHistory(for: testMultiChannels) { result in
      switch result {
      case let .success((messagesByChannel, next)):
        let channelMessages = messagesByChannel[self.testChannel]
        XCTAssertNotNil(channelMessages)
        XCTAssertEqual(channelMessages?.first?.payload.boolOptional, true)
        XCTAssertEqual(next?.start, 15_657_268_328_421_957)
      case let .failure(error):
        XCTFail("Fetch History request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_FetchHistory_WithWrongDecryptionKey_ReturnsDecryptionFailureError() throws {
    let expectation = self.expectation(description: "HereNow Response Received")

    let sessions = try MockURLSession.mockSession(for: ["messageHistory_Fetch_success_encrypted"])

    let pubnub = TestPubNubFactory.make(
      authKey: "auth-key",
      cryptoModule: CryptoModule.legacyCryptoModule(with: "NotTheRightKey", withRandomIV: false),
      session: sessions.session
    )
    pubnub.fetchMessageHistory(for: testMultiChannels) { result in
      switch result {
      case let .success((messagesByChannel, next)):
        let channelMessages = messagesByChannel[self.testChannel]
        XCTAssertNotNil(channelMessages)
        XCTAssertEqual(channelMessages?.first?.payload.dataOptional?.base64EncodedString(), "s3+CcEE2QZ/Lh9CaPieJnQ==")
        XCTAssertTrue((channelMessages ?? []).allSatisfy { $0.error?.reason == .decryptionFailure })
        XCTAssertEqual(next?.start, 15_657_268_328_421_957)
      case let .failure(error):
        XCTFail("Fetch History request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }

  func test_FetchHistory_WithMixedEncryptedMessages_ReturnsDecryptedAndPlaintext() throws {
    let expectation = self.expectation(description: "Fetch Response Received")

    let sessions = try MockURLSession.mockSession(for: ["messageHistory_Fetch_success_mixedEncrypted"])

    let pubnub = TestPubNubFactory.make(
      authKey: "auth-key",
      cryptoModule: CryptoModule.legacyCryptoModule(with: "SomeTestString", withRandomIV: false),
      session: sessions.session
    )
    pubnub.fetchMessageHistory(for: testMultiChannels) { result in
      switch result {
      case let .success((messagesByChannel, next)):
        let channelMessages = messagesByChannel[self.testChannel]
        XCTAssertNotNil(channelMessages)
        // Unencrypted Value
        XCTAssertEqual(channelMessages?.first?.payload.stringOptional, "Hello")
        // Encrypted Value
        XCTAssertEqual(channelMessages?.last?.payload.boolOptional, true)
        XCTAssertEqual(next?.start, 15_653_750_239_963_666)
      case let .failure(error):
        XCTFail("Fetch History request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_FetchHistory_WithNoMessages_ReturnsEmptyResult() throws {
    let expectation = self.expectation(description: "Fetch History Received")

    let sessions = try MockURLSession.mockSession(for: ["messageHistory_Fetch_success_emptyList"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)
    pubnub.fetchMessageHistory(for: testMultiChannels) { result in
      switch result {
      case let .success((messagesByChannel, next)):
        XCTAssertTrue(messagesByChannel.isEmpty)
        XCTAssertNil(next)
      case let .failure(error):
        XCTFail("Fetch History request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Fetch With Message Actions

extension HistoryRouterTests {
  func test_FetchWithActionsRouter_WithValidConfig_SetsExpectedProperties() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = HistoryRouter(
      .fetchWithActions(
        channel: testChannel, max: nil, start: nil, end: nil,
        includeMeta: false, includeMessageType: false,
        includeCustomMessageType: false, includeUUID: false
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Fetch Message History with Message Actions")
    XCTAssertEqual(router.category, "Fetch Message History with Message Actions")
    XCTAssertEqual(router.service, .history)
  }

  func test_FetchWithActionsRouter_WithEmptyChannel_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = HistoryRouter(
      .fetchWithActions(
        channel: "", max: nil, start: nil, end: nil,
        includeMeta: false, includeMessageType: false,
        includeCustomMessageType: false, includeUUID: false
      ),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelString)
  }

  func test_FetchWithActionsRouter_WithValidChannel_ReturnsFirstChannel() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = HistoryRouter(
      .fetchWithActions(
        channel: testChannel, max: nil, start: nil, end: nil,
        includeMeta: false, includeMessageType: false,
        includeCustomMessageType: false, includeUUID: false
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.firstChannel, testChannel)
  }

  func test_FetchWithActions_WithValidChannel_ReturnsMessagesWithActions() throws {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    let sessions = try MockURLSession.mockSession(for: ["messageHistoryWithActions_Fetch_success"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)
    pubnub.fetchMessageHistory(for: [testChannel], includeActions: true) { result in
      switch result {
      case let .success((messagesByChannel, next)):
        XCTAssertEqual(messagesByChannel[self.testChannel]?.count, 2)
        XCTAssertEqual(messagesByChannel[self.testChannel]?.first?.actions.count, 3)
        XCTAssertEqual(messagesByChannel[self.testChannel]?.last?.actions.count, 0)
        XCTAssertEqual(next?.start, 15_724_676_552_283_948)
      case let .failure(error):
        XCTFail("Fetch History  request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_FetchWithActions_WithNoMessages_ReturnsEmptyResult() throws {
    let expectation = self.expectation(description: "Fetch History Response Received")

    let sessions = try MockURLSession.mockSession(for: ["messageHistoryWithActions_success_empty"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)
    pubnub.fetchMessageHistory(for: [testChannel], includeActions: true) { result in
      switch result {
      case let .success((messagesByChannel, next)):
        XCTAssertTrue(messagesByChannel.isEmpty)
        XCTAssertNil(next)
      case let .failure(error):
        XCTFail("Fetch History  request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Delete History

extension HistoryRouterTests {
  func test_DeleteHistoryRouter_WithValidConfig_SetsExpectedProperties() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = HistoryRouter(
      .delete(channel: testChannel, start: nil, end: nil),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Delete Message History")
    XCTAssertEqual(router.category, "Delete Message History")
    XCTAssertEqual(router.method, .delete)
    XCTAssertEqual(router.service, .history)
  }

  func test_DeleteHistoryRouter_WithEmptyChannel_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = HistoryRouter(.delete(channel: "", start: nil, end: nil),
                               configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelString)
  }

  func test_DeleteHistoryRouter_WithValidChannel_ReturnsFirstChannel() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = HistoryRouter(.delete(channel: testChannel, start: nil, end: nil),
                               configuration: config)

    XCTAssertEqual(router.endpoint.firstChannel, testChannel)
  }

  func test_DeleteHistory_WithValidChannel_ReturnsSuccess() throws {
    let expectation = self.expectation(description: "Delete History Received")

    let sessions = try MockURLSession.mockSession(for: ["messageHistory_Delete_success"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)
    pubnub.deleteMessageHistory(from: testChannel) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case let .failure(error):
        XCTFail("Delete History request failed with error: \(error.localizedDescription)")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_DeleteHistory_WhenNotEnabled_ReturnsMessageDeletionNotEnabledError() throws {
    let expectation = self.expectation(description: "History Not Enabled Received")

    let sessions = try MockURLSession.mockSession(for: ["history_delete_not_enabled_for_key_Message"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)
    pubnub.deleteMessageHistory(from: testChannel) { result in
      switch result {
      case .success:
        XCTFail("Request should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.messageDeletionNotEnabled))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Message Counts

extension HistoryRouterTests {
  func test_MessageCountsRouter_WithValidConfig_SetsExpectedProperties() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = HistoryRouter(.messageCounts(channels: testSingleChannel, timetoken: 0, channelsTimetoken: [0]),
                               configuration: config)

    XCTAssertEqual(router.endpoint.description, "Message Counts")
    XCTAssertEqual(router.category, "Message Counts")
    XCTAssertEqual(router.service, .history)
  }

  func test_MessageCountsRouter_WithInvalidInputs_ReturnsValidationErrors() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = HistoryRouter(.messageCounts(channels: [], timetoken: 0, channelsTimetoken: [0]),
                               configuration: config)
    XCTAssertEqual(router.validationError?.pubNubError?.details.first, ErrorDescription.emptyChannelArray)

    let missingTTs = HistoryRouter(.messageCounts(channels: testSingleChannel, timetoken: nil, channelsTimetoken: nil),
                                   configuration: config)
    XCTAssertEqual(missingTTs.validationError?.pubNubError?.details.first, ErrorDescription.missingTimetoken)

    let invalidTTConfig = HistoryRouter(
      .messageCounts(channels: testMultiChannels, timetoken: 0, channelsTimetoken: [0]), configuration: config
    )
    XCTAssertEqual(invalidTTConfig.validationError?.pubNubError?.details.first,
                   ErrorDescription.invalidHistoryTimetokens)
  }

  func test_MessageCountsRouter_WithValidChannels_ReturnsFirstChannel() {
    let config = TestPubNubFactory.makeConfig(authKey: "auth-key")
    let router = HistoryRouter(.messageCounts(channels: testSingleChannel, timetoken: 0, channelsTimetoken: [0]),
                               configuration: config)

    XCTAssertEqual(router.endpoint.firstChannel, testChannel)
  }

  func test_MessageCounts_WithValidChannel_ReturnsCountPerChannel() throws {
    let expectation = self.expectation(description: "Message Counts Response Received")

    let sessions = try MockURLSession.mockSession(for: ["message_counts_success"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)
    pubnub.messageCounts(channels: testSingleChannel, timetoken: 0) { result in
      switch result {
      case let .success(channels):
        XCTAssertFalse(channels.isEmpty)
        let channelCounts = channels[self.testChannel]
        XCTAssertNotNil(channelCounts)
        XCTAssertEqual(channelCounts, 2)
      case let .failure(error):
        XCTFail("Message Counts request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_MessageCounts_WithChannelsDictionary_ReturnsCountPerChannel() throws {
    let expectation = self.expectation(description: "Message Counts Response Received")

    let sessions = try MockURLSession.mockSession(for: ["message_counts_success"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)
    pubnub.messageCounts(channels: Dictionary(zip(testSingleChannel, [0])) { _, last in last }) { result in
      switch result {
      case let .success(channels):
        XCTAssertFalse(channels.isEmpty)
        let channelCounts = channels[self.testChannel]
        XCTAssertNotNil(channelCounts)
        XCTAssertEqual(channelCounts, 2)
      case let .failure(error):
        XCTFail("Message Counts request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_MessageCounts_WithInvalidArguments_ReturnsInvalidArgumentsError() throws {
    let expectation = self.expectation(description: "Message Counts Response Received")

    let sessions = try MockURLSession.mockSession(for: ["message_counts_error_invalid_arguments"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)
    pubnub.messageCounts(channels: testSingleChannel, timetoken: 0) { result in
      switch result {
      case .success:
        XCTFail("This should fail")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.invalidArguments))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_MessageCounts_WhenServiceNotEnabled_ReturnsMessageHistoryNotEnabledError() throws {
    let expectation = self.expectation(description: "Message Counts Response Received")

    let sessions = try MockURLSession.mockSession(for: ["message_counts_error_serviceNotEnabled"])

    let pubnub = TestPubNubFactory.make(authKey: "auth-key", session: sessions.session)
    pubnub.messageCounts(channels: testSingleChannel, timetoken: 0) { result in
      switch result {
      case .success:
        XCTFail("This should fail")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.messageHistoryNotEnabled))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
