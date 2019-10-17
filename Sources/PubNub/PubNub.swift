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

import Foundation

/// An object that coordinates a group of related PubNub pub/sub network events
public struct PubNub {
  /// Instance identifier
  public let instanceID: UUID
  /// A copy of the configuration object used for this session
  public let configuration: PubNubConfiguration
  /// Session used for performing request/response REST calls
  public let networkSession: SessionReplaceable
  /// Session used for performing subscription calls
  public let subscription: SubscriptionSession
  // Default Request Operator attached to every request
  public let defaultRequestOperator: RequestOperator

  /// Global log instance for the PubNub SDK
  public static var log = PubNubLogger(levels: [.event, .warn, .error], writers: [ConsoleLogWriter(), FileLogWriter()])
  // Global log instance for Logging issues/events
  public static var logLog = PubNubLogger(levels: [.log], writers: [ConsoleLogWriter()])

  /// Creates a session with the specified configuration
  public init(configuration: PubNubConfiguration = .default,
              session: SessionReplaceable? = nil) {
    instanceID = UUID()
    self.configuration = configuration

    var operators = [RequestOperator]()
    if let retryOperator = configuration.automaticRetry {
      operators.append(retryOperator)
    }
    if configuration.useInstanceId {
      let instanceIdOperator = InstanceIdOperator(instanceID: instanceID.description)
      operators.append(instanceIdOperator)
    }

    defaultRequestOperator = MultiplexRequestOperator(operators: operators)
    networkSession = session ?? Session(configuration: configuration.urlSessionConfiguration)

    subscription = SubscribeSessionFactory.shared.getSession(from: configuration)
  }

  func route<Decoder>(
    _ endpoint: Endpoint,
    networkConfiguration: NetworkConfiguration?,
    responseDecoder: Decoder,
    respondOn queue: DispatchQueue = .main,
    completion: @escaping (Result<Response<Decoder.Payload>, Error>) -> Void
  ) where Decoder: ResponseDecoder {
    let defaultOperator = defaultRequestOperator
      .merge(requestOperator: networkConfiguration?.retryPolicy ?? configuration.automaticRetry)

    networkSession.usingDefault(requestOperator: defaultOperator)
      .request(with: PubNubRouter(configuration: configuration, endpoint: endpoint),
               requestOperator: networkConfiguration?.requestOperator)
      .validate()
      .response(
        on: queue,
        decoder: responseDecoder,
        completion: completion
      )
  }
}

// MARK: - Time

extension PubNub {
  public func time(
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<TimeResponsePayload, Error>) -> Void)?
  ) {
    route(.time,
          networkConfiguration: networkConfiguration,
          responseDecoder: TimeResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }
}

// MARK: - Publish

extension PubNub {
  public func publish(
    channel: String,
    message: JSONCodable,
    shouldStore: Bool? = nil,
    storeTTL: Int? = nil,
    meta: JSONCodable? = nil,
    shouldCompress: Bool = false,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<PublishResponsePayload, Error>) -> Void)?
  ) {
    let endpoint: Endpoint = shouldCompress ?
      .compressedPublish(message: message.codableValue,
                         channel: channel,
                         shouldStore: shouldStore,
                         ttl: storeTTL,
                         meta: meta?.codableValue) :
      .publish(message: message.codableValue,
               channel: channel,
               shouldStore: shouldStore,
               ttl: storeTTL,
               meta: meta?.codableValue)

    route(endpoint,
          networkConfiguration: networkConfiguration,
          responseDecoder: PublishResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func fire(
    channel: String,
    message: JSONCodable,
    meta: JSONCodable? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<PublishResponsePayload, Error>) -> Void)?
  ) {
    route(.fire(message: message.codableValue, channel: channel, meta: meta?.codableValue),
          networkConfiguration: networkConfiguration,
          responseDecoder: PublishResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func signal(
    channel: String,
    message: JSONCodable,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<PublishResponsePayload, Error>) -> Void)?
  ) {
    route(.signal(message: message.codableValue, channel: channel),
          networkConfiguration: networkConfiguration,
          responseDecoder: PublishResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }
}

// MARK: - Subscription

extension PubNub {
  public func subscribe(
    to channels: [String],
    and channelGroups: [String] = [],
    at timetoken: Timetoken = 0,
    withPresence: Bool = false,
    setting presenceState: [String: [String: JSONCodable]] = [:]
  ) {
    subscription.subscribe(to: channels,
                           and: channelGroups,
                           at: timetoken,
                           withPresence: withPresence,
                           setting: presenceState)
  }

  public func add(_ listener: SubscriptionListener) {
    subscription.add(listener)
  }

  public func unsubscribe(from channels: [String], and channelGroups: [String] = [], presenceOnly: Bool = false) {
    subscription.unsubscribe(from: channels, and: channelGroups, presenceOnly: presenceOnly)
  }

  public func unsubscribeAll() {
    subscription.unsubscribeAll()
  }

  public var subscribedChannels: [String] {
    return subscription.subscribedChannels
  }

  public var subscribedChannelGroups: [String] {
    return subscription.subscribedChannelGroups
  }
}

// MARK: - Presence Management

extension PubNub {
  public func setPresence(
    state: [String: JSONCodable],
    on channels: [String],
    and groups: [String] = [],
    completion: @escaping (Result<[String: [String: AnyJSON]], Error>) -> Void
  ) {
    subscription.setPresence(state: state, on: channels, and: groups, completion: completion)
  }

  public func getPresenceState(
    for uuid: String,
    on channels: [String],
    and groups: [String],
    completion: @escaping (Result<[String: [String: AnyJSON]], Error>) -> Void
  ) {
    subscription.getPresenceState(for: uuid, on: channels, and: groups, completion: completion)
  }

  public func hereNow(
    on channels: [String],
    and groups: [String] = [],
    includeUUIDs: Bool = true,
    also includeState: Bool = false,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<HereNowPayload, Error>) -> Void)?
  ) {
    let endpoint: Endpoint
    if channels.isEmpty, groups.isEmpty {
      endpoint = Endpoint.hereNowGlobal(includeUUIDs: includeUUIDs, includeState: includeState)
    } else {
      endpoint = Endpoint.hereNow(channels: channels,
                                  groups: groups,
                                  includeUUIDs: includeUUIDs,
                                  includeState: includeState)
    }

    route(endpoint,
          networkConfiguration: networkConfiguration,
          responseDecoder: HereNowResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload.payload })
    }
  }

  public func whereNow(
    for uuid: String,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<WhereNowPayload, Error>) -> Void)?
  ) {
    route(.whereNow(uuid: uuid),
          networkConfiguration: networkConfiguration,
          responseDecoder: PresenceResponseDecoder<WhereNowResponsePayload>(),
          respondOn: queue) { result in
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
    route(.channelGroups,
          networkConfiguration: networkConfiguration,
          responseDecoder: ChannelGroupResponseDecoder<GroupListPayloadResponse>(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload.payload })
    }
  }

  public func deleteChannelGroup(
    _ group: String,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    route(.deleteGroup(group: group),
          networkConfiguration: networkConfiguration,
          responseDecoder: GenericServiceResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func listChannels(
    for group: String,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<ChannelListPayload, Error>) -> Void)?
  ) {
    route(.channelsForGroup(group: group),
          networkConfiguration: networkConfiguration,
          responseDecoder: ChannelGroupResponseDecoder<ChannelListPayloadResponse>(),
          respondOn: queue) { result in
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
    route(.addChannelsForGroup(group: group, channels: channels),
          networkConfiguration: networkConfiguration,
          responseDecoder: GenericServiceResponseDecoder(),
          respondOn: queue) { result in
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
    route(.removeChannelsForGroup(group: group, channels: channels),
          networkConfiguration: networkConfiguration,
          responseDecoder: GenericServiceResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }
}

// MARK: - Push

extension PubNub {
  public func listPushChannelRegistrations(
    for deviceToken: Data,
    of pushType: Endpoint.PushType = .apns,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<RegisteredPushChannelsPayloadResponse, Error>) -> Void)?
  ) {
    route(.listPushChannels(pushToken: deviceToken, pushType: pushType),
          networkConfiguration: networkConfiguration,
          responseDecoder: RegisteredPushChannelsResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func modifyPushChannelRegistrations(
    byRemoving removals: [String],
    thenAdding additions: [String],
    for deviceToken: Data,
    of pushType: Endpoint.PushType = .apns,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    let endpoint: Endpoint = .modifyPushChannels(pushToken: deviceToken,
                                                 pushType: pushType,
                                                 addChannels: additions,
                                                 removeChannels: removals)
    route(endpoint,
          networkConfiguration: networkConfiguration,
          responseDecoder: ModifyPushResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func removeAllPushChannelRegistrations(
    for deviceToken: Data,
    of pushType: Endpoint.PushType = .apns,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    route(.removeAllPushChannels(pushToken: deviceToken, pushType: pushType),
          networkConfiguration: networkConfiguration,
          responseDecoder: ModifyPushResponseDecoder(),
          respondOn: queue) { result in
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
    let endpoint: Endpoint = .fetchMessageHistory(channels: channels,
                                                  max: count,
                                                  start: stateTimetoken,
                                                  end: endTimetoken,
                                                  includeMeta: metaInResponse)

    route(endpoint,
          networkConfiguration: networkConfiguration,
          responseDecoder: MessageHistoryResponseDecoder(),
          respondOn: queue) { result in
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
    route(.deleteMessageHistory(channel: channel, start: stateTimetoken, end: endTimetoken),
          networkConfiguration: networkConfiguration,
          responseDecoder: GenericServiceResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func messageCounts(
    channels: [String: Timetoken],
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<[String: Int], Error>) -> Void)?
  ) {
    let endpoint: Endpoint = .messageCounts(channels: channels.map { $0.key },
                                            timetoken: nil,
                                            channelsTimetoken: channels.map { $0.value })

    route(endpoint,
          networkConfiguration: networkConfiguration,
          responseDecoder: MessageCountsResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload.channels })
    }
  }

  public func messageCounts(
    channels: [String],
    timetoken: Timetoken = 1,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<[String: Int], Error>) -> Void)?
  ) {
    let endpoint: Endpoint = .messageCounts(channels: channels,
                                            timetoken: timetoken,
                                            channelsTimetoken: nil)

    route(endpoint,
          networkConfiguration: networkConfiguration,
          responseDecoder: MessageCountsResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload.channels })
    }
  }
}

// MARK: - User Objects

extension PubNub {
  public func fetchUsers(
    include field: Endpoint.IncludeField? = nil,
    limit: Int? = nil,
    start: String? = nil,
    end: String? = nil,
    count: Bool? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserObjectsResponsePayload, Error>) -> Void)?
  ) {
    route(.objectsUserFetchAll(include: field, limit: limit, start: start, end: end, count: count),
          networkConfiguration: networkConfiguration,
          responseDecoder: UserObjectsResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func fetch(
    userID: String,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserObjectResponsePayload, Error>) -> Void)?
  ) {
    route(.objectsUserFetch(userID: userID, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: UserObjectResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func create(
    user: PubNubUser,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserObjectResponsePayload, Error>) -> Void)?
  ) {
    route(.objectsUserCreate(user: user, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: UserObjectResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func update(
    user: PubNubUser,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserObjectResponsePayload, Error>) -> Void)?
  ) {
    route(.objectsUserUpdate(user: user, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: UserObjectResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func delete(
    userID: String,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    route(.objectsUserDelete(userID: userID, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: GenericServiceResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func fetchMemberships(
    userID: String,
    include fields: [Endpoint.IncludeField]? = nil,
    limit: Int? = nil,
    start: String? = nil,
    end: String? = nil,
    count: Bool? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserMembershipsResponsePayload, Error>) -> Void)?
  ) {
    route(.objectsUserMemberships(userID: userID, include: fields, limit: limit, start: start, end: end, count: count),
          networkConfiguration: networkConfiguration,
          responseDecoder: UserMembershipsObjectsResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func updateMemberships(
    userID: String,
    adding addedSpaceIDs: [ObjectIdentifiable] = [],
    updating updateSpaceIDs: [ObjectIdentifiable] = [],
    removing removeSpaceIDs: [ObjectIdentifiable] = [],
    include fields: [Endpoint.IncludeField]? = nil,
    limit: Int? = nil,
    start: String? = nil,
    end: String? = nil,
    count: Bool? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserMembershipsResponsePayload, Error>) -> Void)?
  ) {
    let endpoint = Endpoint.objectsUserMembershipsUpdate(
      userID: userID,
      add: addedSpaceIDs, update: updateSpaceIDs, remove: removeSpaceIDs,
      include: fields,
      limit: limit, start: start, end: end, count: count
    )

    route(endpoint,
          networkConfiguration: networkConfiguration,
          responseDecoder: UserMembershipsObjectsResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }
}

// MARK: - Space Objects

extension PubNub {
  public func fetchSpaces(
    include field: Endpoint.IncludeField? = nil,
    limit: Int? = nil,
    start: String? = nil,
    end: String? = nil,
    count: Bool? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceObjectsResponsePayload, Error>) -> Void)?
  ) {
    route(.objectsSpaceFetchAll(include: field, limit: limit, start: start, end: end, count: count),
          networkConfiguration: networkConfiguration,
          responseDecoder: SpaceObjectsResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func fetch(
    spaceID: String,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceObjectResponsePayload, Error>) -> Void)?
  ) {
    route(.objectsSpaceFetch(spaceID: spaceID, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: SpaceObjectResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func create(
    space: PubNubSpace,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceObjectResponsePayload, Error>) -> Void)?
  ) {
    route(.objectsSpaceCreate(space: space, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: SpaceObjectResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func update(
    space: PubNubSpace,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceObjectResponsePayload, Error>) -> Void)?
  ) {
    route(.objectsSpaceUpdate(space: space, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: SpaceObjectResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func delete(
    spaceID: String,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    route(.objectsSpaceDelete(spaceID: spaceID, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: GenericServiceResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func fetchMemberships(
    spaceID: String,
    include fields: [Endpoint.IncludeField]? = nil,
    limit: Int? = nil,
    start: String? = nil,
    end: String? = nil,
    count: Bool? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceMembershipResponsePayload, Error>) -> Void)?
  ) {
    route(.objectsSpaceMemberships(spaceID: spaceID,
                                   include: fields, limit: limit, start: start, end: end, count: count),
          networkConfiguration: networkConfiguration,
          responseDecoder: SpaceMembershipObjectsResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  public func updateMemberships(
    spaceID: String,
    adding addedUserIDs: [ObjectIdentifiable] = [],
    updating updateUserIDs: [ObjectIdentifiable] = [],
    removing removeUserIDs: [ObjectIdentifiable] = [],
    include fields: [Endpoint.IncludeField]? = nil,
    limit: Int? = nil,
    start: String? = nil,
    end: String? = nil,
    count: Bool? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceMembershipResponsePayload, Error>) -> Void)?
  ) {
    let endpoint = Endpoint.objectsSpaceMembershipsUpdate(
      spaceID: spaceID,
      add: addedUserIDs, update: updateUserIDs, remove: removeUserIDs,
      include: fields,
      limit: limit, start: start, end: end, count: count
    )

    route(endpoint,
          networkConfiguration: networkConfiguration,
          responseDecoder: SpaceMembershipObjectsResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }
}

// MARK: - Crypto

extension PubNub {
  func encrypt(message: String) -> Result<Data, Error> {
    guard let crypto = configuration.cipherKey else {
      PubNub.log.error(ErrorDescription.missingCryptoKey)
      return .failure(CryptoError.invalidKey)
    }

    guard let dataMessage = message.data(using: .utf8) else {
      return .failure(CryptoError.decodeError)
    }

    return crypto.encrypt(utf8Encoded: dataMessage)
  }

  func decrypt(data: Data) -> Result<Data, Error> {
    guard let crypto = configuration.cipherKey else {
      PubNub.log.error(ErrorDescription.missingCryptoKey)
      return .failure(CryptoError.invalidKey)
    }

    return crypto.decrypt(encrypted: data)
  }

  // swiftlint:disable:next file_length
}
