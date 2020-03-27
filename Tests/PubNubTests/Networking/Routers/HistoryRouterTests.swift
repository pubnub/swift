//
//  HistoryRouterTests.swift
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
// swiftlint:disable file_length

@testable import PubNub
import XCTest

final class HistoryRouterTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  let testChannel = "TestChannel"

  let testSingleChannel = ["TestChannel"]
  let testMultiChannels = ["TestChannel", "OtherTestChannel"]
}

// MARK: - Fetch History

extension HistoryRouterTests {
  func testFetch_Router() {
    let router = HistoryRouter(
      .fetch(channels: testMultiChannels, max: nil, start: nil, end: nil, includeMeta: false),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Fetch Message History")
    XCTAssertEqual(router.category, "Fetch Message History")
    XCTAssertEqual(router.service, .history)
  }

  func testFetch_Router_ValidationError() {
    let router = HistoryRouter(
      .fetch(channels: [], max: nil, start: nil, end: nil, includeMeta: false),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelArray)
  }

  func testFetch_Router_firstChannel() {
    let router = HistoryRouter(
      .fetch(channels: testMultiChannels, max: nil, start: nil, end: nil, includeMeta: false),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.firstChannel, testChannel)
  }

  func testFetch_Success() {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: testSingleChannel) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.count, 1)
          let channelMessages = payload[self.testChannel]
          XCTAssertNotNil(channelMessages)
          XCTAssertNotEqual(channelMessages?.startTimetoken, 0)
          XCTAssertNotEqual(channelMessages?.endTimetoken, 0)
          XCTAssertNil(channelMessages?.messages.first?.meta)
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

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: testMultiChannels) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.count, 1)
          let channelMessages = payload[self.testChannel]
          XCTAssertNotNil(channelMessages)
          XCTAssertNotEqual(channelMessages?.startTimetoken, 0)
          XCTAssertNotEqual(channelMessages?.endTimetoken, 0)
          XCTAssertNotNil(channelMessages?.messages.first?.meta)
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

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: testMultiChannels) { result in
        switch result {
        case let .success(payload):
          XCTAssertGreaterThan(payload.count, 1)
          let channelMessages = payload[self.testChannel]
          XCTAssertNotNil(channelMessages)
          XCTAssertNotEqual(channelMessages?.startTimetoken, 0)
          XCTAssertNotEqual(channelMessages?.endTimetoken, 0)
          XCTAssertNotNil(channelMessages?.messages.first?.meta)
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
    configWithCipher.cipherKey = Crypto(key: "SomeTestString")

    PubNub(configuration: configWithCipher, session: sessions.session)
      .fetchMessageHistory(for: testMultiChannels) { result in
        switch result {
        case let .success(payload):
          XCTAssertFalse(payload.isEmpty)
          let channelMessages = payload[self.testChannel]
          XCTAssertNotNil(channelMessages)
          XCTAssertNotEqual(channelMessages?.startTimetoken, 0)
          XCTAssertNotEqual(channelMessages?.endTimetoken, 0)
          XCTAssertEqual(channelMessages?.messages.first?.message.boolOptional, true)
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
    configWithCipher.cipherKey = Crypto(key: "NotTheRightKey")

    PubNub(configuration: configWithCipher, session: sessions.session)
      .fetchMessageHistory(for: testMultiChannels) { result in
        switch result {
        case let .success(payload):
          XCTAssertFalse(payload.isEmpty)
          let channelMessages = payload[self.testChannel]
          XCTAssertNotNil(channelMessages)
          XCTAssertNotEqual(channelMessages?.startTimetoken, 0)
          XCTAssertNotEqual(channelMessages?.endTimetoken, 0)
          XCTAssertEqual(channelMessages?.messages.first?.message.dataOptional?.base64EncodedString(),
                         "s3+CcEE2QZ/Lh9CaPieJnQ==")
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
    configWithCipher.cipherKey = Crypto(key: "SomeTestString")

    PubNub(configuration: configWithCipher, session: sessions.session)
      .fetchMessageHistory(for: testMultiChannels) { result in
        switch result {
        case let .success(payload):
          XCTAssertFalse(payload.isEmpty)
          let channelMessages = payload[self.testChannel]
          XCTAssertNotNil(channelMessages)
          XCTAssertNotEqual(channelMessages?.startTimetoken, 0)
          XCTAssertNotEqual(channelMessages?.endTimetoken, 0)
          // Unencrypted Value
          XCTAssertEqual(channelMessages?.messages.first?.message.stringOptional, "Hello")
          // Encrypted Value
          XCTAssertEqual(channelMessages?.messages.last?.message.boolOptional, true)
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

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: testMultiChannels) { result in
        switch result {
        case let .success(payload):
          XCTAssertTrue(payload.isEmpty)
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
      .fetchWithActions(channel: testChannel, max: nil, start: nil, end: nil, includeMeta: false),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Fetch Message History with Message Actions")
    XCTAssertEqual(router.category, "Fetch Message History with Message Actions")
    XCTAssertEqual(router.service, .history)
  }

  func testFetchWithActions_Router_ValidationError() {
    let router = HistoryRouter(
      .fetchWithActions(channel: "", max: nil, start: nil, end: nil, includeMeta: false),
      configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelString)
  }

  func testFetchWithActions_Router_firstChannel() {
    let router = HistoryRouter(
      .fetchWithActions(channel: testChannel, max: nil, start: nil, end: nil, includeMeta: false),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.firstChannel, testChannel)
  }

  func testFetchWithActions_Decode_MissingTimetoken() {
    guard let action = ["uuid": "UUIDString", "actionTimetoken": "notTimetoken"].jsonData else {
      return XCTFail("Could not convert object to data")
    }

    XCTAssertEqual(try? JSONDecoder().decode(MessageActionHistory.self, from: action).actionTimetoken, 0)
  }

  func testFetchWithActions_Success() {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistoryWithActions_Fetch_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let messageAction = MessageActionPayload(uuid: "otheruser", type: "reaction", value: "smiley_face",
                                             actionTimetoken: 15_724_677_187_827_310,
                                             messageTimetoken: 15_724_676_552_283_948)

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: [testChannel], fetchActions: true) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.count, 1)
          let channelHistory = payload[self.testChannel]
          XCTAssertEqual(channelHistory?.messages.count, 2)
          XCTAssertEqual(channelHistory?.messages.first?.actions.count, 3)
          XCTAssertTrue(channelHistory?.messages.first?.actions.contains(messageAction) ?? false)
          XCTAssertEqual(channelHistory?.messages.last?.actions.count, 0)
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

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: [testChannel], fetchActions: true) { result in
        switch result {
        case let .success(channels):
          XCTAssertEqual(channels.count, 0)
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

    PubNub(configuration: config, session: sessions.session).deleteMessageHistory(from: testChannel) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.message, .acknowledge)
      case let .failure(error):
        XCTFail("Delete History request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testHistory_Error_HistoryNotEnabled() {
    let expectation = self.expectation(description: "History Not Enabled Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["history_delete_not_enabled_for_key_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session).deleteMessageHistory(from: testChannel) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.message, .acknowledge)
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

    PubNub(configuration: config, session: sessions.session)
      .messageCounts(channels: testSingleChannel, timetoken: 0) { result in
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

    PubNub(configuration: config, session: sessions.session)
      .messageCounts(channels: Dictionary(zip(testSingleChannel, [0])) { _, last in last }) { result in
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

    PubNub(configuration: config, session: sessions.session)
      .messageCounts(channels: testSingleChannel, timetoken: 0) { result in
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

    PubNub(configuration: config, session: sessions.session)
      .messageCounts(channels: testSingleChannel, timetoken: 0) { result in
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

// MARK: - MessageHistory ResponseDecoder

extension HistoryRouterTests {
  func testMessageHistoryResponse_Deocde_missingChannels() {
    let data: [String: JSONCodableScalar] = ["status": 0, "error": false, "error_message": "Test Message"]

    guard let json = data.mapValues({ $0.codableValue }).jsonData else {
      return XCTFail("Could not convert object to data")
    }

    XCTAssertEqual(try? JSONDecoder().decode(MessageHistoryResponse.self, from: json).channels.isEmpty, true)
  }

  func testMessageHistoryChannelPayload_Decode_InvalidTimetokenStrings() {
    let data: [Any] = []

    guard let json = AnyJSON(data).jsonData else {
      return XCTFail("Could not convert object to data")
    }

    guard let payload = try? JSONDecoder().decode(MessageHistoryChannelPayload.self, from: json) else {
      return XCTFail("Could not decode object from data")
    }

    XCTAssertEqual(payload.startTimetoken, 0)
    XCTAssertEqual(payload.endTimetoken, 0)
  }

  func testMessageHistoryChannelPayload_isEmpty() {
    let payload = MessageHistoryChannelPayload(messags: [])

    XCTAssertEqual(payload.isEmpty, true)
  }
}

// swiftlint:enable file_length
