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
// swiftlint:disable discouraged_optional_boolean file_length

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
      .response(on: queue, decoder: TimeResponseDecoder()) { result in
        completion?(result.map { $0.payload })
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
        decoder: PublishResponseDecoder()
      ) { result in
        completion?(result.map { $0.payload })
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
        decoder: PublishResponseDecoder()
      ) { result in
        completion?(result.map { $0.payload })
      }
  }
}

// MARK: - Presence Management

extension PubNub {
  public func hereNow(
    on channels: [String],
    and groups: [String] = [],
    includeUUIDs: Bool = true,
    also includeState: Bool = false,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<HereNowPayload, Error>) -> Void)?
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
        decoder: PresenceResponseDecoder<HereNowResponsePayload>()
      ) { result in
        completion?(result.map { $0.payload.payload })
      }
  }

  public func whereNow(
    for uuid: String,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<WhereNowPayload, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let router = PubNubRouter(configuration: configuration,
                              endpoint: .whereNow(uuid: uuid))

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: PresenceResponseDecoder<WhereNowResponsePayload>()
      ) { result in
        completion?(result.map { $0.payload.payload })
      }
  }
}

// MARK: - Channel Group Management

extension PubNub {
  public func listChannelGroups(
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GroupListPayload, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let router = PubNubRouter(configuration: configuration,
                              endpoint: .channelGroups)

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: ChannelGroupResponseDecoder<GroupListPayloadResponse>()
      ) { result in
        completion?(result.map { $0.payload.payload })
      }
  }

  public func deleteChannelGroup(
    _ group: String,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let router = PubNubRouter(configuration: configuration,
                              endpoint: .deleteGroup(group: group))

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: GenericServiceResponseDecoder()
      ) { result in
        completion?(result.map { $0.payload })
      }
  }

  public func listChannels(
    for group: String,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<ChannelListPayload, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let router = PubNubRouter(configuration: configuration,
                              endpoint: .channelsForGroup(group: group))

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: ChannelGroupResponseDecoder<ChannelListPayloadResponse>()
      ) { result in
        completion?(result.map { $0.payload.payload })
      }
  }

  public func addChannels(
    _ channels: [String],
    to group: String,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let router = PubNubRouter(configuration: configuration,
                              endpoint: .addChannelsForGroup(group: group, channels: channels))

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: GenericServiceResponseDecoder()
      ) { result in
        completion?(result.map { $0.payload })
      }
  }

  public func removeChannels(
    _ channels: [String],
    from group: String,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let router = PubNubRouter(configuration: configuration,
                              endpoint: .removeChannelsForGroup(group: group, channels: channels))

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: GenericServiceResponseDecoder()
      ) { result in
        completion?(result.map { $0.payload })
      }
  }
}

extension PubNub {
  public func listPushChannelRegistrations(
    for deivceToken: Data,
    of pushType: Endpoint.PushType = .apns,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<RegisteredPushChannelsPayloadResponse, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let router = PubNubRouter(configuration: configuration,
                              endpoint: .listPushChannels(pushToken: deivceToken, pushType: pushType))

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: RegisteredPushChannelsResponseDecoder()
      ) { result in
        completion?(result.map { $0.payload })
      }
  }

  public func modifyPushChannelRegistrations(
    byRemoving removals: [String],
    thenAdding additions: [String],
    for deivceToken: Data,
    of pushType: Endpoint.PushType = .apns,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let router = PubNubRouter(configuration: configuration,
                              endpoint: .modifyPushChannels(pushToken: deivceToken,
                                                            pushType: pushType,
                                                            addChannels: additions,
                                                            removeChannels: removals))

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: ModifyPushResponseDecoder()
      ) { result in
        completion?(result.map { $0.payload })
      }
  }

  public func removeAllPushChannelRegistrations(
    for deivceToken: Data,
    of pushType: Endpoint.PushType = .apns,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let router = PubNubRouter(configuration: configuration,
                              endpoint: .removeAllPushChannels(pushToken: deivceToken, pushType: pushType))

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: ModifyPushResponseDecoder()
      ) { result in
        completion?(result.map { $0.payload })
      }
  }
}

// MARK: - History

extension PubNub {
  public func fetchMessageHistory(
    for channels: [String],
    max count: Int? = nil,
    start stateTimetoken: Timetoken? = nil,
    end endTimetoken: Timetoken? = nil,
    metaInResponse: Bool = false,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<MessageHistoryChannelsPayload, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession
    let router = PubNubRouter(configuration: configuration,
                              endpoint: .fetchMessageHistory(channels: channels,
                                                             max: count,
                                                             start: stateTimetoken,
                                                             end: endTimetoken,
                                                             includeMeta: metaInResponse))
    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: MessageHistoryResponseDecoder()
      ) { result in
        completion?(result.map { $0.payload.channels })
      }
  }

  public func deleteMessageHistory(
    from channel: String,
    start stateTimetoken: Timetoken? = nil,
    end endTimetoken: Timetoken? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    let client = networkConfiguration?.customSession ?? networkSession

    let router = PubNubRouter(configuration: configuration,
                              endpoint: .deleteMessageHistory(channel: channel,
                                                              start: stateTimetoken,
                                                              end: endTimetoken))

    client
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: GenericServiceResponseDecoder()
      ) { result in

        completion?(result.map { $0.payload })
      }
  }
}

// swiftlint:enable discouraged_optional_boolean file_length
