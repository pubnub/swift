//
//  MessageHistoryEndpointTests.swift
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

final class MessageHistoryEndpointTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  let testChannel = "TestChannel"

  let v2Channels = ["TestChannel"]
  let v3Channels = ["TestChannel", "OtherTestChannel"]

  // MARK: - Fetch History V2 (Single Channel)

  func testFetchHistoryV2_Endpoint() {
    let endpoint = Endpoint.fetchMessageHistory(channels: v2Channels,
                                                max: nil, start: nil, end: nil, includeMeta: false)

    XCTAssertEqual(endpoint.description, "Fetch Message History V2")
    XCTAssertEqual(endpoint.category, .fetchMessageHistoryV2)
    XCTAssertEqual(endpoint.operationCategory, .history)
    XCTAssertNil(endpoint.validationError)
  }

  func testFetchHistoryV2_Endpoint_ValidationError() {
    let endpoint = Endpoint.fetchMessageHistory(channels: [], max: nil, start: nil, end: nil, includeMeta: false)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testFetchHistoryV2_Success() {
    let expectation = self.expectation(description: "FetchHistory Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_FetchV2_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: v2Channels) { result in
        switch result {
        case let .success(payload):
          XCTAssertFalse(payload.isEmpty)
          let channelMessages = payload[self.testChannel]
          XCTAssertNotNil(channelMessages)
          XCTAssertNotEqual(channelMessages?.startTimetoken, 0)
          XCTAssertNotEqual(channelMessages?.endTimetoken, 0)
          XCTAssertFalse(channelMessages?.messages.isEmpty ?? true)
          XCTAssertNil(channelMessages?.messages.first?.meta)
        case let .failure(error):
          XCTFail("Fetch History request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchHistoryV2_Success_IncludeMeta() {
    let expectation = self.expectation(description: "FetchHistory Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_FetchV2_success_withMeta"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: v2Channels) { result in
        switch result {
        case let .success(payload):
          XCTAssertFalse(payload.isEmpty)
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

  func testFetchHistoryV2_Success_Encrypted() {
    let expectation = self.expectation(description: "FetchHistory Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_FetchV2_success_encrypted"]) else {
      return XCTFail("Could not create mock url session")
    }

    var configWithCipher = config
    configWithCipher.cipherKey = Crypto(key: "SomeTestString")

    PubNub(configuration: configWithCipher, session: sessions.session)
      .fetchMessageHistory(for: v2Channels) { result in
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

  func testFetchHistoryV2_Success_EncryptedWrongKey() {
    let expectation = self.expectation(description: "FetchHistory Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_FetchV2_success_encrypted"]) else {
      return XCTFail("Could not create mock url session")
    }

    var configWithCipher = config
    configWithCipher.cipherKey = Crypto(key: "NotTheRightKey")

    PubNub(configuration: configWithCipher, session: sessions.session)
      .fetchMessageHistory(for: v2Channels) { result in
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

  func testFetchHistoryV2_Success_MixedEncrypted() {
    let expectation = self.expectation(description: "FetchHistory Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_FetchV2_success_mixedEncrypted"]) else {
      return XCTFail("Could not create mock url session")
    }

    var configWithCipher = config
    configWithCipher.cipherKey = Crypto(key: "SomeTestString")

    PubNub(configuration: configWithCipher, session: sessions.session)
      .fetchMessageHistory(for: v2Channels) { result in
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

  func testFetchHistoryV2_Success_EmptyMessages() {
    let expectation = self.expectation(description: "Fetch History V2 Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_FetchV2_success_emptyList"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: v2Channels) { result in
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

// MARK: - Fetch History V3 (Multi Channel)

extension MessageHistoryEndpointTests {
  func testFetchHistory_Endpoint() {
    let endpoint = Endpoint.fetchMessageHistory(channels: v3Channels,
                                                max: nil, start: nil, end: nil, includeMeta: false)

    XCTAssertEqual(endpoint.description, "Fetch Message History")
    XCTAssertEqual(endpoint.category, .fetchMessageHistory)
    XCTAssertEqual(endpoint.operationCategory, .history)
    XCTAssertNil(endpoint.validationError)
  }

  func testFetchHistory_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.fetchMessageHistory(channels: ["SomeChannel"], max: 1, start: 0, end: 1, includeMeta: true)

    XCTAssertEqual(endpoint.associatedValue["channels"] as? [String], ["SomeChannel"])
    XCTAssertEqual(endpoint.associatedValue["max"] as? Int, 1)
    XCTAssertEqual(endpoint.associatedValue["start"] as? Timetoken, 0)
    XCTAssertEqual(endpoint.associatedValue["end"] as? Timetoken, 1)
    XCTAssertEqual(endpoint.associatedValue["includeMeta"] as? Bool, true)
  }

  func testFetchHistory_Success() {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: v2Channels) { result in
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

  func testFetchHistory_Success_IncludeMeta() {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success_withMeta"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: v3Channels) { result in
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

  func testFetchHistory_Success_MultipleChannels() {
    let expectation = self.expectation(description: "Fetch History  Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success_multipleChannels"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: v3Channels) { result in
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

  func testFetchHistory_Success_Encrypted() {
    let expectation = self.expectation(description: "HereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success_encrypted"]) else {
      return XCTFail("Could not create mock url session")
    }

    var configWithCipher = config
    configWithCipher.cipherKey = Crypto(key: "SomeTestString")

    PubNub(configuration: configWithCipher, session: sessions.session)
      .fetchMessageHistory(for: v3Channels) { result in
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

  func testFetchHistory_Success_EncryptedWrongKey() {
    let expectation = self.expectation(description: "HereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success_encrypted"]) else {
      return XCTFail("Could not create mock url session")
    }

    var configWithCipher = config
    configWithCipher.cipherKey = Crypto(key: "NotTheRightKey")

    PubNub(configuration: configWithCipher, session: sessions.session)
      .fetchMessageHistory(for: v3Channels) { result in
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

  func testFetchHistory_Success_MixedEncrypted() {
    let expectation = self.expectation(description: "FetchHistory Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_Fetch_success_mixedEncrypted"]) else {
      return XCTFail("Could not create mock url session")
    }

    var configWithCipher = config
    configWithCipher.cipherKey = Crypto(key: "SomeTestString")

    PubNub(configuration: configWithCipher, session: sessions.session)
      .fetchMessageHistory(for: v3Channels) { result in
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

  func testFetchHistory_Success_EmptyMessages() {
    let expectation = self.expectation(description: "Fetch History V2 Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["messageHistory_FetchV2_success_emptyList"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fetchMessageHistory(for: v3Channels) { result in
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

// MARK: - Delete History

extension MessageHistoryEndpointTests {
  func testDeleteHistory_Endpoint() {
    let endpoint = Endpoint.deleteMessageHistory(channel: testChannel, start: nil, end: nil)

    XCTAssertEqual(endpoint.description, "Delete Message History")
    XCTAssertEqual(endpoint.category, .deleteMessageHistory)
    XCTAssertEqual(endpoint.operationCategory, .history)
    XCTAssertNil(endpoint.validationError)
  }

  func testDeleteHistory_Endpoint_ValidationError() {
    let endpoint = Endpoint.deleteMessageHistory(channel: "", start: nil, end: nil)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testDeleteHistory_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.deleteMessageHistory(channel: "SomeChannel", start: 0, end: 1)

    XCTAssertEqual(endpoint.associatedValue["channel"] as? String, "SomeChannel")
    XCTAssertEqual(endpoint.associatedValue["start"] as? Timetoken, 0)
    XCTAssertEqual(endpoint.associatedValue["end"] as? Timetoken, 1)
  }

  func testDeleteHistory_Success() {
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
        XCTAssertEqual(error.pubNubError, PubNubError(reason: .messageDeletionNotEnabled))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Response Decoder

extension MessageHistoryEndpointTests {
  func testResponseDecoder_Decode_Failure() {
    guard let url = URL(string: "http://example.com") else {
      return XCTFail("Could not create URL")
    }

    let router = PubNubRouter(configuration: PubNubConfiguration.default, endpoint: .time)
    let request = URLRequest(url: url)
    let urlResponse = HTTPURLResponse(url: url, mimeType: nil, expectedContentLength: 200, textEncodingName: nil)
    let response = Response<Data>(router: router,
                                  request: request,
                                  response: urlResponse,
                                  payload: Data())
    do {
      _ = try MessageHistoryResponseDecoder().decode(response: response).get()
      XCTFail("This should throw an error")
    } catch {
      XCTAssertEqual(error.pubNubError, PubNubError(reason: .jsonDataDecodingFailure))
    }
  }

  func testDecodeMessageHistoryV2_WrongEndpoint() {
    guard let url = URL(string: "http://example.com") else {
      return XCTFail("Could not create URL")
    }

    let router = PubNubRouter(configuration: PubNubConfiguration.default, endpoint: .time)
    let request = URLRequest(url: url)
    let urlResponse = HTTPURLResponse(url: url, mimeType: nil, expectedContentLength: 200, textEncodingName: nil)

    guard let responseData = "[]".data(using: .utf8) else {
      return XCTFail("Could not create data from string json")
    }

    let response = Response<Data>(router: router,
                                  request: request,
                                  response: urlResponse,
                                  payload: responseData)
    do {
      _ = try MessageHistoryResponseDecoder().decodeMessageHistoryV2(response: response).get()
      XCTFail("This should throw an error")
    } catch {
      XCTAssertEqual(error.pubNubError, PubNubError(reason: .malformedResponseBody))
    }
  }
}

// swiftlint:enable file_length
