//
//  HistoryRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
// swiftlint:disable file_length

@testable import PubNub
import XCTest

final class HistoryRouterTests: XCTestCase {
  var config = PubNubConfiguration(
    publishKey: "FakeTestString",
    subscribeKey: "FakeTestString",
    userId: UUID().uuidString,
    authKey: "auth-key"
  )

  let testChannel = "TestChannel"
  let testSingleChannel = ["TestChannel"]
  let testMultiChannels = ["TestChannel", "OtherTestChannel"]
}

// MARK: - Fetch History

extension HistoryRouterTests {
  func testFetch_Router() {
    config.authToken = "access-token"
    let router = HistoryRouter(
      .fetch(
        channels: testMultiChannels, max: nil, start: nil, end: nil,
        includeMeta: false, includeMessageType: false, includeUUID: false
      ),
      configuration: config
    )

    guard let queryItems = try? router.queryItems.get() else {
      return XCTAssert(false, "'queryItems' not set")
    }

    XCTAssertEqual(router.endpoint.description, "Fetch Message History")
    XCTAssertEqual(router.category, "Fetch Message History")
    XCTAssertEqual(router.service, .history)
    XCTAssertNotNil(config.authKey)
    XCTAssertNotNil(config.authToken)
    XCTAssertTrue(queryItems.contains(URLQueryItem(name: "auth", value: "access-token")))
  }

  func testFetch_Router_ValidationError() {
    let router = HistoryRouter(
      .fetch(
        channels: [], max: nil, start: nil, end: nil,
        includeMeta: false, includeMessageType: false, includeUUID: false
      ),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelArray)
  }

  func testFetch_Router_firstChannel() {
    let router = HistoryRouter(
      .fetch(
        channels: testMultiChannels, max: nil, start: nil, end: nil,
        includeMeta: false, includeMessageType: false, includeUUID: false
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.firstChannel, testChannel)
  }

  func testFetch_Success() {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testFetch_Success_IncludeMeta() {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success_withMeta"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testFetch_Success_MultipleChannels() {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success_multipleChannels"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testFetch_Success_Encrypted() {
    let expectation = self.expectation(description: "HereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success_encrypted"]) else {
      return XCTFail("Could not create mock url session")
    }

    var configWithCipher = config
    configWithCipher.cryptoModule = CryptoModule.legacyCryptoModule(with: "SomeTestString", withRandomIV: false)

    let pubnub = PubNub(configuration: configWithCipher, session: sessions.session)
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

  func testFetch_Success_EncryptedWrongKey() {
    let expectation = self.expectation(description: "HereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success_encrypted"]) else {
      return XCTFail("Could not create mock url session")
    }

    var configWithCipher = config
    configWithCipher.cryptoModule = CryptoModule.legacyCryptoModule(with: "NotTheRightKey", withRandomIV: false)

    let pubnub = PubNub(configuration: configWithCipher, session: sessions.session)
    pubnub.fetchMessageHistory(for: testMultiChannels) { result in
      switch result {
      case let .success((messagesByChannel, next)):
        let channelMessages = messagesByChannel[self.testChannel]
        XCTAssertNotNil(channelMessages)
        XCTAssertEqual(channelMessages?.first?.payload.dataOptional?.base64EncodedString(), "s3+CcEE2QZ/Lh9CaPieJnQ==")
        XCTAssertTrue((channelMessages ?? []).reduce(into: true) { $0 = $0 && $1.error?.reason == .decryptionFailure })
        XCTAssertEqual(next?.start, 15_657_268_328_421_957)
      case let .failure(error):
        XCTFail("Fetch History request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)
  }

  func testFetch_Success_MixedEncrypted() {
    let expectation = self.expectation(description: "Fetch Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success_mixedEncrypted"]) else {
      return XCTFail("Could not create mock url session")
    }

    var configWithCipher = config
    configWithCipher.cryptoModule = CryptoModule.legacyCryptoModule(with: "SomeTestString", withRandomIV: false)

    let pubnub = PubNub(configuration: configWithCipher, session: sessions.session)
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

  func testFetch_Success_EmptyMessages() {
    let expectation = self.expectation(description: "Fetch History Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success_emptyList"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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
  func testFetchWithActions_Router() {
    let router = HistoryRouter(
      .fetchWithActions(
        channel: testChannel, max: nil, start: nil, end: nil,
        includeMeta: false, includeMessageType: false, includeUUID: false
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Fetch Message History with Message Actions")
    XCTAssertEqual(router.category, "Fetch Message History with Message Actions")
    XCTAssertEqual(router.service, .history)
  }

  func testFetchWithActions_Router_ValidationError() {
    let router = HistoryRouter(
      .fetchWithActions(
        channel: "", max: nil, start: nil, end: nil,
        includeMeta: false, includeMessageType: false, includeUUID: false
      ),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelString)
  }

  func testFetchWithActions_Router_firstChannel() {
    let router = HistoryRouter(
      .fetchWithActions(
        channel: testChannel, max: nil, start: nil, end: nil,
        includeMeta: false, includeMessageType: false, includeUUID: false
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.firstChannel, testChannel)
  }

  func testFetchWithActions_Success() {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistoryWithActions_Fetch_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testFetchWithActions_Success_Empty() {
    let expectation = self.expectation(description: "Fetch History Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistoryWithActions_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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
  func testDelete_Router() {
    let router = HistoryRouter(
      .delete(channel: testChannel, start: nil, end: nil),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Delete Message History")
    XCTAssertEqual(router.category, "Delete Message History")
    XCTAssertEqual(router.method, .delete)
    XCTAssertEqual(router.service, .history)
  }

  func testDelete_Router_ValidationError() {
    let router = HistoryRouter(.delete(channel: "", start: nil, end: nil),
                               configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelString)
  }

  func testDelete_Router_firstChannel() {
    let router = HistoryRouter(.delete(channel: testChannel, start: nil, end: nil),
                               configuration: config)

    XCTAssertEqual(router.endpoint.firstChannel, testChannel)
  }

  func testDelete_Success() {
    let expectation = self.expectation(description: "Delete History Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Delete_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testHistory_Error_HistoryNotEnabled() {
    let expectation = self.expectation(description: "History Not Enabled Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["history_delete_not_enabled_for_key_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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
  func testMessageCounts_Router() {
    let router = HistoryRouter(.messageCounts(channels: testSingleChannel, timetoken: 0, channelsTimetoken: [0]),
                               configuration: config)

    XCTAssertEqual(router.endpoint.description, "Message Counts")
    XCTAssertEqual(router.category, "Message Counts")
    XCTAssertEqual(router.service, .history)
  }

  func testMessageCounts_Router_ValidationError() {
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

  func testMessageCounts_Router_firstChannel() {
    let router = HistoryRouter(.messageCounts(channels: testSingleChannel, timetoken: 0, channelsTimetoken: [0]),
                               configuration: config)

    XCTAssertEqual(router.endpoint.firstChannel, testChannel)
  }

  func testMessageCounts_Success() {
    let expectation = self.expectation(description: "Message Counts Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["message_counts_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testMessageCounts_Success_ChannelsDictionary() {
    let expectation = self.expectation(description: "Message Counts Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["message_counts_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testMessageCounts_Error_InvalidArguments() {
    let expectation = self.expectation(description: "Message Counts Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["message_counts_error_invalid_arguments"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testMessageCounts_Error_ServiceNotEnabled() {
    let expectation = self.expectation(description: "Message Counts Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["message_counts_error_serviceNotEnabled"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

// swiftlint:enable file_length
