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
//  let subscribe = Endpoint.subscribe(channels: ["TestChannel"],
//                                     groups: ["TestGroup"],
//                                     timetoken: 1111,
//                                     region: "0",
//                                     state: ["TestChannel": ["Value": AnyJSON([0])]],
//                                     heartbeat: nil, filter: nil)

  struct NonCodable: Equatable {
    var code = 0
  }

  struct PublishOnlyRouter: HTTPRouter {
    var service: PubNubService = .time
    var category: String = "Time"

    var validationError: Error?

    var configuration: RouterConfiguration {
      var config = PubNubConfiguration()
      config.authKey = "SomeAuthKey"
      return config
    }
    var method: HTTPMethod = .get

    var testablePathPayload = AnyJSON(["Key": "Value"])
    var path: Result<String, Error> {
      return testablePathPayload.jsonStringifyResult.map {
        "some/path/\($0.urlEncodeSlash)"
      }
    }

    var additionalHeaders: [String: String] = [:]
    var queryItems: Result<[URLQueryItem], Error> {
      return .success([])
    }

    var keysRequired: PNKeyRequirement = .publish

    var body: Result<Data?, Error> = .success(nil)
    func decodeError(router _: HTTPRouter,
                     request _: URLRequest,
                     response _: HTTPURLResponse,
                     for _: Data) -> PubNubError? {
      return nil
    }
  }

//  func testDefaultQueryItems_NoAuthKey() {
//    var config = PubNubConfiguration(publishKey: "TestKeyNotReal", subscribeKey: "TestKeyNotReal")
//    config.authKey = "SomeAuthKey"
//
//    let router = TimeRouter(.time, configuration: config)
//    let queryItems = [
//      URLQueryItem(name: "pnsdk", value: Constant.pnSDKQueryParameterValue),
//      URLQueryItem(name: "uuid", value: config.uuid)
//    ]
//
//    XCTAssertEqual(router.defaultQueryItems, queryItems)
//  }

//  func testDefaultQueryItems_WithAuthKey() {
//    let router = PublishOnlyRouter()
//    let queryItems = [
//      URLQueryItem(name: "pnsdk", value: Constant.pnSDKQueryParameterValue),
//      URLQueryItem(name: "uuid", value: router.configuration.uuid)
//    ]
//
//    XCTAssertEqual(router.defaultQueryItems, queryItems)
//  }

//  func testKeyValidationError_SubscribeReq() {
//    let router = PublishOnlyRouter()
//
//    XCTAssertNil(router.keyValidationErrorReason)
//  }

//  func testKeyValidationError_SubscribeReq_MissingKey() {
//    let router = PublishOnlyRouter()
//
//    XCTAssertEqual(router.keyValidationErrorReason, .missingSubscribeKey)
//  }

//  func testAsURL_Error_Unknown() {
//    let payload = [NonCodable(code: 0)]
//
//    var router = PublishOnlyRouter()
//    router.body = AnyJSON(payload).jsonDataResult.map { .some($0) }
//    router.testablePathPayload = AnyJSON(payload)
//
//    switch router.asURL {
//    case .success:
//      XCTFail("The URL Convertible should always fail")
//    case let .failure(error):
//      XCTAssertEqual(error.anyJSON, AnyJSONError.stringCreationFailure(nil))
//    }
//  }
}
