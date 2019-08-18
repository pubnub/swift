//
//  RouterTests.swift
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

class RouterTests: XCTestCase {
  let subscribe = Endpoint.subscribe(channels: ["TestChannel"],
                                     groups: ["TestGroup"],
                                     timetoken: 1111,
                                     region: "0",
                                     state: ["TestChannel": ["Value": AnyJSON([0])]],
                                     heartbeat: nil, filter: nil)

  struct NonCodable: Equatable {
    var code = 0
  }

  struct PublishOnlyRouter: Router {
    var endpoint: Endpoint = .time
    var configuration: RouterConfiguration
    var method: HTTPMethod = .get

    var testablePathPayload = AnyJSON(["Key": "Value"])
    var path: Result<String, Error> {
      return testablePathPayload.jsonStringifyResult.map {
        "some/path/\($0.urlEncodeSlash)"
      }
    }

    var additionalHeaders: HTTPHeaders = []
    var queryItems: Result<[URLQueryItem], Error> {
      return .success([])
    }

    var body: Result<Data?, Error> = .success(nil)
    var keysRequired: PNKeyRequirement = .publish
    var pamVersion: PAMVersionRequirement = .version3
    func decodeError(endpoint _: Endpoint,
                     request _: URLRequest,
                     response _: HTTPURLResponse,
                     for _: Data?) -> PNError? {
      return nil
    }

    init(config: RouterConfiguration) {
      configuration = config
    }
  }

  func testDefaultQueryItems_NoAuthKey() {
    var config = PubNubConfiguration(publishKey: "TestKeyNotReal", subscribeKey: "TestKeyNotReal")
    config.authKey = "SomeAuthKey"

    let router = PubNubRouter(configuration: config, endpoint: .time)
    let queryItems = [
      URLQueryItem(name: "pnsdk", value: Constant.pnSDKQueryParameterValue),
      URLQueryItem(name: "uuid", value: config.uuid)
    ]

    XCTAssertEqual(router.defaultQueryItems, queryItems)
  }

  func testDefaultQueryItems_WithAuthKey() {
    var config = PubNubConfiguration(publishKey: "TestKeyNotReal", subscribeKey: "TestKeyNotReal")
    config.authKey = "SomeAuthKey"

    let router = PubNubRouter(configuration: config, endpoint: .fire(message: AnyJSON([]), channel: "Test", meta: nil))
    let queryItems = [
      URLQueryItem(name: "pnsdk", value: Constant.pnSDKQueryParameterValue),
      URLQueryItem(name: "uuid", value: config.uuid),
      URLQueryItem(name: "auth", value: config.authKey)
    ]

    XCTAssertEqual(router.defaultQueryItems, queryItems)
  }

  func testKeyValidationError_PublishReq() {
    let config = PubNubConfiguration(publishKey: "TestKeyNotReal", subscribeKey: nil)
    let router = PublishOnlyRouter(config: config)

    XCTAssertNil(router.keyValidationError)
  }

  func testKeyValidationError_PublishReq_MissingKey() {
    let config = PubNubConfiguration(publishKey: nil, subscribeKey: nil)
    let router = PublishOnlyRouter(config: config)

    XCTAssertEqual(router.keyValidationError, PNError.requestCreationFailure(.missingPublishKey, router.endpoint))
  }

  func testKeyValidationError_SubscribeReq() {
    let config = PubNubConfiguration(publishKey: nil, subscribeKey: "TestKeyNotReal")
    let router = PubNubRouter(configuration: config, endpoint: subscribe)

    XCTAssertNil(router.keyValidationError)
  }

  func testKeyValidationError_SubscribeReq_MissingKey() {
    let config = PubNubConfiguration(publishKey: nil, subscribeKey: nil)
    let router = PubNubRouter(configuration: config, endpoint: subscribe)

    XCTAssertEqual(router.keyValidationError, PNError.requestCreationFailure(.missingSubscribeKey, router.endpoint))
  }

  func testAsURL_Error_Unknown() {
    let payload = [NonCodable(code: 0)]

    let config = PubNubConfiguration(publishKey: "TestKeyNotReal", subscribeKey: "TestKeyNotReal")

    var router = PublishOnlyRouter(config: config)
    router.body = AnyJSON(payload).jsonDataResult.map { .some($0) }
    router.testablePathPayload = AnyJSON(payload)

    switch router.asURL {
    case .success:
      XCTFail("The URL Convertible should always fail")
    case let .failure(error):
      let pnError = PNError.requestCreationFailure(.unknown(AnyJSONError.stringCreationFailure(nil)), router.endpoint)
      XCTAssertEqual(error.pubNubError, pnError)
    }
  }
}
