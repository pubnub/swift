//
//  PubNubTests.swift
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

final class PubNubTests: XCTestCase {
  let testBundle = Bundle(for: PubNubTests.self)
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  func testInit_DefaultConfig() {
    XCTAssertEqual(PubNub().configuration, PubNubConfiguration.default)
  }

  func testInit_CustomConfig() {
    let customConfig = PubNubConfiguration(from: testBundle)

    let pubnub = PubNub(configuration: customConfig)

    XCTAssertNotEqual(pubnub.configuration, PubNubConfiguration.default)
  }

  func testTime_Success() {
    let expectation = self.expectation(description: "Time Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["time_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    pubnub = PubNub(configuration: .default, session: sessions.session)
    pubnub.time { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.timetoken, 15_643_405_135_132_358)
      case let .failure(error):
        XCTFail("Time request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testPublish_Success() {
    let expectation = self.expectation(description: "Publish Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.publish(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.timetoken, 15_644_265_196_692_560)
      case let .failure(error):
        XCTFail("Publish request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testCompressedPublish_Success() {
    let expectation = self.expectation(description: "Publish Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.publish(channel: "Test", message: ["text": "Hello"], shouldCompress: true) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.timetoken, 15_644_265_196_692_560)
      case let .failure(error):
        XCTFail("Publish request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testFire_Success() {
    let expectation = self.expectation(description: "Publish Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.fire(channel: "Test", message: ["text": "Hello"], meta: ["metaKey": "metaValue"]) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.timetoken, 15_644_265_196_692_560)
      case let .failure(error):
        XCTFail("Publish request failed with error: \(error.localizedDescription)")
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
          guard let task = sessions.mockSession.tasks.first else {
            return XCTFail("Could not get task")
          }
          let invalidKeyError = PNError.convert(endpoint: .unknown,
                                                generalError: .init(message: .invalidPublishKey,
                                                                    service: .publish,
                                                                    status: .badRequest,
                                                                    error: true),
                                                request: task.mockRequest,
                                                response: task.mockResponse)

          XCTAssertNotNil(error.pubNubError)
          XCTAssertEqual(error.pubNubError, invalidKeyError)
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

    pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.publish(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        guard let task = sessions.mockSession.tasks.first else {
          return XCTFail("Could not get task")
        }
        let invalidKeyError = PNError.convert(endpoint: .unknown,
                                              generalError: .init(message: .requestURITooLong,
                                                                  service: .balancer,
                                                                  status: .badRequest,
                                                                  error: true),
                                              request: task.mockRequest,
                                              response: task.mockResponse)

        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, invalidKeyError)
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

    let missingPublishConfig = PubNubConfiguration(publishKey: nil, subscribeKey: "NotARealKey")

    pubnub = PubNub(configuration: missingPublishConfig, session: sessions.session)
    pubnub.publish(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        let missingKey = PNError.requestCreationFailure(.missingPublishKey, .unknown)

        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, missingKey)
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

    let missingPublishConfig = PubNubConfiguration(publishKey: "NotARealKey", subscribeKey: nil)

    pubnub = PubNub(configuration: missingPublishConfig, session: sessions.session)
    pubnub.publish(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        let missingKey = PNError.requestCreationFailure(.missingSubscribeKey, .unknown)

        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, missingKey)
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

    let missingPublishConfig = PubNubConfiguration(publishKey: nil, subscribeKey: nil)

    pubnub = PubNub(configuration: missingPublishConfig, session: sessions.session)
    pubnub.publish(channel: "Test", message: ["text": "Hello"]) { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        let missingKey = PNError.requestCreationFailure(.missingPublishAndSubscribeKey, .unknown)

        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, missingKey)
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
