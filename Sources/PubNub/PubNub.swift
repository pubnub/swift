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
  /// Get current `Timetoken` from System
  /// - Parameters:
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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
  /// Publish a message to a channel.
  ///
  /// Message storage and TTL can be configured with the following rules:
  /// 1. If `shouldStore` is true and `storeTTL` is 0, the message is stored with no expiry time.
  /// 2. If `shouldStore` is true and `storeTTL` is X; X>0, the message is stored with an expiry time of X hours.
  /// 3. If `shouldStore` is false or not specified, the message is not stored and the `storeTTL` parameter is ignored.
  /// 4. If `storeTTL` is not specified, then expiration of the message defaults back to the expiry value for the key.
  ///
  /// - Parameters:
  ///   - channel: The destination of the message
  ///   - message: The message to publish
  ///   - shouldStore: If true the published message is stored in history.
  ///   - storeTTL: Set a per message time to live in storage.
  ///   - meta: Publish extra metadata with the request.
  ///   - shouldCompress: Whether the message needs to be compressed before transmission
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Publish a message to PubNub Functions Event Handlers
  ///
  ///  These messages will go directly to any Event Handlers registered
  ///  on the channel that you fire to and will trigger their execution.
  ///
  ///  The content of the fired request will be available for processing within the Event Handler.
  ///  - Important: The message sent via fire() is not replicated,
  ///  and so will not be received by any subscribers to the channel.
  ///
  ///  The message is also not stored in history.
  ///
  /// - Parameters:
  ///   - channel: The destination of the message
  ///   - message: The message to publish
  ///   - meta: Publish extra metadata with the request.
  ///   - shouldCompress: Whether the message needs to be compressed before transmission
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Publish a message to PubNub Functions Event Handlers
  ///
  /// - Parameters:
  ///   - channel: The destination of the message
  ///   - message: The message to publish
  ///   - shouldCompress: Whether the message needs to be compressed before transmission
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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
  /// Subscribe to channels and/or channel groups
  ///
  /// - Parameters:
  ///   - to: List of channels to subscribe on
  ///   - and: List of channel groups to subscribe on
  ///   - at: The initial timetoken to subscribe with
  ///   - withPresence: If true it also subscribes to presence events on the specified channels.
  ///   - setting: The object containing the state for the channel(s).
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

  /// Unsubscribe from channels and/or channel groups
  ///
  /// - Parameters:
  ///   - from: List of channels to unsubscribe from
  ///   - and: List of channel groups to unsubscribe from
  ///   - presenceOnly: If true, it only unsubscribes from presence events on the specified channels.
  public func unsubscribe(from channels: [String], and channelGroups: [String] = [], presenceOnly: Bool = false) {
    subscription.unsubscribe(from: channels, and: channelGroups, presenceOnly: presenceOnly)
  }

  /// Unsubscribe from all channels and channel groups
  public func unsubscribeAll() {
    subscription.unsubscribeAll()
  }

  /// Stops the subscriptions in progress
  /// - Important: This subscription might be shared with multiple `PubNub` instances.
  public func disconnect() {
    subscription.disconnect()
  }

  /// Reconnets to a stopped subscription with the previous subscribed channels and channel groups
  /// - Parameter at: The timetoken value used to reconnect or nil to use the previous stored value
  /// - Important: This subscription might be shared with multiple `PubNub` instances.
  public func reconnect(at timetoken: Timetoken?) {
    subscription.reconnect(at: timetoken)
  }

  /// The `Timetoken` used for the last successful subscription request
  public var previousTimetoken: Timetoken? {
    return subscription.previousTokenResponse?.timetoken
  }

  /// Add a listener to enable the receiving of subscription events
  public func add(_ listener: SubscriptionListener) {
    subscription.add(listener)
  }

  /// List of currently subscribed channels
  public var subscribedChannels: [String] {
    return subscription.subscribedChannels
  }

  /// List of currently subscribed channel groups
  public var subscribedChannelGroups: [String] {
    return subscription.subscribedChannelGroups
  }

  /// The total number of channels and channel groups that are currently subscribed to
  public var subscriptionCount: Int {
    return subscription.subscriptionCount
  }

  /// The current state of the subscription connection
  public var connectionStatus: ConnectionStatus {
    return subscription.connectionStatus
  }
}

// MARK: - Presence Management

extension PubNub {
  /// Set state dictionary pairs specific to a subscriber uuid
  /// - Parameters:
  ///   - state: The UUID for which to query the subscribed channels of
  ///   - on: Additional network configuration to use on the request
  ///   - and: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func setPresence(
    state: [String: JSONCodableScalar],
    on channels: [String],
    and groups: [String] = [],
    completion: @escaping (Result<[String: [String: AnyJSON]], Error>) -> Void
  ) {
    subscription.setPresence(state: state, on: channels, and: groups, completion: completion)
  }

  /// Get state dictionary pairs from a specific subscriber uuid
  /// - Parameters:
  ///   - for: The UUID for which to query the subscribed channels of
  ///   - on: Additional network configuration to use on the request
  ///   - and: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func getPresenceState(
    for uuid: String,
    on channels: [String],
    and groups: [String] = [],
    completion: @escaping (Result<[String: [String: AnyJSON]], Error>) -> Void
  ) {
    subscription.getPresenceState(for: uuid, on: channels, and: groups, completion: completion)
  }

  /// Obtain information about the current state of a channel
  ///
  /// List of unique user-ids currently subscribed to the channel and the total occupancy count of the channel.
  /// If you don't pass in any channels or groups,
  /// then this method will make a global call to return data for all channels
  ///
  /// - Parameters:
  ///   - on: The list of channels to return occupancy results from.
  ///   - and: The list of channel groups to return occupancy results from.
  ///   - includeUUIDs: `false` disables the return of uuids
  ///   - also: `true` will return the subscribe state information if available
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Obtain information about the current list of channels a UUID is subscribed to
  /// - Parameters:
  ///   - for: The UUID for which to query the subscribed channels of
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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
  /// Lists all the channel groups
  /// - Parameters:
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Removes the channel group.
  /// - Parameters:
  ///   - channelGroup: The channel group to delete.
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func delete(
    channelGroup: String,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    route(.deleteGroup(group: channelGroup),
          networkConfiguration: networkConfiguration,
          responseDecoder: GenericServiceResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  /// Lists all the channels of the channel group.
  /// - Parameters:
  ///   - for: The channel group to list channels on.
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Adds a channel to a channel group.
  /// - Parameters:
  ///   - channels: List of channels to add to the group
  ///   - to: The Channel Group to add the list of channels to.
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func add(
    channels: [String],
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

  /// Rremoves the channels from the channel group.
  /// - Parameters:
  ///   - channels: List of channels to remove from the group
  ///   - from: The Channel Group to remove the list of channels from
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func remove(
    channels: [String],
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
  /// All channels on which push notification has been enabled using specified pushToken.
  /// - Parameters:
  ///   - for: The Channel Group to remove the list of channels from
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Adds or removes push notification functionality on provided set of channels.
  /// - Parameters:
  ///   - byRemoving: The list of channels to remove the device registration from
  ///   - thenAdding: The list of channels to add the device registration to
  ///   - for: A device token to identify the device for registration changes
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Disable push notifications from all channels which is registered with specified pushToken.
  /// - Parameters:
  ///   - for: The Channel Group to remove the list of channels from
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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
  /// Fetches historical messages of a channel.
  ///
  /// Keep in mind that you will still receive a maximum of 100 messages
  /// even if there are more messages that meet the timetoken values.
  ///
  /// Iterative calls to history adjusting the start timetoken is necessary to page
  /// through the full set of results if more than 100 messages meet the timetoken values.
  ///
  /// - Parameters:
  ///   - for: List of channels to fetch history messages from.
  ///   - max: The max number of messages to retrieve.
  ///   - start: Time token delimiting the start of time slice (exclusive) to pull messages from.
  ///   - end: Time token delimiting the end of time slice (inclusive) to pull messages from.
  ///   - metaInResponse: If `true` the meta properties of messages will be returned as well (if existing).
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Removes the messages from the history of a specific channel.
  /// - Parameters:
  ///   - from: The channel to delete the messages from.
  ///   - start: Time token delimiting the start of time slice (exclusive) to delete messages from.
  ///   - end: Time token delimiting the end of time slice (inclusive) to delete messages from.
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Returns the number of messages published for one of more channels using a channel specific time token
  /// - Parameters:
  ///   - channels: Dictionary of channel and the timetoken to get the message count for.
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Returns the number of messages published for each channels for a single time
  /// - Parameters:
  ///   - channels: The channel to delete the messages from.
  ///   - timetoken: The timetoken for all channels in the list to get message counts for.
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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
  /// Returns a paginated list of user objects, optionally including each user's custom data object.
  /// - Parameters:
  ///   - include: Whether to include the custom field in the fetch response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the users from
  ///   - end: The end paging hash string to retrieve the users from
  ///   - count: A flag denoting whether to return the total count of users
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Returns the specified user object
  /// - Parameters:
  ///   - userID: The unique identifier of the PubNub user object to delete.
  ///   - include: Whether to include the custom field in the fetch response
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func fetch(
    userID: String,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserObject, Error>) -> Void)?
  ) {
    route(.objectsUserFetch(userID: userID, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: UserObjectResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload.user })
    }
  }

  /// Creates a user with the specified properties
  /// - Parameters:
  ///   - user: The `PubNubUser` protocol object to create
  ///   - include: Whether to include the custom field in the fetch response
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func create(
    user: PubNubUser,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserObject, Error>) -> Void)?
  ) {
    route(.objectsUserCreate(user: user, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: UserObjectResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload.user })
    }
  }

  /// Updates a user with the specified properties
  /// - Parameters:
  ///   - user: The `PubNubUser` protocol object to update
  ///   - include: Whether to include the custom field in the fetch response
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func update(
    user: PubNubUser,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserObject, Error>) -> Void)?
  ) {
    route(.objectsUserUpdate(user: user, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: UserObjectResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload.user })
    }
  }

  /// Deletes the specified user object.
  /// - Parameters:
  ///   - userID: The unique identifier of the PubNub user object to delete.
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func delete(
    userID: String,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    route(.objectsUserDelete(userID: userID),
          networkConfiguration: networkConfiguration,
          responseDecoder: GenericServiceResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  /// Get the specified user's space memberships.
  /// - Parameters:
  ///   - userID: The unique identifier of the PubNub user
  ///   - include: Whether to include the custom field in the fetch response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the users from
  ///   - end: The end paging hash string to retrieve the users from
  ///   - count: A flag denoting whether to return the total count of users
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Modifty the list of space memberships for a given user
  /// - Parameters:
  ///   - userID: The unique identifier of the PubNub user
  ///   - joining: The list of spaces identifiers to add the user to
  ///   - updating: The list of space identifiers to update for the user
  ///   - leaving: The list of space identifiers to remove the user from
  ///   - include: List of custom fields (if any) to include in the response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the users from
  ///   - end: The end paging hash string to retrieve the users from
  ///   - count: A flag denoting whether to return the total count of users
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func modifyMemberships(
    userID: String,
    joining joinedSpaceIDs: [ObjectIdentifiable] = [],
    updating updateSpaceIDs: [ObjectIdentifiable] = [],
    leaving leavingSpaceIDs: [ObjectIdentifiable] = [],
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
      add: joinedSpaceIDs, update: updateSpaceIDs, remove: leavingSpaceIDs,
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
  /// Returns a paginated list of space objects, optionally including each space's custom data object.
  /// - Parameters:
  ///   - include: Whether to include the custom field in the fetch response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the spaces from
  ///   - end: The end paging hash string to retrieve the spaces from
  ///   - count: A flag denoting whether to return the total count of spaces
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
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

  /// Returns the specified space object
  /// - Parameters:
  ///   - spaceID: The unique identifier of the PubNub space object to delete.
  ///   - include: Whether to include the custom field in the fetch response
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func fetch(
    spaceID: String,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceObject, Error>) -> Void)?
  ) {
    route(.objectsSpaceFetch(spaceID: spaceID, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: SpaceObjectResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload.space })
    }
  }

  /// Creates a space with the specified properties
  /// - Parameters:
  ///   - space: The `PubNubSpace` protocol object to create
  ///   - include: Whether to include the custom field in the fetch response
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func create(
    space: PubNubSpace,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceObject, Error>) -> Void)?
  ) {
    route(.objectsSpaceCreate(space: space, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: SpaceObjectResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload.space })
    }
  }

  /// Updates a space with the specified properties
  /// - Parameters:
  ///   - space: The `PubNubSpace` protocol object to update
  ///   - include: Whether to include the custom field in the fetch response
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func update(
    space: PubNubSpace,
    include field: Endpoint.IncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceObject, Error>) -> Void)?
  ) {
    route(.objectsSpaceUpdate(space: space, include: field),
          networkConfiguration: networkConfiguration,
          responseDecoder: SpaceObjectResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload.space })
    }
  }

  /// Deletes the specified space object.
  /// - Parameters:
  ///   - spaceID: The unique identifier of the PubNub space object to delete.
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func delete(
    spaceID: String,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<GenericServicePayloadResponse, Error>) -> Void)?
  ) {
    route(.objectsSpaceDelete(spaceID: spaceID),
          networkConfiguration: networkConfiguration,
          responseDecoder: GenericServiceResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  /// Get the specified space’s member users.
  /// - Parameters:
  ///   - spaceID: The unique identifier of the PubNub space
  ///   - include: Whether to include the custom field in the fetch response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the users from
  ///   - end: The end paging hash string to retrieve the users from
  ///   - count: A flag denoting whether to return the total count of users
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func fetchMembers(
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

  /// Modifty the list of members for a space.
  /// - Parameters:
  ///   - spaceID: The unique identifier of the PubNub space
  ///   - adding: A list of unique  PubNub user identifier to add
  ///   - updating: A list of unique  PubNub user identifier to update
  ///   - removing: A list of unique  PubNub user identifier to remove
  ///   - include: Whether to include the custom field in the fetch response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the users from
  ///   - end: The end paging hash string to retrieve the users from
  ///   - count: A flag denoting whether to return the total count of users
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func modifyMembers(
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
  /// Encrypt some `Data` using the configuration Cipher Key value
  /// - Parameter message: The plaintext message to be encrypted
  /// - Returns: A `Result` containing either the encryped Data or the Crypto Error
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

  /// Decrypt some `Data` using the configuration Cipher Key value
  /// - Parameter message: The encrypted `Data` to decrypt
  /// - Returns: A `Result` containing either the decrypted plaintext message as `Data` or the Crypto Error
  func decrypt(data: Data) -> Result<Data, Error> {
    guard let crypto = configuration.cipherKey else {
      PubNub.log.error(ErrorDescription.missingCryptoKey)
      return .failure(CryptoError.invalidKey)
    }

    return crypto.decrypt(encrypted: data)
  }

  // swiftlint:disable:next file_length
}
