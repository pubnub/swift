//
//  UserTestHelpers.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import PubNub

struct UserCustom: FlatJSONCodable, Hashable {
  var value: String?

  init(
    value: String?
  ) {
    self.value = value
  }

  init(flatJSON: [String: JSONCodableScalar]) {
    self.init(value: flatJSON["value"]?.stringOptional)
  }
}

// MARK: Mock Session

class MockSession: SessionReplaceable {
  func request(with router: HTTPRouter, requestOperator _: RequestOperator?) -> RequestReplaceable {
    return MockRequest(router: router)
  }

  var sessionID: UUID = .init()
  var session: URLSessionReplaceable = URLSession.shared
  var sessionQueue: DispatchQueue = .main
  var defaultRequestOperator: RequestOperator?
  var sessionStream: SessionStream?

  init() {}

  var validateRouter: ((HTTPRouter) -> Void)?
  var provideResponse: (() throws -> (Result<EndpointResponse<Data>, Error>))?

  func route<Decoder>(
    _ router: HTTPRouter,
    responseDecoder: Decoder,
    responseQueue _: DispatchQueue = .main,
    completion: @escaping (Result<EndpointResponse<Decoder.Payload>, Error>) -> Void
  ) where Decoder: ResponseDecoder {
    validateRouter?(router)

    if let response = provideResponse {
      do {
        switch try response() {
        case let .success(endpoint):
          completion(responseDecoder.decode(response: endpoint))
        case let .failure(error):
          completion(.failure(error))
        }
      } catch {
        completion(.failure(error))
      }
    }
  }
}

class MockRequest: RequestReplaceable {
  var sessionID: UUID = .init()
  var requestID: UUID = .init()
  var router: HTTPRouter
  var requestQueue: DispatchQueue = .main
  var requestOperator: RequestOperator?
  var urlRequest: URLRequest?
  var urlResponse: HTTPURLResponse?
  var retryCount: Int = 0
  var isCancelled: Bool = false

  init(
    router: HTTPRouter
  ) {
    self.router = router
  }
}

class MockRouter: HTTPRouter {
  var service: PubNubService = .objects
  var category: String = "mock-objects"
  var configuration: RouterConfiguration = PubNubConfiguration(
    publishKey: "mockRouter-pub",
    subscribeKey: "mockRouter-sub",
    userId: "mockRouter-membershipId"
  )
  var path: Result<String, Error> = .success("mock-path")
  var queryItems: Result<[URLQueryItem], Error> = .success([])
}

extension EndpointResponse where Value == Data {
  init(data: Data?) {
    self.init(
      router: MockRouter(),
      // swiftlint:disable:next force_unwrapping
      request: .init(url: URL(string: "example.com")!),
      response: .init(),
      payload: data ?? Data()
    )
  }
}
