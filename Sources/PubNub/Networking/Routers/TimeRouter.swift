//
//  TimeRouter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Router

struct TimeRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CustomStringConvertible {
    case time

    var description: String {
      return "Time"
    }
  }

  // Init
  init(_ endpoint: Endpoint, configuration: RouterConfiguration) {
    self.endpoint = endpoint
    self.configuration = configuration
  }

  var endpoint: Endpoint
  var configuration: RouterConfiguration

  // Protocol Properties
  var service: PubNubService {
    return .time
  }

  var category: String {
    return endpoint.description
  }

  var path: Result<String, Error> {
    return .success("/time/0")
  }

  var pamVersion: PAMVersionRequirement {
    return .none
  }

  var keysRequired: PNKeyRequirement {
    return .none
  }

  var queryItems: Result<[URLQueryItem], Error> {
    return .success(defaultQueryItems)
  }
}

// MARK: - Response Decoder

struct TimeResponseDecoder: ResponseDecoder {
  func decode(response: EndpointResponse<Data>) -> Result<EndpointResponse<TimeResponsePayload>, Error> {
    do {
      let decodedPayload = try Constant.jsonDecoder.decode([Timetoken].self, from: response.payload)

      guard let timetoken = decodedPayload.first else {
        return .failure(PubNubError(.malformedResponseBody, response: response))
      }

      let decodedResponse = EndpointResponse<TimeResponsePayload>(router: response.router,
                                                                  request: response.request,
                                                                  response: response.response,
                                                                  data: response.data,
                                                                  payload: TimeResponsePayload(timetoken: timetoken))

      return .success(decodedResponse)
    } catch {
      return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error))
    }
  }
}

// MARK: - Response Body

struct TimeResponsePayload: Codable, Hashable {
  let timetoken: Timetoken
}
