//
//  PubNub.swift
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
// swiftlint:disable discouraged_optional_boolean

import Foundation

/// An object that coordinates a group of related PubNub pub/sub network events
public struct PubNub {
  /// Instance identifier
  public let instanceID: UUID
  /// A copy of the configuration object used for this session
  public let configuration: PubNubConfiguration
  /// HTTP Session used for performing request/response REST calls
  public let networkSession: SessionReplaceable

  /// Creates a session with the specified configuration
  public init(configuration: PubNubConfiguration = .default,
              session: SessionReplaceable? = nil) {
    instanceID = UUID()
    self.configuration = configuration
    let complexSessionStream = MultiplexSessionStream([])
    networkSession = session ?? Session(configuration: configuration.urlSessionConfiguration,
                                        sessionStream: complexSessionStream)
  }

  public func time(
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<TimeResponsePayload, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession
    let router = PubNubRouter(configuration: configuration, endpoint: .time)

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(on: queue, decoder: TimeResponseDecoder(), operator: networkConfiguration?.responseOperator) { result in
        switch result {
        case let .success(response):
          completion?(.success(response.payload))
        case let .failure(error):
          completion?(.failure(error))
        }
      }
  }

  public func publish(
    channel: String,
    message: AnyJSON,
    shouldStore: Bool? = nil,
    storeTTL: Int? = nil,
    meta: AnyJSON? = nil,
    shouldCompress: Bool = false,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<PublishResponsePayload, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let endpoint: Endpoint
    if shouldCompress {
      endpoint = .compressedPublish(message: message,
                                    channel: channel,
                                    shouldStore: shouldStore,
                                    ttl: storeTTL,
                                    meta: meta)
    } else {
      endpoint = .publish(message: message,
                          channel: channel,
                          shouldStore: shouldStore,
                          ttl: storeTTL,
                          meta: meta)
    }

    let router = PubNubRouter(configuration: configuration,
                              endpoint: endpoint)

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: PublishResponseDecoder(),
        operator: networkConfiguration?.responseOperator
      ) { result in
        switch result {
        case let .success(response):
          completion?(.success(response.payload))
        case let .failure(error):
          completion?(.failure(error))
        }
      }
  }

  public func fire(
    channel: String,
    message: AnyJSON,
    meta: AnyJSON? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<PublishResponsePayload, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let endpoint = Endpoint.fire(message: message, channel: channel, meta: meta)

    let router = PubNubRouter(configuration: configuration,
                              endpoint: endpoint)

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: PublishResponseDecoder(),
        operator: networkConfiguration?.responseOperator
      ) { result in
        switch result {
        case let .success(response):
          completion?(.success(response.payload))
        case let .failure(error):
          completion?(.failure(error))
        }
      }
  }

  public func hereNow(
    on channels: [String],
    and groups: [String] = [],
    includeUUIDs: Bool = true,
    also includeState: Bool = false,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<HereNowResponsePayload, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let router = PubNubRouter(configuration: configuration,
                              endpoint: .hereNow(channels: channels,
                                                 groups: groups,
                                                 includeUUIDs: includeUUIDs,
                                                 includeState: includeState))

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: PresenceResponseDecoder<HereNowResponsePayload>(),
        operator: networkConfiguration?.responseOperator
      ) { result in
        switch result {
        case let .success(response):
          completion?(.success(response.payload))
        case let .failure(error):
          completion?(.failure(error))
        }
      }
  }
}

// swiftlint:enable discouraged_optional_boolean
