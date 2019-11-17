//
//  PushRouter.swift
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

import Foundation

// MARK: - Router

public struct PushRouter: HTTPRouter {
  public enum PushType: String, Codable {
    case apns
    case gcm
    case mpns
  }

  // Nested Endpoint
  public enum Endpoint: CustomStringConvertible {
    case listPushChannels(pushToken: Data, pushType: PushType)
    case modifyPushChannels(pushToken: Data, pushType: PushType, joining: [String], leaving: [String])
    case removeAllPushChannels(pushToken: Data, pushType: PushType)

    public var description: String {
      switch self {
      case .listPushChannels:
        return "List Push Channels"
      case .modifyPushChannels:
        return "Modify Push Channels"
      case .removeAllPushChannels:
        return "Remove All Push Channels"
      }
    }
  }

  // Init
  init(_ endpoint: Endpoint, configuration: RouterConfiguration) {
    self.endpoint = endpoint
    self.configuration = configuration
  }

  public var endpoint: Endpoint
  public var configuration: RouterConfiguration

  // Protocol Properties
  public var service: PubNubService {
    return .push
  }

  public var category: String {
    return endpoint.description
  }

  public var path: Result<String, Error> {
    let path: String

    switch endpoint {
    case .listPushChannels(let pushToken, _):
      path = "/v1/push/sub-key/\(subscribeKey)/devices/\(pushToken.hexEncodedString)"
    case .modifyPushChannels(let pushToken, _, _, _):
      path = "/v1/push/sub-key/\(subscribeKey)/devices/\(pushToken.hexEncodedString)"
    case .removeAllPushChannels(let token, _):
      path = "/v1/push/sub-key/\(subscribeKey)/devices/\(token.hexEncodedString)/remove"
    }
    return .success(path)
  }

  public var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .listPushChannels(_, pushType):
      query.append(URLQueryItem(key: .type, value: pushType.rawValue))
    case let .modifyPushChannels(_, pushType, addChannels, removeChannels):
      query.append(URLQueryItem(key: .type, value: pushType.rawValue))
      query.appendIfNotEmpty(key: .add, value: addChannels)
      query.appendIfNotEmpty(key: .remove, value: removeChannels)
    case let .removeAllPushChannels(_, pushType):
      query.append(URLQueryItem(key: .type, value: pushType.rawValue))
    }

    return .success(query)
  }

  public var pamVersion: PAMVersionRequirement {
    switch endpoint {
    case .listPushChannels:
      return .none
    case .modifyPushChannels:
      return .version2
    case .removeAllPushChannels:
      return .version2
    }
  }

  // Validated
  public var validationErrorDetail: String? {
    switch endpoint {
    case .listPushChannels(let pushToken, _):
      return isInvalidForReason((pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData))
    case let .modifyPushChannels(pushToken, _, addChannels, removeChannels):
      return isInvalidForReason(
        (pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData),
        (addChannels.isEmpty && removeChannels.isEmpty, ErrorDescription.emptyChannelArray)
      )
    case .removeAllPushChannels(let pushToken, _):
      return isInvalidForReason((pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData))
    }
  }
}

// MARK: - Response Decoder

struct RegisteredPushChannelsResponseDecoder: ResponseDecoder {
  func decode(
    response: EndpointResponse<Data>
  ) -> Result<EndpointResponse<RegisteredPushChannelsPayloadResponse>, Error> {
    do {
      let anyJSONPayload = try Constant.jsonDecoder.decode(AnyJSON.self, from: response.payload)

      guard let stringArray = anyJSONPayload.arrayOptional as? [String] else {
        return .failure(PubNubError(.malformedResponseBody, response: response))
      }

      let pushListPayload = RegisteredPushChannelsPayloadResponse(channels: stringArray)

      let decodedResponse = EndpointResponse<RegisteredPushChannelsPayloadResponse>(router: response.router,
                                                                                    request: response.request,
                                                                                    response: response.response,
                                                                                    data: response.data,
                                                                                    payload: pushListPayload)

      return .success(decodedResponse)
    } catch {
      return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error))
    }
  }
}

struct ModifyPushResponseDecoder: ResponseDecoder {
  func decode(response: EndpointResponse<Data>) -> Result<EndpointResponse<GenericServicePayloadResponse>, Error> {
    do {
      let anyJSONPayload = try Constant.jsonDecoder.decode(AnyJSON.self, from: response.payload)

      guard let anyArray = anyJSONPayload.arrayOptional,
        anyArray.first as? Int != nil, anyArray.last as? String != nil else {
        return .failure(PubNubError(.malformedResponseBody, response: response))
      }

      let decodedPayload = GenericServicePayloadResponse(message: .acknowledge,
                                                         service: "push",
                                                         status: 200,
                                                         error: false)

      let decodedResponse = EndpointResponse<GenericServicePayloadResponse>(router: response.router,
                                                                            request: response.request,
                                                                            response: response.response,
                                                                            data: response.data,
                                                                            payload: decodedPayload)

      return .success(decodedResponse)
    } catch {
      return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error))
    }
  }
}

// MARK: - Response Body

public struct RegisteredPushChannelsPayloadResponse: Codable {
  let channels: [String]
}

public struct ErrorMessagePayloadResponse: Codable {
  let error: String
}
