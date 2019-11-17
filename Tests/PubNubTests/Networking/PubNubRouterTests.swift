//
//  PubNubRouterTests.swift
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

class PubNubRouterTests: XCTestCase {
  static let testState = ["TestChannel": ["Value": AnyJSON([0])]]

  static let time = Endpoint.time
  static let publish = Endpoint.publish(message: AnyJSON([0]),
                                        channel: "TestChannel",
                                        shouldStore: nil,
                                        ttl: nil,
                                        meta: nil)
  static let compressedPublish = Endpoint.compressedPublish(message: AnyJSON([0]),
                                                            channel: "TestChannel",
                                                            shouldStore: nil,
                                                            ttl: nil,
                                                            meta: nil)
  static let fire = Endpoint.fire(message: AnyJSON([0]), channel: "TestChannel", meta: nil)
  static let subscribe = Endpoint.subscribe(channels: ["TestChannel"],
                                            groups: ["TestGroup"],
                                            timetoken: 1111,
                                            region: "0",
                                            state: PubNubRouterTests.testState,
                                            heartbeat: 300, filter: "Test Filter")

  static let config = PubNubConfiguration(publishKey: "TestKeyNotReal", subscribeKey: "TestKeyNotReal")

  let timeRouter = PubNubRouter(configuration: config, endpoint: time)
  let publishRouter = PubNubRouter(configuration: config, endpoint: publish)
  let compressedPublishRouter = PubNubRouter(configuration: config, endpoint: compressedPublish)
  let fireRouter = PubNubRouter(configuration: config, endpoint: fire)
  let subscribeRouter = PubNubRouter(configuration: config, endpoint: subscribe)

  struct NonCodable: Equatable {
    var code = 0
  }

  // Temporary Tests until endpoints are added to PubNub
  func testPamVersions() {
    XCTAssertEqual(timeRouter.pamVersion, .none)
    XCTAssertEqual(publishRouter.pamVersion, .version2)
    XCTAssertEqual(compressedPublishRouter.pamVersion, .version2)
    XCTAssertEqual(fireRouter.pamVersion, .version2)
    XCTAssertEqual(subscribeRouter.pamVersion, .version2)
  }

  func testSubscribe() {
    guard let subscribeKey = PubNubRouterTests.config.subscribeKey else {
      return XCTFail("Could not get the subscribe key from the configuration")
    }

    let stringState = try? AnyJSON(PubNubRouterTests.testState).jsonStringifyResult.get()

    let queryItems = [
      URLQueryItem(name: "tt", value: "1111"),
      URLQueryItem(name: "channel-group", value: "TestGroup"),
      URLQueryItem(name: "tr", value: "0"),
      URLQueryItem(name: "filter-expr", value: "Test Filter"),
      URLQueryItem(name: "heartbeat", value: "300"),
      URLQueryItem(name: "state", value: stringState)
    ]

    XCTAssertEqual(subscribeRouter.method, .get)
    XCTAssertEqual(subscribeRouter.keysRequired, .subscribe)
    XCTAssertEqual(try? subscribeRouter.path.get(), "/v2/subscribe/\(subscribeKey)/TestChannel/0")
    XCTAssertEqual(try? subscribeRouter.queryItems.get(), subscribeRouter.defaultQueryItems + queryItems)
    XCTAssertNoThrow(try subscribeRouter.body.get())
  }

  func testSubscribe_MissingTimetoken() {
    let subscribe = Endpoint.subscribe(channels: ["TestChannel"],
                                       groups: [],
                                       timetoken: 0,
                                       region: nil,
                                       state: nil,
                                       heartbeat: nil,
                                       filter: nil)
    let subscribeRouter = PubNubRouter(configuration: PubNubRouterTests.config, endpoint: subscribe)

    let queryItems = [
      URLQueryItem(name: "tt", value: "0")
    ]

    XCTAssertEqual(try? subscribeRouter.queryItems.get(), subscribeRouter.defaultQueryItems + queryItems)
  }

  // End Temporary Tests

  // MARK: - Special Encoding Tests

  func testPathContainsForwardSlash() {
    let testMessage = AnyJSON(["/test/message/with/slashes/"])
    let testChannel = "/test/channel/"

    let publish = Endpoint.publish(message: testMessage, channel: testChannel, shouldStore: nil, ttl: nil, meta: nil)
    let publishRouter = PubNubRouter(configuration: PubNubRouterTests.config, endpoint: publish)

    guard let url = try? publishRouter.asURL.get() else {
      return XCTFail("Could not create url")
    }

    var testPath = "/publish/TestKeyNotReal/TestKeyNotReal/0"
    let encodedChannel = testChannel.urlEncodeSlash
    // URLEncode the path like it would be done inside the URL
    guard let encodedMessage = testMessage.description
      .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
      return XCTFail("Message could not be encoded")
    }
    // Perform the additional encoding to sanitize the forward slashes
    testPath = "\(testPath)/\(encodedChannel)/0/\(encodedMessage.urlEncodeSlash)"

    // url.path with print without being percent encoded, but will in fact be percent encoded
    XCTAssertFalse(url.description.contains(url.path))
    XCTAssertTrue(url.description.contains(testPath))
  }

  func testQueryContainsSpecialCharacters() {
    let uuid = "UUID+With+Questions?"
    let encodedUUID = "UUID%2BWith%2BQuestions%3F"
    var config = PubNubConfiguration(publishKey: "demo", subscribeKey: "demo")
    config.uuid = uuid

    let publish = Endpoint.publish(message: "TestMessage", channel: "Test", shouldStore: nil, ttl: nil, meta: nil)
    let publishRouter = PubNubRouter(configuration: config, endpoint: publish)

    guard let url = try? publishRouter.asURL.get(),
      let comps = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
      return XCTFail("Could not create url")
    }

    guard let encodedQuery = comps.percentEncodedQuery else {
      return XCTFail("Could not get query from url")
    }

    XCTAssertFalse(encodedQuery.contains(uuid))
    XCTAssertTrue(encodedQuery.contains(encodedUUID))
  }

  func testInvalidMeta() {
    var expectations = [XCTestExpectation]()

    let nonCodable = NonCodable()
    let failedJSON = AnyJSON([nonCodable])

    let fireWithMeta = Endpoint.fire(message: AnyJSON([0]), channel: "TestChannel", meta: failedJSON)
    let metaErrorRouter = PubNubRouter(configuration: PubNubRouterTests.config, endpoint: fireWithMeta)

    let sessionListener = SessionListener()
    let sessionExpector = SessionExpector(session: sessionListener)

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_invalid_key"], with: sessionListener) else {
      return XCTFail("Could not create mock url session")
    }

    sessionExpector.expectDidFailToCreateURLRequestWithError { _, error in
      XCTAssertEqual(error.pubNubError, PubNubError(reason: .jsonStringEncodingFailure))
    }

    let expectation = self.expectation(description: "Publish Response Received")
    sessions
      .session?
      .request(with: metaErrorRouter)
      .validate()
      .response(on: .main, decoder: PublishResponseDecoder()) { result in
        switch result {
        case .success:
          XCTFail("Publish request should fail")
        case let .failure(error):
          XCTAssertNotNil(error.pubNubError)
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .jsonStringEncodingFailure))
        }
        expectation.fulfill()
      }
    expectations.append(expectation)

    XCTAssertEqual(sessionExpector.expectations.count, 1)
    expectations.append(contentsOf: sessionExpector.expectations)

    wait(for: expectations, timeout: 1.0)
  }

  func testInvalidPath_Publish() {
    var expectations = [XCTestExpectation]()

    let nonCodable = NonCodable()
    let failedJSON = AnyJSON([nonCodable])

    let fireWithMeta = Endpoint.fire(message: failedJSON, channel: "TestChannel", meta: AnyJSON([0]))
    let metaErrorRouter = PubNubRouter(configuration: PubNubRouterTests.config, endpoint: fireWithMeta)

    let sessionListener = SessionListener()
    let sessionExpector = SessionExpector(session: sessionListener)

    guard let sessions = try? MockURLSession.mockSession(for: ["publish_invalid_key"], with: sessionListener) else {
      return XCTFail("Could not create mock url session")
    }

    sessionExpector.expectDidFailToCreateURLRequestWithError { _, error in
      XCTAssertEqual(error.pubNubError, PubNubError(reason: .jsonStringEncodingFailure))
    }

    let expectation = self.expectation(description: "Publish Response Received")
    sessions
      .session?
      .request(with: metaErrorRouter)
      .validate()
      .response(on: .main, decoder: PublishResponseDecoder()) { result in
        switch result {
        case .success:
          XCTFail("Publish request should fail")
        case let .failure(error):
          XCTAssertNotNil(error.pubNubError)
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .jsonStringEncodingFailure))
        }
        expectation.fulfill()
      }
    expectations.append(expectation)

    XCTAssertEqual(sessionExpector.expectations.count, 1)
    expectations.append(contentsOf: sessionExpector.expectations)

    wait(for: expectations, timeout: 1.0)
  }
}
