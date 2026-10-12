//
//  HTTPRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import XCTest
@testable import PubNubSDK

final class HTTPRouterTests: XCTestCase {
  let config = TestPubNubFactory.makeConfig(subscribeKey: "demo-sub")

  func test_AsURLRequest_PreservesSuppliedContentType() throws {
    let suppliedContentType = "application/vnd.example+json"
    let router = BodyRouter(configuration: config, additionalHeaders: [Constant.contentTypeHeaderKey: suppliedContentType])

    let request = try router.asURLRequest.get()

    XCTAssertEqual(request.value(forHTTPHeaderField: Constant.contentTypeHeaderKey), suppliedContentType)
    XCTAssertNotEqual(request.value(forHTTPHeaderField: Constant.contentTypeHeaderKey), Constant.defaultContentTypeHeader)
  }

  func test_AsURLRequest_AppliesDefaultContentType() throws {
    let suppliedContentType = "application/vnd.example+json"
    let router = BodyRouter(configuration: config)
    let request = try router.asURLRequest.get()

    XCTAssertEqual(request.value(forHTTPHeaderField: Constant.contentTypeHeaderKey), Constant.defaultContentTypeHeader)
    XCTAssertNotEqual(request.value(forHTTPHeaderField: Constant.contentTypeHeaderKey), suppliedContentType)
  }
}

private struct BodyRouter: HTTPRouter {
  let configuration: RouterConfiguration
  let additionalHeaders: [String: String]

  init(configuration: RouterConfiguration, additionalHeaders: [String: String] = [:]) {
    self.configuration = configuration
    self.additionalHeaders = additionalHeaders
  }

  var service: PubNubService { .unknown }
  var category: String { "HTTPRouter" }
  var method: HTTPMethod { .post }
  var path: Result<String, Error> { .success("/test") }
  var queryItems: Result<[URLQueryItem], Error> { .success(defaultQueryItems) }
  var body: Result<Data?, Error> { .success(Data("{}".utf8)) }
  var keysRequired: PNKeyRequirement { .none }
  var pamVersion: PAMVersionRequirement { .none }
}
