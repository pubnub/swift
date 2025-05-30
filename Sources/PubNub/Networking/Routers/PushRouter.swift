//
//  PushRouter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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

    var pushToken: String? {
      var service: PubNub.PushService = .apns
      var token: Data

      switch self {
      case let .listPushChannels(pushToken, pushType),
           let .managePushChannels(pushToken, pushType, _, _),
           let .removeAllPushChannels(pushToken, pushType):
        service = pushType
        token = pushToken
      case let .manageAPNS(pushToken, _, _, _, _), let .removeAllAPNS(pushToken, _, _):
        token = pushToken
      }

      if service == .fcm || service == .gcm {
        return String(data: token, encoding: .utf8)
      } else {
        return token.hexEncodedString
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

    guard let pushToken = endpoint.pushToken else {
      var errorDetails = [String]()
      if let validationDetail = validationErrorDetail {
        errorDetails.append(validationDetail)
      }
      return .failure(PubNubError(.missingRequiredParameter, router: self, additional: errorDetails))
    }

    switch endpoint {
    case .listPushChannels:
      path = "/v1/push/sub-key/\(subscribeKey)/devices/\(pushToken)"
    case .managePushChannels:
      path = "/v1/push/sub-key/\(subscribeKey)/devices/\(pushToken)"
    case .removeAllPushChannels:
      path = "/v1/push/sub-key/\(subscribeKey)/devices/\(pushToken)/remove"
    case .manageAPNS:
      path = "/v2/push/sub-key/\(subscribeKey)/devices-apns2/\(pushToken)"
    case .removeAllAPNS:
      path = "/v2/push/sub-key/\(subscribeKey)/devices-apns2/\(pushToken)/remove"
    }
    return .success(path)
  }

  var queryItems: Result<[URLQueryItem], Error> {
    var query = defaultQueryItems

    switch endpoint {
    case let .listPushChannels(_, pushType):
      query.append(URLQueryItem(key: .type, value: pushType.stringValue()))
    case let .managePushChannels(_, pushType, joining, removing):
      query.append(URLQueryItem(key: .type, value: pushType.stringValue()))
      query.appendIfNotEmpty(key: .add, value: joining)
      query.appendIfNotEmpty(key: .remove, value: removing)
    case let .removeAllPushChannels(_, pushType):
      query.append(URLQueryItem(key: .type, value: pushType.stringValue()))
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
      return isInvalidForReason(
        (pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData),
        (endpoint.pushToken == nil, ErrorDescription.malformedDeviceTokenData)
      )
    case let .managePushChannels(pushToken, _, addChannels, removeChannels):
      return isInvalidForReason(
        (pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData),
        (endpoint.pushToken == nil, ErrorDescription.malformedDeviceTokenData),
        (addChannels.isEmpty && removeChannels.isEmpty, ErrorDescription.emptyChannelArray)
      )
    case let .removeAllPushChannels(pushToken, _):
      return isInvalidForReason(
        (pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData),
        (endpoint.pushToken == nil, ErrorDescription.malformedDeviceTokenData)
      )
    case let .manageAPNS(pushToken, _, topic, _, _):
      return isInvalidForReason(
        (pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData),
        (endpoint.pushToken == nil, ErrorDescription.malformedDeviceTokenData),
        (topic.isEmpty, ErrorDescription.emptyUUIDString)
      )
    case let .removeAllAPNS(pushToken, _, topic):
      return isInvalidForReason(
        (pushToken.isEmpty, ErrorDescription.emptyDeviceTokenData),
        (endpoint.pushToken == nil, ErrorDescription.malformedDeviceTokenData),
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
            anyArray.first is Int, anyArray.last is String
      else {
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
  let message: EndpointResponseMessage
  /// Channels that had push support added
  let added: [String]
  /// Channels that had push support removed
  let removed: [String]

  init(message: EndpointResponseMessage = .acknowledge, added: [String], removed: [String]) {
    self.message = message
    self.added = added
    self.removed = removed
  }

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
