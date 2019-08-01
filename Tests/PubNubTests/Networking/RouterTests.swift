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
                                     region: 0,
                                     state: AnyJSON([0]))

  struct NonCodable: Equatable {
    var code = 0
  }

  struct PublishOnlyRouter: Router {
    var endpoint: Endpoint = .time
    var configuration: RouterConfiguration
    var method: HTTPMethod = .get

    var testablePathPayload = AnyJSON(["Key": "Value"])
    func path() throws -> String {
      return try "some/path/\(testablePathPayload.jsonString())"
    }

    var additionalHeaders: HTTPHeaders = []
    func queryItems() throws -> [URLQueryItem] {
      return []
    }

    var body: AnyJSON?
    var keysRequired: PNKeyRequirement = .publish
    var pamVersion: PAMVersionRequirement = .version3
    func decodeError(request _: URLRequest, response _: HTTPURLResponse, for _: Data?) -> PNError? {
      return nil
    }

    init(config: RouterConfiguration) {
      configuration = config
    }
  }

  func testDefaultQueryItems_WithAuthKey() {
    var config = PubNubConfiguration(publishKey: "TestKeyNotReal", subscribeKey: "TestKeyNotReal")
    config.authKey = "SomeAuthKey"

    let router = PubNubRouter(configuration: config, endpoint: .time)
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

    XCTAssertEqual(router.keyValidationError, PNError.requestCreationFailure(.missingPublishKey))
  }

  func testKeyValidationError_SubscribeReq() {
    let config = PubNubConfiguration(publishKey: nil, subscribeKey: "TestKeyNotReal")
    let router = PubNubRouter(configuration: config, endpoint: subscribe)

    XCTAssertNil(router.keyValidationError)
  }

  func testKeyValidationError_SubscribeReq_MissingKey() {
    let config = PubNubConfiguration(publishKey: nil, subscribeKey: nil)
    let router = PubNubRouter(configuration: config, endpoint: subscribe)

    XCTAssertEqual(router.keyValidationError, PNError.requestCreationFailure(.missingSubscribeKey))
  }

  func testURLEncodeSlash() {
    let router = PubNubRouter(configuration: PubNubConfiguration.default, endpoint: .time)

    let userInput = router.urlEncodeSlash(path: "unsanitary/input")
    let path = "/path/component/\(userInput)/end"

    let sanitaryInput = userInput.replacingOccurrences(of: "/", with: "%2F")
    let sanitaryPath = "/path/component/\(sanitaryInput)/end"

    XCTAssertEqual(path, sanitaryPath)
  }

  func testAsRequest_Error_Unknown() {
    let payload = [NonCodable(code: 0)]

    let config = PubNubConfiguration(publishKey: "TestKeyNotReal", subscribeKey: "TestKeyNotReal")

    var router = PublishOnlyRouter(config: config)
    router.body = AnyJSON(payload)
    router.testablePathPayload = AnyJSON(payload)

    switch router.asURL {
    case .success:
      XCTFail("The URL Convertible should always fail")
    case let .failure(error):
      let context = EncodingError.Context(
        codingPath: [],
        debugDescription: ErrorDescription.EncodingError.invalidUnkeyedContainerErrorDescription
      )

      let encodingError = EncodingError.invalidValue(payload, context)
      let pnError = PNError.requestCreationFailure(.unknown(encodingError))
      XCTAssertEqual(error.pubNubError, pnError)
    }
  }
}
