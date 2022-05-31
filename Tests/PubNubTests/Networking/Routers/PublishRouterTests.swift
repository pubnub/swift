//
//  PublishRouterTests.swift
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

final class PublishRouterTests: XCTestCase {
  var config = PubNubConfiguration(
    publishKey: "FakeTestString",
    subscribeKey: "FakeTestString",
    uuid: UUID().uuidString,
    authKey: "auth-key"
  )

  let testMessage: AnyJSON = "Test Message"
  let testChannel = "TestChannel"
  let testFileId = "FileId"
  let testFilename = "exampe.txt"
  let testCustom = ["purpose": "file testing"]
}

// MARK: - Publish

extension PublishRouterTests {
  func testPublish_Router() {
    let router = PublishRouter(
      .publish(message: testMessage, channel: testChannel, shouldStore: nil, ttl: nil, meta: nil),
      configuration: config
    )

    guard let queryItems = try? router.queryItems.get() else {
      return XCTAssert(false, "'queryItems' not set")
    }

    XCTAssertTrue(queryItems.contains(URLQueryItem(name: "auth", value: "auth-key")))
    XCTAssertEqual(router.endpoint.description, "Publish")
    XCTAssertEqual(router.category, "Publish")
    XCTAssertEqual(router.service, .publish)
  }

  func testPublish_Router_ValidationError() {
    let router = PublishRouter(
      .publish(message: [], channel: testChannel, shouldStore: nil, ttl: nil, meta: nil),
      configuration: config
    )

    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))
  }

  func testPublish_Success() {
    let expectation = self.expectation(description: "Publish Response Received")
    config.authToken = "access-token"

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .publish(channel: "Test", message: ["text": "Hello"]) { result in
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

  func testPublish_MessageTooLongError() {
    let expectation = self.expectation(description: "Message Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_message_too_large"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .publish(channel: "Test", message: ["text": "Hello"]) { result in
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

  func testPublish_Error_InvalidKey() {
    let expectation = self.expectation(description: "Publish Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_invalid_key"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .publish(channel: "Test", message: ["text": "Hello"]) { result in
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

  func testPublish_Error_SystemSupplied() {
    let expectation = self.expectation(description: "Publish Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["requestURITooLong_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .publish(channel: "Test", message: ["text": "Hello"]) { result in
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

  func testPublish_Error_MissingPublishKey() {
    let expectation = self.expectation(description: "Publish Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_invalid_key"]) else {
      return XCTFail("Could not create mock url session")
    }

    let missingPublishConfig = PubNubConfiguration(publishKey: nil, subscribeKey: "NotARealKey", uuid: UUID().uuidString)

    PubNub(configuration: missingPublishConfig, session: sessions.session)
      .publish(channel: "Test", message: ["text": "Hello"]) { result in
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

  func testPublish_Error_MissingSubscribeKey() {
    let expectation = self.expectation(description: "Publish Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_invalid_key"]) else {
      return XCTFail("Could not create mock url session")
    }

    let missingPublishConfig = PubNubConfiguration(publishKey: "NotARealKey", subscribeKey: "", uuid: UUID().uuidString)

    PubNub(configuration: missingPublishConfig, session: sessions.session)
      .publish(channel: "Test", message: ["text": "Hello"]) { result in
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

  func testPublish_Error_MissingPublishAndSubscribeKey() {
    let expectation = self.expectation(description: "Publish Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_invalid_key"]) else {
      return XCTFail("Could not create mock url session")
    }

    let missingPublishConfig = PubNubConfiguration(publishKey: nil, subscribeKey: "", uuid: UUID().uuidString)

    PubNub(configuration: missingPublishConfig, session: sessions.session)
      .publish(channel: "Test", message: ["text": "Hello"]) { result in
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
  func testCompressedPublish_Router() {
    let router = PublishRouter(
      .compressedPublish(message: testMessage, channel: testChannel, shouldStore: nil, ttl: nil, meta: nil),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Compressed Publish")
    XCTAssertEqual(router.category, "Compressed Publish")
    XCTAssertEqual(router.service, .publish)
  }

  func testCompressedPublish_Router_ValidationError() {
    let router = PublishRouter(
      .compressedPublish(message: [], channel: testChannel, shouldStore: nil, ttl: nil, meta: nil),
      configuration: config
    )

    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))
  }

  func testCompressedPublish_Success() {
    let expectation = self.expectation(description: "Publish Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .publish(channel: "Test", message: ["text": "Hello"], shouldCompress: true) { result in
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
  func testFile_Router() {
    let router = PublishRouter(
      .file(
        message: FilePublishPayload(channel: testChannel, fileId: testFileId, filename: testFilename),
        shouldStore: nil, ttl: nil, meta: nil
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Publish a File Message")
    XCTAssertEqual(router.category, "Publish a File Message")
    XCTAssertEqual(router.service, .publish)
  }

  func testFile_Router_Validate_Message() {
    let file = FilePublishPayload(
      channel: "",
      fileId: testFileId, filename: testFilename,
      additionalDetails: testCustom
    )

    do {
      let jsonMessage = try ImportTestResource.importResource("publish_file_body_raw")
      let jsonFilePublish = try Constant.jsonDecoder.decode(FilePublishPayload.self, from: jsonMessage)

      XCTAssertEqual(file, jsonFilePublish)
    } catch {
      XCTFail("Could not create test resources due to \(error)")
    }
  }

  func testFile_Router_ValidationError_EmptyChannel() {
    let router = PublishRouter(
      .file(
        message: FilePublishPayload(channel: "", fileId: testFileId, filename: testFilename),
        shouldStore: nil, ttl: nil, meta: nil
      ),
      configuration: config
    )
    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))
  }

  func testFile_Router_ValidationError_EmptyFileId() {
    let router = PublishRouter(
      .file(
        message: FilePublishPayload(channel: testChannel, fileId: "", filename: testFilename),
        shouldStore: nil, ttl: nil, meta: nil
      ),
      configuration: config
    )
    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))
  }

  func testFile_Router_ValidationError_EmptyFilename() {
    let router = PublishRouter(
      .file(
        message: FilePublishPayload(channel: testChannel, fileId: testFileId, filename: ""),
        shouldStore: nil, ttl: nil, meta: nil
      ),
      configuration: config
    )
    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))
  }

  func testFile_Success() {
    let expectation = self.expectation(description: "Publish Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let file = FilePublishPayload(channel: testChannel, fileId: testFileId, filename: testFilename)

    PubNub(configuration: config, session: sessions.session)
      .publish(file: file, request: .init(additionalMessage: ["text": "Hello"])) { result in
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

  func testFile_MessageTooLongError() {
    let expectation = self.expectation(description: "Message Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_message_too_large"]) else {
      return XCTFail("Could not create mock url session")
    }

    let file = FilePublishPayload(channel: testChannel, fileId: testFileId, filename: testFilename)

    PubNub(configuration: config, session: sessions.session)
      .publish(file: file, request: .init(additionalMessage: ["text": "Hello"])) { result in
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
  func testFire_Router() {
    let router = PublishRouter(.fire(message: testMessage, channel: testChannel, meta: nil), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Fire")
    XCTAssertEqual(router.category, "Fire")
    XCTAssertEqual(router.service, .publish)
  }

  func testFire_Router_ValidationError() {
    let router = PublishRouter(.fire(message: [], channel: testChannel, meta: nil), configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))
  }

  func testFire_Success() {
    let expectation = self.expectation(description: "Publish Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .fire(channel: "Test", message: ["text": "Hello"], meta: ["metaKey": "metaValue"]) { result in
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
  func testSignal_Router() {
    let router = PublishRouter(.signal(message: testMessage, channel: testChannel), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Signal")
    XCTAssertEqual(router.category, "Signal")
    XCTAssertEqual(router.service, .publish)
  }

  func testSignal_Router_ValidationError() {
    let router = PublishRouter(.signal(message: "", channel: testChannel), configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))
  }

  func testSignal_Success() {
    let expectation = self.expectation(description: "Signal Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .signal(channel: "Test", message: ["text": "Hello"]) { result in
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

  func testSignal_Error() {
    let expectation = self.expectation(description: "Signal Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_invalid_key"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .signal(channel: "Test", message: ["text": "Hello"]) { result in
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

  func testSignal_Error_MessageTooLarge() {
    let expectation = self.expectation(description: "Signal Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["signal_message_too_large"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .signal(channel: "Test", message: ["text": "Hello"]) { result in
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

  func testSignal_Error_SystemSupplied() {
    let expectation = self.expectation(description: "Signal Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["requestURITooLong_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .signal(channel: "Test", message: ["text": "Hello"]) { result in
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

  // swiftlint:disable:next file_length
}
