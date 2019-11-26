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
    networkSession = session ?? HTTPSession(configuration: configuration.urlSessionConfiguration)

    subscription = SubscribeSessionFactory.shared.getSession(from: configuration)
  }

  func route<Decoder>(
    _ router: HTTPRouter,
    networkConfiguration: NetworkConfiguration?,
    responseDecoder: Decoder,
    respondOn queue: DispatchQueue = .main,
    completion: @escaping (Result<EndpointResponse<Decoder.Payload>, Error>) -> Void
  ) where Decoder: ResponseDecoder {
    let defaultOperator = defaultRequestOperator
      .merge(requestOperator: networkConfiguration?.retryPolicy ?? configuration.automaticRetry)

    networkSession.usingDefault(requestOperator: defaultOperator)
      .request(with: router, requestOperator: networkConfiguration?.requestOperator)
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
    route(TimeRouter(.time, configuration: configuration),
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
    let router: PublishRouter
    if shouldCompress {
      router = PublishRouter(
        .compressedPublish(message: message.codableValue,
                           channel: channel,
                           shouldStore: shouldStore,
                           ttl: storeTTL,
                           meta: meta?.codableValue),
        configuration: configuration
      )
    } else {
      router = PublishRouter(
        .publish(message: message.codableValue,
                 channel: channel,
                 shouldStore: shouldStore,
                 ttl: storeTTL,
                 meta: meta?.codableValue),
        configuration: configuration
      )
    }

    route(router,
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
    messageAction _: MessageAction? = nil,
    meta: JSONCodable? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<PublishResponsePayload, Error>) -> Void)?
  ) {
    route(PublishRouter(.fire(message: message.codableValue, channel: channel, meta: meta?.codableValue),
                        configuration: configuration),
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
    route(PublishRouter(.signal(message: message.codableValue, channel: channel),
                        configuration: configuration),
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
    let router: PresenceRouter
    if channels.isEmpty, groups.isEmpty {
      router = PresenceRouter(.hereNowGlobal(includeUUIDs: includeUUIDs, includeState: includeState),
                              configuration: configuration)
    } else {
      router = PresenceRouter(
        .hereNow(channels: channels, groups: groups, includeUUIDs: includeUUIDs, includeState: includeState),
        configuration: configuration
      )
    }

    route(router,
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
    route(PresenceRouter(.whereNow(uuid: uuid), configuration: configuration),
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
    route(ChannelGroupsRouter(.channelGroups, configuration: configuration),
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
    route(ChannelGroupsRouter(.deleteGroup(group: channelGroup), configuration: configuration),
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
    route(ChannelGroupsRouter(.channelsForGroup(group: group), configuration: configuration),
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
    route(ChannelGroupsRouter(.addChannelsToGroup(group: group, channels: channels), configuration: configuration),
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
    route(ChannelGroupsRouter(.removeChannelsForGroup(group: group, channels: channels), configuration: configuration),
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
    of pushType: PushRouter.PushType = .apns,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<RegisteredPushChannelsPayloadResponse, Error>) -> Void)?
  ) {
    route(PushRouter(.listPushChannels(pushToken: deviceToken, pushType: pushType), configuration: configuration),
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
    of pushType: PushRouter.PushType = .apns,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<ModifiedPushChannelsPayloadResponse, Error>) -> Void)?
  ) {
    let router = PushRouter(
      .modifyPushChannels(pushToken: deviceToken, pushType: pushType, joining: additions, leaving: removals),
      configuration: configuration
    )

    route(router,
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
    of pushType: PushRouter.PushType = .apns,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<ModifiedPushChannelsPayloadResponse, Error>) -> Void)?
  ) {
    route(PushRouter(.removeAllPushChannels(pushToken: deviceToken, pushType: pushType), configuration: configuration),
          networkConfiguration: networkConfiguration,
          responseDecoder: ModifyPushResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  /// All channels on which APNS push notification has been enabled using specified device token and topic.
  /// - Parameters:
  ///   - for: The device token used during registration
  ///   - on: The topic of the device
  ///   - environment: The environment to register the device
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func listAPNSChannelsOnDevice(
    for deviceToken: Data,
    on topic: String,
    environment: PushRouter.Environment = .development,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<RegisteredPushChannelsPayloadResponse, Error>) -> Void)?
  ) {
    route(PushRouter(.modifyAPNS(pushToken: deviceToken, environment: environment,
                                 topic: topic, adding: [], removing: []),
                     configuration: configuration),
          networkConfiguration: networkConfiguration,
          responseDecoder: RegisteredPushChannelsResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  /// Adds or removes APNS push notification functionality on provided set of channels for a given topic
  /// - Parameters:
  ///   - byRemoving: The list of channels to remove the device registration from
  ///   - thenAdding: The list of channels to add the device registration to
  ///   - device: The device to add/remove from the channels
  ///   - on: The topic of the device
  ///   - environment: The environment to register the device
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func modifyAPNSDevicesOnChannels(
    byRemoving removals: [String],
    thenAdding additions: [String],
    device token: Data,
    on topic: String,
    environment: PushRouter.Environment = .development,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<ModifiedPushChannelsPayloadResponse, Error>) -> Void)?
  ) {
    let router = PushRouter(
      .modifyAPNS(pushToken: token, environment: environment,
                  topic: topic, adding: additions, removing: removals),
      configuration: configuration
    )

    if removals.isEmpty, additions.isEmpty {
      completion?(
        .failure(PubNubError(.missingRequiredParameter,
                             router: router,
                             additional: [ErrorDescription.missingChannelsAnyGroups])))
    }

    route(router,
          networkConfiguration: networkConfiguration,
          responseDecoder: ModifyPushResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  /// Disable APNS push notifications from all channels which is registered with specified pushToken.
  /// - Parameters:
  ///   - for: The device token to remove from all channels
  ///   - on: The topic of the device
  ///   - environment: TThe environment to register the device
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func removeAPNSPushDevice(
    for deviceToken: Data,
    on topic: String,
    environment: PushRouter.Environment = .development,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<ModifiedPushChannelsPayloadResponse, Error>) -> Void)?
  ) {
    route(PushRouter(.removeAllAPNS(pushToken: deviceToken, environment: environment, topic: topic),
                     configuration: configuration),
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
  /// - Important: History with Message Actions will only return the history of the first channel in the list
  ///
  /// - Parameters:
  ///   - for: List of channels to fetch history messages from.
  ///   - fetchActions: Include MessageAction in response
  ///   - max: The max number of messages to retrieve.
  ///   - start: Time token delimiting the start of time slice (exclusive) to pull messages from.
  ///   - end: Time token delimiting the end of time slice (inclusive) to pull messages from.
  ///   - metaInResponse: If `true` the meta properties of messages will be returned as well (if existing).
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func fetchMessageHistory(
    for channels: [String],
    fetchActions actions: Bool = false,
    max: Int? = nil,
    start: Timetoken? = nil,
    end: Timetoken? = nil,
    metaInResponse: Bool = false,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<MessageHistoryChannelsPayload, Error>) -> Void)?
  ) {
    let router: HistoryRouter
    switch (channels.count, actions) {
    case (1, false):
      router = HistoryRouter(
        .fetchV2(channel: channels.first ?? "",
                 max: max, start: start, end: end, includeMeta: metaInResponse),
        configuration: configuration
      )
    case (_, true):
      router = HistoryRouter(
        .fetchWithActions(channel: channels.first ?? "",
                          max: max, start: start, end: end, includeMeta: metaInResponse),
        configuration: configuration
      )
    default:
      router = HistoryRouter(
        .fetchV3(channels: channels, max: max, start: start, end: end, includeMeta: metaInResponse),
        configuration: configuration
      )
    }

    route(router,
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
    route(HistoryRouter(.delete(channel: channel, start: stateTimetoken, end: endTimetoken),
                        configuration: configuration),
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
    let router = HistoryRouter(
      .messageCounts(channels: channels.map { $0.key }, timetoken: nil, channelsTimetoken: channels.map { $0.value }),
      configuration: configuration
    )

    route(router,
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
    let router = HistoryRouter(
      .messageCounts(channels: channels, timetoken: timetoken, channelsTimetoken: nil),
      configuration: configuration
    )

    route(router,
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
    include field: CustomIncludeField? = nil,
    limit: Int? = nil,
    start: String? = nil,
    end: String? = nil,
    count: Bool? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserObjectsResponsePayload, Error>) -> Void)?
  ) {
    route(UserObjectsRouter(.fetchAll(include: field, limit: limit, start: start, end: end, count: count),
                            configuration: configuration),
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
    include field: CustomIncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserObject, Error>) -> Void)?
  ) {
    route(UserObjectsRouter(.fetch(userID: userID, include: field), configuration: configuration),
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
    include field: CustomIncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserObject, Error>) -> Void)?
  ) {
    route(UserObjectsRouter(.create(user: user, include: field), configuration: configuration),
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
    include field: CustomIncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserObject, Error>) -> Void)?
  ) {
    route(UserObjectsRouter(.update(user: user, include: field), configuration: configuration),
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
    route(UserObjectsRouter(.delete(userID: userID), configuration: configuration),
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
    include fields: [CustomIncludeField]? = nil,
    limit: Int? = nil,
    start: String? = nil,
    end: String? = nil,
    count: Bool? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserMembershipsResponsePayload, Error>) -> Void)?
  ) {
    route(UserObjectsRouter(
      .fetchMemberships(userID: userID, include: fields, limit: limit, start: start, end: end, count: count),
      configuration: configuration
    ),
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
    include fields: [CustomIncludeField]? = nil,
    limit: Int? = nil,
    start: String? = nil,
    end: String? = nil,
    count: Bool? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<UserMembershipsResponsePayload, Error>) -> Void)?
  ) {
    let router = UserObjectsRouter(
      .modifyMemberships(
        userID: userID,
        joining: joinedSpaceIDs, updating: updateSpaceIDs, leaving: leavingSpaceIDs,
        include: fields, limit: limit, start: start, end: end, count: count
      ),
      configuration: configuration
    )

    route(router,
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
    include field: CustomIncludeField? = nil,
    limit: Int? = nil,
    start: String? = nil,
    end: String? = nil,
    count: Bool? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceObjectsResponsePayload, Error>) -> Void)?
  ) {
    route(SpaceObjectsRouter(.fetchAll(include: field, limit: limit, start: start, end: end, count: count),
                             configuration: configuration),
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
    include field: CustomIncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceObject, Error>) -> Void)?
  ) {
    route(SpaceObjectsRouter(.fetch(spaceID: spaceID, include: field), configuration: configuration),
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
    include field: CustomIncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceObject, Error>) -> Void)?
  ) {
    route(SpaceObjectsRouter(.create(space: space, include: field), configuration: configuration),
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
    include field: CustomIncludeField? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceObject, Error>) -> Void)?
  ) {
    route(SpaceObjectsRouter(.update(space: space, include: field), configuration: configuration),
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
    route(SpaceObjectsRouter(.delete(spaceID: spaceID), configuration: configuration),
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
    include fields: [CustomIncludeField]? = nil,
    limit: Int? = nil,
    start: String? = nil,
    end: String? = nil,
    count: Bool? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceMembershipResponsePayload, Error>) -> Void)?
  ) {
    route(SpaceObjectsRouter(
      .fetchMembers(spaceID: spaceID, include: fields, limit: limit, start: start, end: end, count: count),
      configuration: configuration
    ),
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
    include fields: [CustomIncludeField]? = nil,
    limit: Int? = nil,
    start: String? = nil,
    end: String? = nil,
    count: Bool? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<SpaceMembershipResponsePayload, Error>) -> Void)?
  ) {
    let router = SpaceObjectsRouter(
      .modifyMembers(
        spaceID: spaceID,
        adding: addedUserIDs, updating: updateUserIDs, removing: removeUserIDs,
        include: fields,
        limit: limit, start: start, end: end, count: count
      ),
      configuration: configuration
    )

    route(router,
          networkConfiguration: networkConfiguration,
          responseDecoder: SpaceMembershipObjectsResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }
}

// MARK: - Message Actions

extension PubNub {
  /// Fetch a list of Message Actions for a channel
  /// - Parameters:
  ///   - channel: The name of the channel
  ///   - start: Action timetoken denoting the start of the range requested (exclusive).
  ///   - end: Action timetoken denoting the end of the range requested (inclusive).
  ///   - limit: The max number of message actions to retrieve per request
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func fetchMessageActions(
    channel: String,
    start: Timetoken? = nil,
    end: Timetoken? = nil,
    limit: Int? = nil,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<MessageActionsResponsePayload, Error>) -> Void)?
  ) {
    route(MessageActionsRouter(.fetch(channel: channel, start: start, end: end, limit: limit),
                               configuration: configuration),
          networkConfiguration: networkConfiguration,
          responseDecoder: MessageActionsResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  /// Add an Action to a parent Message
  /// - Parameters:
  ///   - channel: The name of the channel
  ///   - message: The Message Action to associate with a Message
  ///   - messageTimetoken: The publish timetoken of a parent message.
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func addMessageAction(
    channel: String,
    message: MessageAction,
    messageTimetoken: Timetoken,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<MessageActionResponsePayload, Error>) -> Void)?
  ) {
    route(MessageActionsRouter(.add(channel: channel, message: message, timetoken: messageTimetoken),
                               configuration: configuration),
          networkConfiguration: networkConfiguration,
          responseDecoder: MessageActionResponseDecoder(),
          respondOn: queue) { result in
      completion?(result.map { $0.payload })
    }
  }

  /// Removes a Message Action from a published Message
  /// - Parameters:
  ///   - channel: The name of the channel
  ///   - message: The publish timetoken of a parent message.
  ///   - action: The action timetoken of a message action to be removed.
  ///   - with: Additional network configuration to use on the request
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func removeMessageActions(
    channel: String,
    message timetoken: Timetoken,
    action actionTimetoken: Timetoken,
    with networkConfiguration: NetworkConfiguration? = nil,
    respondOn queue: DispatchQueue = .main,
    completion: ((Result<DeleteResponsePayload, Error>) -> Void)?
  ) {
    route(MessageActionsRouter(.remove(channel: channel, message: timetoken, action: actionTimetoken),
                               configuration: configuration),
          networkConfiguration: networkConfiguration,
          responseDecoder: DeleteResponseDecoder(),
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
