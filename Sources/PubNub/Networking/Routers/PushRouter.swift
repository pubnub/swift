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

struct PushRouter: HTTPRouter {
  // Nested Endpoint
  enum Endpoint: CustomStringConvertible {
    case listPushChannels(pushToken: Data, pushType: PubNub.PushService)
    case managePushChannels(pushToken: Data, pushType: PubNub.PushService, joining: [String], leaving: [String])
    case removeAllPushChannels(pushToken: Data, pushType: PubNub.PushService)
    case manageAPNS(
      pushToken: Data, environment: PubNub.PushEnvironment, topic: String, adding: [String], removing: [String]
    )
    case removeAllAPNS(pushToken: Data, environment: PubNub.PushEnvironment, topic: String)

    var description: String {
      switch self {
      case .listPushChannels:
        return "List Push Channels"
      case .managePushChannels:
        return "Modify Push Channels"
      case .removeAllPushChannels:
        return "Remove All Push Channels"
      case .manageAPNS:
        return "List/Modify APNS Devices"
      case .removeAllAPNS:
        return "Remove all channels from APNS device"
      }
    }

    var addedChannels: [String] {
      switch self {
      case .listPushChannels:
        return []
      case let .managePushChannels(_, _, joining, _):
        return joining
      case .removeAllPushChannels:
        return []
      case let .manageAPNS(_, _, _, adding, _):
        return adding
      case .removeAllAPNS:
        return []
      }
    }

    var removedChannels: [String] {
      switch self {
      case .listPushChannels:
        return []
      case let .managePushChannels(_, _, _, leaving):
        return leaving
      case .removeAllPushChannels:
        return []
      case let .manageAPNS(_, _, _, _, removing):
        return removing
      case .removeAllAPNS:
        return []
      }
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
    return .push
  }

  var category: String {
    return endpoint.description
  }

  var path: Result<String, Error> {
    let path: String

    switch endpoint {
    case let .listPushChannels(pushToken, _):
      path = "/v1/push/sub-key/\(subscribeKey)/devices/\(pushToken.hexEncodedString)"
    case let .managePushChannels(pushToken, _, _, _):
      path = "/v1/push/sub-key/\(subscribeKey)/devices/\(pushToken.hexEncodedString)"
    case let .removeAllPushChannels(token, _):
      path = "/v1/push/sub-key/\(subscribeKey)/devices/\(token.hexEncodedString)/remove"
    case let .manageAPNS(token, _, _, _, _):
      path = "/v2/push/sub-key/\(subscribeKey)/devices-apns2/\(token.hexEncodedString)"
    case let .removeAllAPNS(token, _, _):
      path = "/v2/push/sub-key/\(subscribeKey)/devices-apns2/\(token.hexEncodedString)/remove"
    }
    return .success(path)
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .listPushChannels(_, pushType):
      query.append(URLQueryItem(key: .type, value: pushType.rawValue))
    case let .managePushChannels(_, pushType, joining, removing):
      query.append(URLQueryItem(key: .type, value: pushType.rawValue))
      query.appendIfNotEmpty(key: .add, value: joining)
      query.appendIfNotEmpty(key: .remove, value: removing)
    case let .removeAllPushChannels(_, pushType):
      query.append(URLQueryItem(key: .type, value: pushType.rawValue))
    case let .manageAPNS(_, environment, topic, adding, removing):
      query.append(URLQueryItem(key: .environment, value: environment.rawValue))
      query.append(URLQueryItem(key: .topic, value: topic))
      query.appendIfNotEmpty(key: .add, value: adding)
      query.appendIfNotEmpty(key: .remove, value: removing)
    case let .removeAllAPNS(_, environment, topic):
      query.append(URLQueryItem(key: .environment, value: environment.rawValue))
      query.append(URLQueryItem(key: .topic, value: topic))
    }

    return .success(query)
  }

  var pamVersion: PAMVersionRequirement {
    switch endpoint {
    case .listPushChannels:
      return .none
    default:
      return .version2
    }
  }

  // Validated
  var validationErrorDetail: String? {
    switch endpoint {
    case let .listPushChannels(pushToken, _):
      return isInvalidForReason((pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData))
    case let .managePushChannels(pushToken, _, addChannels, removeChannels):
      return isInvalidForReason(
        (pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData),
        (addChannels.isEmpty && removeChannels.isEmpty, ErrorDescription.emptyChannelArray)
      )
    case let .removeAllPushChannels(pushToken, _):
      return isInvalidForReason((pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData))
    case let .manageAPNS(pushToken, _, topic, _, _):
      return isInvalidForReason(
        (pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData),
        (topic.isEmpty, ErrorDescription.emptyUUIDString)
      )
    case let .removeAllAPNS(pushToken, _, topic):
      return isInvalidForReason(
        (pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData),
        (topic.isEmpty, ErrorDescription.emptyUUIDString)
      )
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
  func decode(
    response: EndpointResponse<Data>
  ) -> Result<EndpointResponse<ModifiedPushChannelsPayloadResponse>, Error> {
    do {
      let anyJSONPayload = try Constant.jsonDecoder.decode(AnyJSON.self, from: response.payload)

      guard let anyArray = anyJSONPayload.arrayOptional,
        anyArray.first as? Int != nil, anyArray.last as? String != nil else {
        return .failure(PubNubError(.malformedResponseBody, response: response))
      }

      let endpoint = (response.router as? PushRouter)?.endpoint
      let payload = ModifiedPushChannelsPayloadResponse(
        added: endpoint?.addedChannels ?? [],
        removed: endpoint?.removedChannels ?? []
      )

      let decodedResponse = EndpointResponse<ModifiedPushChannelsPayloadResponse>(router: response.router,
                                                                                  request: response.request,
                                                                                  response: response.response,
                                                                                  data: response.data,
                                                                                  payload: payload)

      return .success(decodedResponse)
    } catch {
      return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error))
    }
  }
}

// MARK: - Response Body

struct ModifiedPushChannelsPayloadResponse: Codable {
  /// Response message
  let message: EndpointResponseMessage = .acknowledge
  /// Channels that had push support added
  let added: [String]
  /// Channels that had push support removed
  let removed: [String]
  /// All channels that were modified
  var channels: [String] {
    return added + removed
  }
}

struct RegisteredPushChannelsPayloadResponse: Codable {
  let channels: [String]
}

struct ErrorMessagePayloadResponse: Codable {
  let error: String
}
