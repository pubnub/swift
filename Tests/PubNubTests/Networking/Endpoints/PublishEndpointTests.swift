//
//  PublishEndpointTests.swift
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

final class PublishEndpointTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  // MARK: - Publish

  func testPublish_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.publish(message: "Hello", channel: "SomeChannel", shouldStore: true, ttl: 1, meta: "Meta")

    XCTAssertEqual(endpoint.associatedValue["message"] as? AnyJSON, AnyJSON("Hello"))
    XCTAssertEqual(endpoint.associatedValue["channel"] as? String, "SomeChannel")
    XCTAssertEqual(endpoint.associatedValue["shouldStore"] as? Bool, true)
    XCTAssertEqual(endpoint.associatedValue["ttl"] as? Int, 1)
    XCTAssertEqual(endpoint.associatedValue["meta"] as? AnyJSON, AnyJSON("Meta"))
  }

  // MARK: - Signal

  func testSignal_Endpoint() {
    let channel = "TestChannel"
    let message = "TestMessage"
    let endpoint = Endpoint.signal(message: AnyJSON(message), channel: channel)

    XCTAssertEqual(endpoint.description, "Signal")
    XCTAssertEqual(endpoint.category, .signal)
    XCTAssertEqual(endpoint.operationCategory, .publish)
    XCTAssertNil(endpoint.validationError)
  }

  func testSignal_Endpoint_ValidationError() {
    let endpoint = Endpoint.signal(message: "", channel: "")

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testSignal_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.signal(message: "Hello", channel: "SomeChannel")

    XCTAssertEqual(endpoint.associatedValue["message"] as? AnyJSON, AnyJSON("Hello"))
    XCTAssertEqual(endpoint.associatedValue["channel"] as? String, "SomeChannel")
  }

  func testSignal_Success() {
    let expectation = self.expectation(description: "Signal Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .signal(channel: "Test", message: ["text": "Hello"]) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.timetoken, 15_644_265_196_692_560)
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .invalidPublishKey))
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
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .requestURITooLong))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }
}
