//
//  UserTestHelpers.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
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
      request: .init(url: URL(string: "example.com")!),
      response: .init(),
      payload: data ?? Data()
    )
  }
}
