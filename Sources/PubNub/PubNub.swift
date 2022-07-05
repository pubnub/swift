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
public class PubNub {
  /// Instance identifier
  public let instanceID: UUID
  /// A copy of the configuration object used for this session
  public private(set) var configuration: PubNubConfiguration

  /// Session used for performing request/response REST calls
  public let networkSession: SessionReplaceable
  /// Session used for performing subscription calls
  public let subscription: SubscriptionSession

  /// The URLSession used when making File upload/download requests
  public var fileURLSession: URLSessionReplaceable
  /// The URLSessionDelegate used by the `fileSession` to handle file responses
  public var fileSessionManager: FileSessionManager? {
    return fileURLSession.delegate as? FileSessionManager
  }

  /// Global log instance for the PubNub SDK
  public static var log = PubNubLogger(levels: [.event, .warn, .error], writers: [ConsoleLogWriter(), FileLogWriter()])
  // Global log instance for Logging issues/events
  public static var logLog = PubNubLogger(levels: [.log], writers: [ConsoleLogWriter()])

  /// Creates a PubNub session with the specified configuration
  ///
  /// - Parameters:
  ///   - configuration: The default configurations that will be used
  ///   - session: Session used for performing request/response REST calls
  ///   - subscribeSession: The network session used for Subscription only
  public init(
    configuration: PubNubConfiguration,
    session: SessionReplaceable? = nil,
    subscribeSession: SessionReplaceable? = nil,
    fileSession: URLSessionReplaceable? = nil
  ) {
    instanceID = UUID()
    self.configuration = configuration

    // Default operators based on config
    var operators = [RequestOperator]()
    if let retryOperator = configuration.automaticRetry {
      operators.append(retryOperator)
    }
    if configuration.useInstanceId {
      let instanceIdOperator = InstanceIdOperator(instanceID: instanceID.description)
      operators.append(instanceIdOperator)
    }

    // Mutable session
    var networkSession = session ?? HTTPSession(configuration: configuration.urlSessionConfiguration)

    // Configure the default request operators
    if networkSession.defaultRequestOperator == nil {
      networkSession.defaultRequestOperator = MultiplexRequestOperator(operators: operators)
    } else {
      networkSession.defaultRequestOperator = networkSession
        .defaultRequestOperator?
        .merge(requestOperator: MultiplexRequestOperator(operators: operators))
    }

    // Immutable session
    self.networkSession = networkSession

    // Set initial session also based on configuration
    subscription = SubscribeSessionFactory.shared.getSession(
      from: configuration,
      with: subscribeSession,
      presenceSession: session
    )

    if let fileSession = fileSession {
      fileURLSession = fileSession
    } else {
      fileURLSession = URLSession(
        configuration: .pubnubBackground,
        delegate: FileSessionManager(),
        delegateQueue: .main
      )
    }
  }

  func route<Decoder>(
    _ router: HTTPRouter,
    responseDecoder: Decoder,
    custom requestConfig: RequestConfiguration,
    completion: @escaping (Result<EndpointResponse<Decoder.Payload>, Error>) -> Void
  ) where Decoder: ResponseDecoder {
    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: responseDecoder,
        responseQueue: requestConfig.responseQueue,
        completion: completion
      )
  }
}

// MARK: - Request Helpers

public extension PubNub {
  /// The APNs Environment that notifications will be sent through
  ///
  /// This should match the value mapped to the `aps-environment` key in your Info.plist
  ///
  /// See [APS Environment Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/aps-environment)
  /// for more information.
  enum PushEnvironment: String, Codable, Hashable {
    /// The APNs development environment.
    case development
    /// The APNs production environment.
    case production
  }

  /// The identifier of the Push Service being used
  enum PushService: String, Codable, Hashable {
    /// Apple Push Notification Service
    case apns
    /// Firebase Cloude Messaging
    case gcm
    /// Microsoft Push Notification Service
    case mpns
  }

  /// Configuration overrides for a single request
  struct RequestConfiguration {
    /// The custom Network session that that will be used to make the request
    public var customSession: SessionReplaceable?
    /// The endpoint configuration used by the request
    public var customConfiguration: RouterConfiguration?
    /// The response queue that will
    public var responseQueue: DispatchQueue

    /// Default init for all fields
    /// - Parameters:
    ///   - customSession: The custom Network session that that will be used to make the request
    ///   - customConfiguration: The endpoint configuration used by the request
    ///   - responseQueue: The response queue that will
    ///
    public init(
      customSession: SessionReplaceable? = nil,
      customConfiguration: RouterConfiguration? = nil,
      responseQueue: DispatchQueue = .main
    ) {
      self.customSession = customSession
      self.customConfiguration = customConfiguration
      self.responseQueue = responseQueue
    }
  }

  /// A start and end value for a PubNub paged request
  struct Page: PubNubHashedPage, Hashable {
    public var start: String?
    public var end: String?
    public let totalCount: Int?

    /// Default init
    /// - Parameters:
    ///   - start: The value of the  start of a next page
    ///   - end: The value of the end of a slice of paged data
    public init(start: String? = nil, end: String? = nil, totalCount: Int? = nil) {
      self.start = start
      self.end = end
      self.totalCount = totalCount
    }

    public init(next: String?, prev: String?, totalCount: Int?) {
      self.init(start: next, end: prev, totalCount: totalCount)
    }

    public init(from other: PubNubHashedPage) throws {
      self.init(start: other.start, end: other.end, totalCount: other.totalCount)
    }
  }
}

// MARK: - Time

public extension PubNub {
  /// Get current `Timetoken` from System
  /// - Parameters:
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The current `Timetoken`
  ///     - **Failure**: An `Error` describing the failure
  func time(
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Timetoken, Error>) -> Void)?
  ) {
    route(TimeRouter(.time, configuration: requestConfig.customConfiguration ?? configuration),
          responseDecoder: TimeResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.timetoken })
    }
  }
}

// MARK: - Publish

public extension PubNub {
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `Timetoken` of the published Message
  ///     - **Failure**: An `Error` describing the failure
  func publish(
    channel: String,
    message: JSONCodable,
    shouldStore: Bool? = nil,
    storeTTL: Int? = nil,
    meta: JSONCodable? = nil,
    shouldCompress: Bool = false,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Timetoken, Error>) -> Void)?
  ) {
    let router: PublishRouter
    if shouldCompress {
      router = PublishRouter(
        .compressedPublish(message: message.codableValue,
                           channel: channel,
                           shouldStore: shouldStore,
                           ttl: storeTTL,
                           meta: meta?.codableValue),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    } else {
      router = PublishRouter(
        .publish(message: message.codableValue,
                 channel: channel,
                 shouldStore: shouldStore,
                 ttl: storeTTL,
                 meta: meta?.codableValue),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    }

    route(router,
          responseDecoder: PublishResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.timetoken })
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `Timetoken` of the published Message
  ///     - **Failure**: An `Error` describing the failure
  func fire(
    channel: String,
    message: JSONCodable,
    meta: JSONCodable? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Timetoken, Error>) -> Void)?
  ) {
    route(PublishRouter(.fire(message: message.codableValue, channel: channel, meta: meta?.codableValue),
                        configuration: requestConfig.customConfiguration ?? configuration),
          responseDecoder: PublishResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.timetoken })
    }
  }

  /// Publish a message to PubNub Functions Event Handlers
  ///
  /// - Parameters:
  ///   - channel: The destination of the message
  ///   - message: The message to publish
  ///   - shouldCompress: Whether the message needs to be compressed before transmission
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `Timetoken` of the published Message
  ///     - **Failure**: An `Error` describing the failure
  func signal(
    channel: String,
    message: JSONCodable,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Timetoken, Error>) -> Void)?
  ) {
    route(PublishRouter(.signal(message: message.codableValue, channel: channel),
                        configuration: requestConfig.customConfiguration ?? configuration),
          responseDecoder: PublishResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.timetoken })
    }
  }
}

// MARK: - Subscription

public extension PubNub {
  /// Subscribe to channels and/or channel groups
  ///
  /// - Parameters:
  ///   - to: List of channels to subscribe on
  ///   - and: List of channel groups to subscribe on
  ///   - at: The initial timetoken to subscribe with
  ///   - withPresence: If true it also subscribes to presence events on the specified channels.
  ///   - region: The region code from a previous `SubscribeCursor`
  ///   - filterOverride: Overrides the previous filter on the next successful request
  func subscribe(
    to channels: [String],
    and channelGroups: [String] = [],
    at timetoken: Timetoken? = nil,
    withPresence: Bool = false,
    filterOverride: String? = nil
  ) {
    subscription.filterExpression = filterOverride

    subscription.subscribe(to: channels,
                           and: channelGroups,
                           at: SubscribeCursor(timetoken: timetoken),
                           withPresence: withPresence)
  }

  /// Unsubscribe from channels and/or channel groups
  ///
  /// - Parameters:
  ///   - from: List of channels to unsubscribe from
  ///   - and: List of channel groups to unsubscribe from
  ///   - presenceOnly: If true, it only unsubscribes from presence events on the specified channels.
  func unsubscribe(from channels: [String], and channelGroups: [String] = [], presenceOnly: Bool = false) {
    subscription.unsubscribe(from: channels, and: channelGroups, presenceOnly: presenceOnly)
  }

  /// Unsubscribe from all channels and channel groups
  func unsubscribeAll() {
    subscription.unsubscribeAll()
  }

  /// Stops the subscriptions in progress
  /// - Important: This subscription might be shared with multiple `PubNub` instances.
  func disconnect() {
    subscription.disconnect()
  }

  /// Reconnets to a stopped subscription with the previous subscribed channels and channel groups
  /// - Parameter at: The timetoken value used to reconnect or nil to use the previous stored value
  /// - Important: This subscription might be shared with multiple `PubNub` instances.
  func reconnect(at timetoken: Timetoken? = nil) {
    subscription.reconnect(at: SubscribeCursor(timetoken: timetoken))
  }

  /// The `Timetoken` used for the last successful subscription request
  var previousTimetoken: Timetoken? {
    return subscription.previousTokenResponse?.timetoken
  }

  /// Add a listener to enable the receiving of subscription events
  /// - Parameter listener: The subscription listener to be added
  func add(_ listener: BaseSubscriptionListener) {
    subscription.add(listener)
  }

  /// List of currently subscribed channels
  var subscribedChannels: [String] {
    return subscription.subscribedChannels
  }

  /// List of currently subscribed channel groups
  var subscribedChannelGroups: [String] {
    return subscription.subscribedChannelGroups
  }

  /// The total number of channels and channel groups that are currently subscribed to
  var subscriptionCount: Int {
    return subscription.subscriptionCount
  }

  /// The current state of the subscription connection
  var connectionStatus: ConnectionStatus {
    return subscription.connectionStatus
  }

  /// An override for the default filter expression set during initialization
  internal var subscribeFilterExpression: String? {
    get { return subscription.filterExpression }
    set {
      subscription.filterExpression = newValue
    }
  }
}

// MARK: - Presence Management

public extension PubNub {
  /// Set state dictionary pairs specific to a subscriber uuid
  /// - Parameters:
  ///   - state: The UUID for which to query the subscribed channels of
  ///   - on: Additional network configuration to use on the request
  ///   - and: The queue the completion handler should be returned on
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The presence State set as a `JSONCodable`
  ///     - **Failure**: An `Error` describing the failure
  func setPresence(
    state: [String: JSONCodableScalar],
    on channels: [String],
    and groups: [String] = [],
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<JSONCodable, Error>) -> Void)?
  ) {
    let router = PresenceRouter(
      .setState(channels: channels, groups: groups, state: state),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: PresenceResponseDecoder<AnyPresencePayload<AnyJSON>>(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.payload })
    }
  }

  /// Get state dictionary pairs from a specific subscriber uuid
  /// - Parameters:
  ///   - for: The UUID for which to query the subscribed channels of
  ///   - on: Additional network configuration to use on the request
  ///   - and: The queue the completion handler should be returned on
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the UUID that set the State and a `Dictionary` of channels mapped to their respective State
  ///     - **Failure**: An `Error` describing the failure
  func getPresenceState(
    for uuid: String,
    on channels: [String],
    and groups: [String] = [],
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(uuid: String, stateByChannel: [String: JSONCodable]), Error>) -> Void)?
  ) {
    let router = PresenceRouter(
      .getState(uuid: uuid, channels: channels, groups: groups),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: GetPresenceStateResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { (uuid: $0.payload.uuid, stateByChannel: $0.payload.channels) })
    }
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
  ///   - includeUUIDs: `true` will include the UUIDs of those present on the channel
  ///   - includeState: `true` will return the presence channel state information if available
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Dictionary` of channels mapped to their respective `PubNubPresence`
  ///     - **Failure**: An `Error` describing the failure
  func hereNow(
    on channels: [String],
    and groups: [String] = [],
    includeUUIDs: Bool = true,
    includeState: Bool = false,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String: PubNubPresence], Error>) -> Void)?
  ) {
    let router: PresenceRouter
    if channels.isEmpty, groups.isEmpty {
      router = PresenceRouter(.hereNowGlobal(includeUUIDs: includeUUIDs, includeState: includeState),
                              configuration: requestConfig.customConfiguration ?? configuration)
    } else {
      router = PresenceRouter(
        .hereNow(channels: channels, groups: groups, includeUUIDs: includeUUIDs, includeState: includeState),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    }

    let decoder = HereNowResponseDecoder(channels: channels, groups: groups)

    route(router,
          responseDecoder: decoder,
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.asPubNubPresenceBase })
    }
  }

  /// Obtain information about the current list of channels a UUID is subscribed to
  /// - Parameters:
  ///   - for: The UUID for which to query the subscribed channels of
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**:  A `Dictionary` of UUIDs mapped to their respective `Array` of channels they have presence on
  ///     - **Failure**: An `Error` describing the failure
  func whereNow(
    for uuid: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String: [String]], Error>) -> Void)?
  ) {
    route(PresenceRouter(.whereNow(uuid: uuid), configuration: requestConfig.customConfiguration ?? configuration),
          responseDecoder: PresenceResponseDecoder<AnyPresencePayload<WhereNowPayload>>(),
          custom: requestConfig) { result in
      completion?(result.map { [uuid: $0.payload.payload.channels] })
    }
  }
}

// MARK: - Channel Group Management

public extension PubNub {
  /// Lists all the channel groups
  /// - Parameters:
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: List of all channel-groups
  ///     - **Failure**: An `Error` describing the failure
  func listChannelGroups(
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String], Error>) -> Void)?
  ) {
    route(ChannelGroupsRouter(.channelGroups, configuration: requestConfig.customConfiguration ?? configuration),
          responseDecoder: ChannelGroupResponseDecoder<GroupListPayloadResponse>(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.payload.groups })
    }
  }

  /// Removes the channel group.
  /// - Parameters:
  ///   - channelGroup: The channel group to remove.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The channel-group that was removed
  ///     - **Failure**: An `Error` describing the failure
  ///   - result: A `Result` containing  either the removed channel-group  **or** an `Error`
  func remove(
    channelGroup: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    route(
      ChannelGroupsRouter(
        .deleteGroup(group: channelGroup),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      responseDecoder: GenericServiceResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in channelGroup })
    }
  }

  /// Lists all the channels of the channel group.
  /// - Parameters:
  ///   - for: The channel group to list channels on.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the channel-group and the `Array` of  its channels
  ///     - **Failure**: An `Error` describing the failure
  func listChannels(
    for group: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(group: String, channels: [String]), Error>) -> Void)?
  ) {
    route(
      ChannelGroupsRouter(
        .channelsForGroup(group: group),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      responseDecoder: ChannelGroupResponseDecoder<ChannelListPayloadResponse>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { ($0.payload.payload.group, $0.payload.payload.channels) })
    }
  }

  /// Adds a channel to a channel group.
  /// - Parameters:
  ///   - channels: List of channels to add to the group
  ///   - to: The Channel Group to add the list of channels to.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the channel-group and the `Array` of channels added
  ///     - **Failure**: An `Error` describing the failure
  func add(
    channels: [String],
    to group: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(group: String, channels: [String]), Error>) -> Void)?
  ) {
    route(
      ChannelGroupsRouter(
        .addChannelsToGroup(group: group, channels: channels),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      responseDecoder: GenericServiceResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in (group, channels) })
    }
  }

  /// Rremoves the channels from the channel group.
  /// - Parameters:
  ///   - channels: List of channels to remove from the group
  ///   - from: The Channel Group to remove the list of channels from
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the channel-group and the `Array` of channels removed
  ///     - **Failure**: An `Error` describing the failure
  func remove(
    channels: [String],
    from group: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(group: String, channels: [String]), Error>) -> Void)?
  ) {
    route(
      ChannelGroupsRouter(
        .removeChannelsForGroup(group: group, channels: channels),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      responseDecoder: GenericServiceResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in (group, channels) })
    }
  }
}

// MARK: - Push

public extension PubNub {
  /// All channels on which push notification has been enabled using specified pushToken.
  /// - Parameters:
  ///   - for: The Channel Group to remove the list of channels from
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An `Array` of all channels registered to the device token
  ///     - **Failure**: An `Error` describing the failure
  func listPushChannelRegistrations(
    for deviceToken: Data,
    of pushType: PushService = .apns,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String], Error>) -> Void)?
  ) {
    route(
      PushRouter(
        .listPushChannels(pushToken: deviceToken, pushType: pushType),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      responseDecoder: RegisteredPushChannelsResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.channels })
    }
  }

  /// Adds or removes push notification functionality on provided set of channels.
  /// - Parameters:
  ///   - byRemoving: The list of channels to remove the device registration from
  ///   - thenAdding: The list of channels to add the device registration to
  ///   - for: A device token to identify the device for registration changes
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of channels added and an `Array` of channels removed for notifications on a specific device token
  ///     - **Failure**: An `Error` describing the failure
  func managePushChannelRegistrations(
    byRemoving removals: [String],
    thenAdding additions: [String],
    for deviceToken: Data,
    of pushType: PushService = .apns,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(added: [String], removed: [String]), Error>) -> Void)?
  ) {
    let router = PushRouter(
      .managePushChannels(pushToken: deviceToken, pushType: pushType, joining: additions, leaving: removals),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: ModifyPushResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { (added: $0.payload.added, removed: $0.payload.removed) })
    }
  }

  /// Adds or removes push notification functionality on provided set of channels.
  /// - Parameters:
  ///   - additions: The list of channels to add the device registration to
  ///   - for: A device token to identify the device for registration changes
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An `Array` of channels added for notifications on a specific device token
  ///     - **Failure**: An `Error` describing the failure
  func addPushChannelRegistrations(
    _ additions: [String],
    for deviceToken: Data,
    of pushType: PushService = .apns,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String], Error>) -> Void)?
  ) {
    managePushChannelRegistrations(
      byRemoving: [], thenAdding: additions,
      for: deviceToken, of: pushType,
      custom: requestConfig
    ) { completion?($0.map { $0.added }) }
  }

  /// Adds or removes push notification functionality on provided set of channels.
  /// - Parameters:
  ///   - removals: The list of channels to remove the device registration from
  ///   - for: A device token to identify the device for registration changes
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An `Array` of channels removed from notifications on a specific device token
  ///     - **Failure**: An `Error` describing the failure
  func removePushChannelRegistrations(
    _ removals: [String],
    for deviceToken: Data,
    of pushType: PushService = .apns,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String], Error>) -> Void)?
  ) {
    managePushChannelRegistrations(
      byRemoving: removals, thenAdding: [],
      for: deviceToken, of: pushType,
      custom: requestConfig
    ) { completion?($0.map { $0.removed }) }
  }

  /// Disable push notifications from all channels which is registered with specified pushToken.
  /// - Parameters:
  ///   - for: The Channel Group to remove the list of channels from
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Void`indicating a success
  ///     - **Failure**: An `Error` describing the failure
  func removeAllPushChannelRegistrations(
    for deviceToken: Data,
    of pushType: PushService = .apns,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    route(
      PushRouter(
        .removeAllPushChannels(pushToken: deviceToken, pushType: pushType),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      responseDecoder: ModifyPushResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in () })
    }
  }

  /// All channels on which APNS push notification has been enabled using specified device token and topic.
  /// - Parameters:
  ///   - for: The device token used during registration
  ///   - on: The topic of the remote notification (which is typically the bundle ID for your app)
  ///   - environment: The APS environment to register the device
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An `Array` of all channels registered to the device token
  ///     - **Failure**: An `Error` describing the failure
  func listAPNSPushChannelRegistrations(
    for deviceToken: Data,
    on topic: String,
    environment: PushEnvironment = .development,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String], Error>) -> Void)?
  ) {
    route(
      PushRouter(
        .manageAPNS(
          pushToken: deviceToken, environment: environment, topic: topic, adding: [], removing: []
        ),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      responseDecoder: RegisteredPushChannelsResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.channels })
    }
  }

  /// Adds or removes APNS push notification functionality on provided set of channels for a given topic
  /// - Parameters:
  ///   - byRemoving: The list of channels to remove the device registration from
  ///   - thenAdding: The list of channels to add the device registration to
  ///   - device: The device to add/remove from the channels
  ///   - on: The topic of the remote notification (which is typically the bundle ID for your app)
  ///   - environment: The APS environment to register the device
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of channels added and an `Array` of channels removed for notifications on a specific device token
  ///     - **Failure**: An `Error` describing the failure
  func manageAPNSDevicesOnChannels(
    byRemoving removals: [String],
    thenAdding additions: [String],
    device token: Data,
    on topic: String,
    environment: PushEnvironment = .development,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(added: [String], removed: [String]), Error>) -> Void)?
  ) {
    let router = PushRouter(
      .manageAPNS(pushToken: token, environment: environment,
                  topic: topic, adding: additions, removing: removals),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    if removals.isEmpty, additions.isEmpty {
      completion?(
        .failure(PubNubError(.missingRequiredParameter,
                             router: router,
                             additional: [ErrorDescription.missingChannelsAnyGroups])))
    } else {
      route(router,
            responseDecoder: ModifyPushResponseDecoder(),
            custom: requestConfig) { result in
        completion?(result.map { (added: $0.payload.added, removed: $0.payload.removed) })
      }
    }
  }

  /// Enable APNS2 push notifications on provided set of channels.
  /// - Parameters:
  ///   - additions: The list of channels to add the device registration to
  ///   - device: The device to add/remove from the channels
  ///   - on: The topic of the remote notification (which is typically the bundle ID for your app)
  ///   - environment: The APS environment to register the device
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**:An `Array` of channels added for notifications on a specific device token
  ///     - **Failure**: An `Error` describing the failure
  func addAPNSDevicesOnChannels(
    _ additions: [String],
    device token: Data,
    on topic: String,
    environment: PushEnvironment = .development,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String], Error>) -> Void)?
  ) {
    manageAPNSDevicesOnChannels(
      byRemoving: [], thenAdding: additions,
      device: token, on: topic, environment: environment,
      custom: requestConfig
    ) { completion?($0.map { $0.added }) }
  }

  /// Disables APNS2 push notifications on provided set of channels.
  /// - Parameters:
  ///   - removals: The list of channels to disable registration
  ///   - device: The device to add/remove from the channels
  ///   - on: The topic of the remote notification (which is typically the bundle ID for your app)
  ///   - environment: The APS environment to register the device
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**:An `Array` of channels disabled from notifications on a specific device token
  ///     - **Failure**: An `Error` describing the failure
  func removeAPNSDevicesOnChannels(
    _ removals: [String],
    device token: Data,
    on topic: String,
    environment: PushEnvironment = .development,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String], Error>) -> Void)?
  ) {
    manageAPNSDevicesOnChannels(
      byRemoving: removals, thenAdding: [],
      device: token, on: topic, environment: environment,
      custom: requestConfig
    ) { completion?($0.map { $0.removed }) }
  }

  /// Disable APNS push notifications from all channels which is registered with specified pushToken.
  /// - Parameters:
  ///   - for: The device token to remove from all channels
  ///   - on: The topic of the remote notification (which is typically the bundle ID for your app)
  ///   - environment: The APS environment to register the device
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Void`indicating a success
  ///     - **Failure**: An `Error` describing the failure
  func removeAllAPNSPushDevice(
    for deviceToken: Data,
    on topic: String,
    environment: PushEnvironment = .development,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    route(PushRouter(.removeAllAPNS(pushToken: deviceToken, environment: environment, topic: topic),
                     configuration: requestConfig.customConfiguration ?? configuration),
          responseDecoder: ModifyPushResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { _ in () })
    }
  }
}

// MARK: - History

public extension PubNub {
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
  ///   - includeActions: If `true` any Message Actions will be included in the response
  ///   - includeMeta: If `true` the meta properties of messages will be included in the response
  ///   - includeUUID: If `true` the UUID of the message publisher will be included with each message in the response
  ///   - includeMessageType: If `true` the message type will be included with each message
  ///   - page: The paging object used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` of a `Dictionary` of channels mapped to an `Array` their respective `PubNubMessages`, and the next request `PubNubBoundedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func fetchMessageHistory(
    for channels: [String],
    includeActions: Bool = false, includeMeta: Bool = false,
    includeUUID: Bool = true, includeMessageType: Bool = true,
    page: PubNubBoundedPage? = PubNubBoundedPageBase(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(messagesByChannel: [String: [PubNubMessage]], next: PubNubBoundedPage?), Error>) -> Void)?
  ) {
    let router: HistoryRouter

    switch (channels.count > 1, includeActions) {
    case (_, true):
      router = HistoryRouter(
        .fetchWithActions(
          channel: channels.first ?? "",
          max: page?.limit ?? 25, start: page?.start, end: page?.end,
          includeMeta: includeMeta, includeMessageType: includeMessageType,
          includeUUID: includeUUID
        ),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    case (false, _):
      router = HistoryRouter(
        .fetch(
          channels: channels, max: page?.limit ?? 100,
          start: page?.start, end: page?.end,
          includeMeta: includeMeta, includeMessageType: includeMessageType,
          includeUUID: includeUUID
        ),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    case (true, _):
      router = HistoryRouter(
        .fetch(
          channels: channels, max: page?.limit ?? 25,
          start: page?.start, end: page?.end,
          includeMeta: includeMeta, includeMessageType: includeMessageType,
          includeUUID: includeUUID
        ),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    }

    route(
      router,
      responseDecoder: MessageHistoryResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map {
        (
          messagesByChannel: $0.payload.asPubNubMessagesByChannel,
          next: $0.payload.asBoundedPage(end: page?.end, limit: page?.limit)
        )
      })
    }
  }

  /// Removes the messages from the history of a specific channel.
  /// - Parameters:
  ///   - from: The channel to delete the messages from.
  ///   - start: Time token delimiting the start of time slice (exclusive) to delete messages from.
  ///   - end: Time token delimiting the end of time slice (inclusive) to delete messages from.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Void` indicating a success
  ///     - **Failure**: An `Error` describing the failure
  func deleteMessageHistory(
    from channel: String,
    start: Timetoken? = nil,
    end: Timetoken? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    route(
      HistoryRouter(
        .delete(channel: channel, start: start, end: end),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      responseDecoder: GenericServiceResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in () })
    }
  }

  /// Returns the number of messages published for one of more channels using a channel specific time token
  /// - Parameters:
  ///   - channels: Dictionary of channel and the timetoken to get the message count for.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Dictionary` of channels mapped to their respective message count
  ///     - **Failure**: An `Error` describing the failure
  func messageCounts(
    channels: [String: Timetoken],
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String: Int], Error>) -> Void)?
  ) {
    let router = HistoryRouter(
      .messageCounts(channels: channels.map { $0.key }, timetoken: nil, channelsTimetoken: channels.map { $0.value }),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: MessageCountsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.channels })
    }
  }

  /// Returns the number of messages published for each channels for a single time
  /// - Parameters:
  ///   - channels: The channel to delete the messages from.
  ///   - timetoken: The timetoken for all channels in the list to get message counts for.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Dictionary` of channels mapped to their respective message count
  ///     - **Failure**: An `Error` describing the failure
  func messageCounts(
    channels: [String],
    timetoken: Timetoken = 1,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String: Int], Error>) -> Void)?
  ) {
    let router = HistoryRouter(
      .messageCounts(channels: channels, timetoken: timetoken, channelsTimetoken: nil),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: MessageCountsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.channels })
    }
  }
}

// MARK: - Message Actions

public extension PubNub {
  /// Fetch a list of Message Actions for a channel
  /// - Parameters:
  ///   - channel: The name of the channel
  ///   - page: The paging object used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An `Array` of `PubNubMessageAction` for the request channel, and the next request `PubNubBoundedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func fetchMessageActions(
    channel: String,
    page: PubNubBoundedPage? = PubNubBoundedPageBase(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(actions: [PubNubMessageAction], next: PubNubBoundedPage?), Error>) -> Void)?
  ) {
    route(
      MessageActionsRouter(
        .fetch(channel: channel, start: page?.start, end: page?.end, limit: page?.limit),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      responseDecoder: MessageActionsResponseDecoder(),
      custom: requestConfig
    ) { result in
      switch result {
      case let .success(response):
        completion?(.success((
          actions: response.payload.actions.map { PubNubMessageActionBase(from: $0, on: channel) },
          next: PubNubBoundedPageBase(
            start: response.payload.start, end: response.payload.end, limit: response.payload.limit
          )
        )))
      case let .failure(error):
        completion?(.failure(error))
      }
    }
  }

  /// Add an Action to a parent Message
  /// - Parameters:
  ///   - channel: The name of the channel
  ///   - type: The Message Action's type
  ///   - value: The Message Action's value
  ///   - messageTimetoken: The publish timetoken of a parent message.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubMessageAction` that was added
  ///     - **Failure**: An `Error` describing the failure
  func addMessageAction(
    channel: String,
    type actionType: String,
    value: String,
    messageTimetoken: Timetoken,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubMessageAction, Error>) -> Void)?
  ) {
    let router = MessageActionsRouter(
      .add(channel: channel, type: actionType, value: value, timetoken: messageTimetoken),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: MessageActionResponseDecoder(),
          custom: requestConfig) { result in
      switch result {
      case let .success(response):

        if let errorPayload = response.payload.error {
          let error = PubNubError(
            reason: errorPayload.message.pubnubReason, router: router,
            request: response.request, response: response.response,
            additional: errorPayload.details
          )
          completion?(.failure(error))
        }
        completion?(.success(PubNubMessageActionBase(from: response.payload.data, on: channel)))
      case let .failure(error):
        completion?(.failure(error))
      }
    }
  }

  /// Removes a Message Action from a published Message
  /// - Parameters:
  ///   - channel: The name of the channel
  ///   - message: The publish timetoken of a parent message.
  ///   - action: The action timetoken of a message action to be removed.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the channel, message `Timetoken`, and action `Timetoken` of the action that was removed
  ///     - **Failure**: An `Error` describing the failure
  func removeMessageActions(
    channel: String,
    message timetoken: Timetoken,
    action actionTimetoken: Timetoken,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    // swiftlint:disable:next large_tuple
    completion: ((Result<(channel: String, message: Timetoken, action: Timetoken), Error>) -> Void)?
  ) {
    let router = MessageActionsRouter(
      .remove(channel: channel, message: timetoken, action: actionTimetoken),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: DeleteResponseDecoder(),
          custom: requestConfig) { result in
      switch result {
      case let .success(response):
        if let errorPayload = response.payload.error {
          let error = PubNubError(
            reason: errorPayload.message.pubnubReason, router: router,
            request: response.request, response: response.response,
            additional: errorPayload.details
          )
          completion?(.failure(error))
        }

        completion?(.success((channel, timetoken, actionTimetoken)))
      case let .failure(error):
        completion?(.failure(error))
      }
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

    return crypto.encrypt(encoded: dataMessage)
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
}

// MARK: - PAM

public extension PubNub {
  /// Extract permissions from provided token,
  /// - Parameter token: The token from which permissions should be extracted.
  /// - Returns: PAMToken with permissions information.
  func parse(token: String) -> PAMToken? {
    return PAMToken.token(from: token)
  }

  /// Stores token for use in API calls.
  /// - Parameter token: The token to add to the Token Management System.
  func set(token: String) {
    configuration.authToken = token
    subscription.configuration.authToken = token
  }
}

// MARK: - Consumer

public extension PubNub {
  /// Set consumer identifying value for components usage.
  /// - Parameters:
  ///   - identifier: Identifier of consumer with which value will be associated.
  ///   - value: Value which should be associated with consumer identifier.
  func setConsumer(identifier: String, value: String) {
    configuration.consumerIdentifiers[identifier] = value
  }
  // swiftlint:disable:next file_length
}
