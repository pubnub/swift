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
  // PAM Token Manager
  internal var tokenStore: PAMTokenManagementSystem

  /// Global log instance for the PubNub SDK
  public static var log = PubNubLogger(levels: [.event, .warn, .error], writers: [ConsoleLogWriter(), FileLogWriter()])
  // Global log instance for Logging issues/events
  public static var logLog = PubNubLogger(levels: [.log], writers: [ConsoleLogWriter()])

  /// Creates a session with the specified configuration
  public init(
    configuration: PubNubConfiguration = .default,
    session: SessionReplaceable? = nil,
    subscribeSession: SessionReplaceable? = nil,
    presenceSession: SessionReplaceable? = nil
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
      presenceSession: presenceSession
    )

    tokenStore = PAMTokenManagementSystem()
  }

  func route<Decoder>(
    _ router: HTTPRouter,
    responseDecoder: Decoder,
    custom requestConfig: RequestConfiguration,
    completion: @escaping (Result<EndpointResponse<Decoder.Payload>, Error>) -> Void
  ) where Decoder: ResponseDecoder {
    (requestConfig.customSession ?? networkSession)
      .request(with: router, requestOperator: nil)
      .validate()
      .response(
        on: requestConfig.responseQueue,
        decoder: responseDecoder,
        completion: completion
      )
  }
}

// MARK: - Request Helpers

extension PubNub {
  public struct RequestConfiguration {
    public var customSession: SessionReplaceable?
    public var customConfiguration: RouterConfiguration?
    public var responseQueue: DispatchQueue

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

  public struct Page {
    public var start: String?
    public var end: String?

    public init?(start: String?, end: String?) {
      if start == nil, end == nil {
        return nil
      }

      self.start = start
      self.end = end
    }
  }

  public struct IncludeFields {
    public var customFields: Bool
    public var totalCount: Bool

    public init(custom: Bool = true, totalCount: Bool = true) {
      customFields = custom
      self.totalCount = totalCount
    }
  }

  public struct MembershipInclude {
    public var customFields: Bool
    public var channelFields: Bool
    public var channelCustomFields: Bool
    public var totalCount: Bool

    public init(
      customFields: Bool = true,
      channelFields: Bool = false,
      channelCustomFields: Bool = false,
      totalCount: Bool = false
    ) {
      self.customFields = customFields
      self.channelFields = channelFields
      self.channelCustomFields = channelCustomFields
      self.totalCount = totalCount
    }

    var customIncludes: [ObjectsMembershipsRouter.MembershipInclude]? {
      var includes = [ObjectsMembershipsRouter.MembershipInclude]()

      if customFields { includes.append(.custom) }
      if channelFields { includes.append(.channel) }
      if channelCustomFields { includes.append(.channelCustom) }

      return includes.isEmpty ? nil : includes
    }
  }

  public struct MemberInclude {
    public var customFields: Bool
    public var uuidFields: Bool
    public var uuidCustomFields: Bool
    public var totalCount: Bool

    public init(
      customFields: Bool = true,
      uuidFields: Bool = false,
      uuidCustomFields: Bool = false,
      totalCount: Bool = false
    ) {
      self.customFields = customFields
      self.uuidFields = uuidFields
      self.uuidCustomFields = uuidCustomFields
      self.totalCount = totalCount
    }

    var customIncludes: [ObjectsMembershipsRouter.MembershipInclude]? {
      var includes = [ObjectsMembershipsRouter.MembershipInclude]()

      if customFields { includes.append(.custom) }
      if uuidFields { includes.append(.uuid) }
      if uuidCustomFields { includes.append(.uuidCustom) }

      return includes.isEmpty ? nil : includes
    }
  }
}

// MARK: - Time

extension PubNub {
  /// Get current `Timetoken` from System
  /// - Parameters:
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func time(
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func publish(
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func fire(
    channel: String,
    message: JSONCodable,
    meta: JSONCodable? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Timetoken, Error>) -> Void)?
  ) {
    route(PublishRouter(.fire(message: message.codableValue, channel: channel, meta: meta?.codableValue),
                        configuration: configuration),
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func signal(
    channel: String,
    message: JSONCodable,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Timetoken, Error>) -> Void)?
  ) {
    route(PublishRouter(.signal(message: message.codableValue, channel: channel),
                        configuration: configuration),
          responseDecoder: PublishResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.timetoken })
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
  public func subscribe(
    to channels: [String],
    and channelGroups: [String] = [],
    at timetoken: Timetoken? = nil,
    region: Int? = nil,
    withPresence: Bool = false,
    filterOverride: String? = nil
  ) {
    subscription.customFilter = filterOverride

    subscription.subscribe(to: channels,
                           and: channelGroups,
                           at: SubscribeCursor(timetoken: timetoken, region: region),
                           withPresence: withPresence)
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
  public func reconnect(at timetoken: Timetoken? = nil, region: Int? = nil) {
    subscription.reconnect(at: SubscribeCursor(timetoken: timetoken, region: region))
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

  // An override for the default filter
  var subscribeFilterOverride: String? {
    get { return subscription.customFilter }
    set {
      subscription.customFilter = newValue
    }
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
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<JSONCodable, Error>) -> Void)?
  ) {
    let router = PresenceRouter(
      .setState(channels: channels, groups: groups, state: state),
      configuration: configuration
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
  ///   - completion: The async result of the method call
  public func getPresenceState(
    for uuid: String,
    on channels: [String],
    and groups: [String] = [],
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(uuid: String, stateByChannel: [String: JSONCodable]), Error>) -> Void)?
  ) {
    let router = PresenceRouter(
      .getState(uuid: uuid, channels: channels, groups: groups),
      configuration: configuration
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
  ///   - includeUUIDs: `false` disables the return of uuids
  ///   - also: `true` will return the subscribe state information if available
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func hereNow(
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
                              configuration: configuration)
    } else {
      router = PresenceRouter(
        .hereNow(channels: channels, groups: groups, includeUUIDs: includeUUIDs, includeState: includeState),
        configuration: configuration
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func whereNow(
    for uuid: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String: [String]], Error>) -> Void)?
  ) {
    route(PresenceRouter(.whereNow(uuid: uuid), configuration: configuration),
          responseDecoder: PresenceResponseDecoder<AnyPresencePayload<WhereNowPayload>>(),
          custom: requestConfig) { result in
      completion?(result.map { [uuid: $0.payload.payload.channels] })
    }
  }
}

// MARK: - Channel Group Management

extension PubNub {
  /// Lists all the channel groups
  /// - Parameters:
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func listChannelGroups(
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String], Error>) -> Void)?
  ) {
    route(ChannelGroupsRouter(.channelGroups, configuration: configuration),
          responseDecoder: ChannelGroupResponseDecoder<GroupListPayloadResponse>(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.payload.groups })
    }
  }

  /// Removes the channel group.
  /// - Parameters:
  ///   - channelGroup: The channel group to delete.
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func delete(
    channelGroup: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    route(
      ChannelGroupsRouter(.deleteGroup(group: channelGroup), configuration: configuration),
      responseDecoder: GenericServiceResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in channelGroup })
    }
  }

  /// Lists all the channels of the channel group.
  /// - Parameters:
  ///   - for: The channel group to list channels on.
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func listChannels(
    for group: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String: [String]], Error>) -> Void)?
  ) {
    route(ChannelGroupsRouter(.channelsForGroup(group: group), configuration: configuration),
          responseDecoder: ChannelGroupResponseDecoder<ChannelListPayloadResponse>(),
          custom: requestConfig) { result in
      completion?(result.map { [$0.payload.payload.group: $0.payload.payload.channels] })
    }
  }

  /// Adds a channel to a channel group.
  /// - Parameters:
  ///   - channels: List of channels to add to the group
  ///   - to: The Channel Group to add the list of channels to.
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func add(
    channels: [String],
    to group: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    route(ChannelGroupsRouter(.addChannelsToGroup(group: group, channels: channels), configuration: configuration),
          responseDecoder: GenericServiceResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { _ in () })
    }
  }

  /// Rremoves the channels from the channel group.
  /// - Parameters:
  ///   - channels: List of channels to remove from the group
  ///   - from: The Channel Group to remove the list of channels from
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func remove(
    channels: [String],
    from group: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String: [String]], Error>) -> Void)?
  ) {
    route(ChannelGroupsRouter(.removeChannelsForGroup(group: group, channels: channels), configuration: configuration),
          responseDecoder: GenericServiceResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { _ in [group: channels] })
    }
  }
}

// MARK: - Push

extension PubNub {
  /// All channels on which push notification has been enabled using specified pushToken.
  /// - Parameters:
  ///   - for: The Channel Group to remove the list of channels from
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func listPushChannelRegistrations(
    for deviceToken: Data,
    of pushType: PushRouter.PushType = .apns,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String], Error>) -> Void)?
  ) {
    route(PushRouter(.listPushChannels(pushToken: deviceToken, pushType: pushType), configuration: configuration),
          responseDecoder: RegisteredPushChannelsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.channels })
    }
  }

  /// Adds or removes push notification functionality on provided set of channels.
  /// - Parameters:
  ///   - byRemoving: The list of channels to remove the device registration from
  ///   - thenAdding: The list of channels to add the device registration to
  ///   - for: A device token to identify the device for registration changes
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func managePushChannelRegistrations(
    byRemoving removals: [String],
    thenAdding additions: [String],
    for deviceToken: Data,
    of pushType: PushRouter.PushType = .apns,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(added: [String], removed: [String]), Error>) -> Void)?
  ) {
    let router = PushRouter(
      .managePushChannels(pushToken: deviceToken, pushType: pushType, joining: additions, leaving: removals),
      configuration: configuration
    )

    route(router,
          responseDecoder: ModifyPushResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { (added: $0.payload.added, removed: $0.payload.removed) })
    }
  }

  /// Adds or removes push notification functionality on provided set of channels.
  /// - Parameters:
  ///   - byRemoving: The list of channels to remove the device registration from
  ///   - thenAdding: The list of channels to add the device registration to
  ///   - for: A device token to identify the device for registration changes
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func addingPushChannelRegistrations(
    _ additions: [String],
    for deviceToken: Data,
    of pushType: PushRouter.PushType = .apns,
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
  ///   - byRemoving: The list of channels to remove the device registration from
  ///   - thenAdding: The list of channels to add the device registration to
  ///   - for: A device token to identify the device for registration changes
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func removingPushChannelRegistrations(
    _ removals: [String],
    for deviceToken: Data,
    of pushType: PushRouter.PushType = .apns,
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func removeAllPushChannelRegistrations(
    for deviceToken: Data,
    of pushType: PushRouter.PushType = .apns,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    route(PushRouter(.removeAllPushChannels(pushToken: deviceToken, pushType: pushType), configuration: configuration),
          responseDecoder: ModifyPushResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { _ in () })
    }
  }

  /// All channels on which APNS push notification has been enabled using specified device token and topic.
  /// - Parameters:
  ///   - for: The device token used during registration
  ///   - on: The topic of the remote notification (which is typically the bundle ID for your app)
  ///   - environment: The APS environment to register the device
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func listAPNSChannelsOnDevice(
    for deviceToken: Data,
    on topic: String,
    environment: PushRouter.Environment = .development,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String], Error>) -> Void)?
  ) {
    route(PushRouter(.manageAPNS(pushToken: deviceToken, environment: environment,
                                 topic: topic, adding: [], removing: []),
                     configuration: configuration),
          responseDecoder: RegisteredPushChannelsResponseDecoder(),
          custom: requestConfig) { result in
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func manageAPNSDevicesOnChannels(
    byRemoving removals: [String],
    thenAdding additions: [String],
    device token: Data,
    on topic: String,
    environment: PushRouter.Environment = .development,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(added: [String], removed: [String]), Error>) -> Void)?
  ) {
    let router = PushRouter(
      .manageAPNS(pushToken: token, environment: environment,
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
          responseDecoder: ModifyPushResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { (added: $0.payload.added, removed: $0.payload.removed) })
    }
  }

  /// Adds or removes APNS push notification functionality on provided set of channels for a given topic
  /// - Parameters:
  ///   - byRemoving: The list of channels to remove the device registration from
  ///   - thenAdding: The list of channels to add the device registration to
  ///   - device: The device to add/remove from the channels
  ///   - on: The topic of the remote notification (which is typically the bundle ID for your app)
  ///   - environment: The APS environment to register the device
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func addingAPNSDevicesOnChannels(
    _ additions: [String],
    device token: Data,
    on topic: String,
    environment: PushRouter.Environment = .development,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String], Error>) -> Void)?
  ) {
    manageAPNSDevicesOnChannels(
      byRemoving: [], thenAdding: additions,
      device: token, on: topic, environment: environment,
      custom: requestConfig
    ) { completion?($0.map { $0.removed }) }
  }

  /// Adds or removes APNS push notification functionality on provided set of channels for a given topic
  /// - Parameters:
  ///   - byRemoving: The list of channels to remove the device registration from
  ///   - thenAdding: The list of channels to add the device registration to
  ///   - device: The device to add/remove from the channels
  ///   - on: The topic of the remote notification (which is typically the bundle ID for your app)
  ///   - environment: The APS environment to register the device
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func removingAPNSDevicesOnChannels(
    _ removals: [String],
    device token: Data,
    on topic: String,
    environment: PushRouter.Environment = .development,
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func removeAllAPNSPushDevice(
    for deviceToken: Data,
    on topic: String,
    environment: PushRouter.Environment = .development,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    route(PushRouter(.removeAllAPNS(pushToken: deviceToken, environment: environment, topic: topic),
                     configuration: configuration),
          responseDecoder: ModifyPushResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { _ in () })
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func fetchMessageHistory(
    for channels: [String],
    fetchActions actions: Bool = false,
    limit: Int? = nil,
    start: Timetoken? = nil,
    end: Timetoken? = nil,
    metaInResponse: Bool = false,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(messagesByChannel: [String: [PubNubMessage]], next: PubNubBoundedPage?), Error>) -> Void)?
  ) {
    let router: HistoryRouter
    if actions {
      router = HistoryRouter(
        .fetchWithActions(channel: channels.first ?? "",
                          max: limit, start: start, end: end, includeMeta: metaInResponse),
        configuration: configuration
      )
    } else {
      router = HistoryRouter(
        .fetch(channels: channels, max: limit, start: start, end: end, includeMeta: metaInResponse),
        configuration: configuration
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
          next: $0.payload.asBoundedPage(end: end, limit: limit)
        )
      })
    }
  }

  /// Removes the messages from the history of a specific channel.
  /// - Parameters:
  ///   - from: The channel to delete the messages from.
  ///   - start: Time token delimiting the start of time slice (exclusive) to delete messages from.
  ///   - end: Time token delimiting the end of time slice (inclusive) to delete messages from.
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func deleteMessageHistory(
    from channel: String,
    start stateTimetoken: Timetoken? = nil,
    end endTimetoken: Timetoken? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    route(HistoryRouter(.delete(channel: channel, start: stateTimetoken, end: endTimetoken),
                        configuration: configuration),
          responseDecoder: GenericServiceResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { _ in channel })
    }
  }

  /// Returns the number of messages published for one of more channels using a channel specific time token
  /// - Parameters:
  ///   - channels: Dictionary of channel and the timetoken to get the message count for.
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func messageCounts(
    channels: [String: Timetoken],
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String: Int], Error>) -> Void)?
  ) {
    let router = HistoryRouter(
      .messageCounts(channels: channels.map { $0.key }, timetoken: nil, channelsTimetoken: channels.map { $0.value }),
      configuration: configuration
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func messageCounts(
    channels: [String],
    timetoken: Timetoken = 1,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String: Int], Error>) -> Void)?
  ) {
    let router = HistoryRouter(
      .messageCounts(channels: channels, timetoken: timetoken, channelsTimetoken: nil),
      configuration: configuration
    )

    route(router,
          responseDecoder: MessageCountsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.channels })
    }
  }
}

// MARK: - UUID Metadat Objects

extension PubNub {
  /// Returns a paginated list of user objects, optionally including each user's custom data object.
  /// - Parameters:
  ///   - include: Whether to include the custom field in the fetch response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the users from
  ///   - end: The end paging hash string to retrieve the users from
  ///   - count: A flag denoting whether to return the total count of users
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func allUUIDMetadata(
    include: IncludeFields = IncludeFields(),
    filter: String? = nil,
    sort: String? = nil,
    limit: Int? = 100,
    page: Page? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<([PubNubUUIDMetadata], PubNubHashedPage?), Error>) -> Void)?
  ) {
    let router = ObjectsUUIDRouter(
      .all(customFields: include.customFields, totalCount: include.totalCount,
           filter: filter, sort: sort, limit: limit, start: page?.start, end: page?.end),
      configuration: configuration
    )

    route(router,
          responseDecoder: PubNubUUIDsMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { (
        $0.payload.data,
        try? PubNubHashedPageBase(from: $0.payload)
      ) })
    }
  }

  /// Returns the specified user object
  /// - Parameters:
  ///   - uuid: The unique identifier of the PubNub user object to delete.
  ///   - include: Whether to include the custom field in the fetch response
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func fetch(
    uuid metadata: String?,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubUUIDMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsUUIDRouter(
      .fetch(metadataId: metadata ?? configuration.uuid, customFields: customFields),
      configuration: configuration
    )

    route(router,
          responseDecoder: PubNubUUIDMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Creates a user with the specified properties
  /// - Parameters:
  ///   - uuid: The `PubNubUser` protocol object to create
  ///   - include: Whether to include the custom field in the fetch response
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func set(
    uuid metadata: PubNubUUIDMetadata,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubUUIDMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsUUIDRouter(
      .set(metadata: metadata, customFields: customFields),
      configuration: configuration
    )

    route(router,
          responseDecoder: PubNubUUIDMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Deletes the specified user object.
  /// - Parameters:
  ///   - uuid: The unique identifier of the PubNub user object to delete.
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func remove(
    uuid metadataId: String?,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    // Capture the response or current configuration uuid
    let metadataId = metadataId ?? configuration.uuid

    let router = ObjectsUUIDRouter(
      .remove(metadataId: metadataId),
      configuration: configuration
    )

    route(router,
          responseDecoder: GenericServiceResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { _ in metadataId })
    }
  }
}

// MARK: - Channel Metadata Objects

extension PubNub {
  /// Returns a paginated list of `SpaceObject` objects, optionally including each space's custom data object.
  /// - Parameters:
  ///   - include: Whether to include the custom field in the fetch response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the spaces from
  ///   - end: The end paging hash string to retrieve the spaces from
  ///   - count: A flag denoting whether to return the total count of spaces
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func allChannelMetadata(
    include: IncludeFields = IncludeFields(),
    filter: String? = nil,
    sort: String? = nil,
    limit: Int? = nil,
    page: Page? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<([PubNubChannelMetadata], PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .all(customFields: include.customFields, totalCount: include.totalCount,
           filter: filter, sort: sort, limit: limit, start: page?.start, end: page?.end),
      configuration: configuration
    )

    route(router,
          responseDecoder: PubNubChannelsMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { (
        $0.payload.data,
        try? PubNubHashedPageBase(from: $0.payload)
      ) })
    }
  }

  /// Returns the specified space object
  /// - Parameters:
  ///   - spaceID: The unique identifier of the PubNub space object to delete.
  ///   - include: Whether to include the custom field in the fetch response
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func fetch(
    channel metadataId: String,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubChannelMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .fetch(metadataId: metadataId, customFields: customFields),
      configuration: configuration
    )

    route(router,
          responseDecoder: PubNubChannelMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Creates a space with the specified properties
  /// - Parameters:
  ///   - space: The `PubNubSpace` protocol object to create
  ///   - include: Whether to include the custom field in the fetch response
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func set(
    channel metadata: PubNubChannelMetadata,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubChannelMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .set(metadata: metadata, customFields: customFields),
      configuration: configuration
    )

    route(router,
          responseDecoder: PubNubChannelMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Deletes the specified space object.
  /// - Parameters:
  ///   - spaceID: The unique identifier of the PubNub space object to delete.
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func remove(
    channel metadataId: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .remove(metadataId: metadataId),
      configuration: configuration
    )

    route(router,
          responseDecoder: GenericServiceResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { _ in metadataId })
    }
  }
}

// MARK: - Memberships

extension PubNub {
  /// Get the specified user's space memberships.
  /// - Parameters:
  ///   - userID: The unique identifier of the PubNub user
  ///   - include: Whether to include the custom field in the fetch response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the users from
  ///   - end: The end paging hash string to retrieve the users from
  ///   - count: A flag denoting whether to return the total count of users
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func fetchMemberships(
    uuid metadataId: String,
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: String? = nil,
    limit: Int? = nil,
    page: Page? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<([PubNubMembershipMetadata], PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    let router = ObjectsMembershipsRouter(.fetchMemberships(
      uuidMetadataId: metadataId, customFields: include.customIncludes,
      totalCount: include.totalCount, filter: filter, sort: sort,
      limit: limit, start: page?.start, end: page?.end
    ),
                                          configuration: configuration)

    route(router,
          responseDecoder: PubNubMembershipsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { response in
        (
          response.payload.data.compactMap {
            PubNubMembershipMetadataBase(from: $0, other: metadataId)
          },
          try? PubNubHashedPageBase(from: response.payload)
        )
      })
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func fetchMembers(
    channel metadataId: String,
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: String? = nil,
    limit: Int? = nil,
    page: Page? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<([PubNubMembershipMetadata], PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    let router = ObjectsMembershipsRouter(.fetchMembers(
      channelMetadataId: metadataId, customFields: include.customIncludes,
      totalCount: include.totalCount, filter: filter, sort: sort,
      limit: limit, start: page?.start, end: page?.end
    ),
                                          configuration: configuration)

    route(router,
          responseDecoder: PubNubMembershipsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { response in
        (
          response.payload.data.compactMap {
            PubNubMembershipMetadataBase(from: $0, other: metadataId)
          },
          try? PubNubHashedPageBase(from: response.payload)
        )
      })
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func setMemberships(
    uuid metadataId: String,
    channels memberships: [PubNubMembershipMetadata],
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: String? = nil,
    limit: Int? = nil,
    page: Page? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<([PubNubMembershipMetadata], PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    manageMemberships(
      uuid: metadataId, setting: memberships, removing: [],
      include: include, filter: filter, sort: sort, limit: limit, page: page,
      custom: requestConfig, completion: completion
    )
  }

  /// Get the specified user's space memberships.
  /// - Parameters:
  ///   - userID: The unique identifier of the PubNub user
  ///   - include: Whether to include the custom field in the fetch response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the users from
  ///   - end: The end paging hash string to retrieve the users from
  ///   - count: A flag denoting whether to return the total count of users
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func removeMemberships(
    uuid metadataId: String,
    channels memberships: [PubNubMembershipMetadata],
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: String? = nil,
    limit: Int? = nil,
    page: Page? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<([PubNubMembershipMetadata], PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    manageMemberships(
      uuid: metadataId, setting: [], removing: memberships,
      include: include, filter: filter, sort: sort, limit: limit, page: page,
      custom: requestConfig, completion: completion
    )
  }

  /// Modifty the list of space memberships for a given user
  /// - Parameters:
  ///   - userID: The unique identifier of the PubNub user
  ///   - seting: The list of space identifiers to update for the user
  ///   - removing: The list of space identifiers to remove the user from
  ///   - include: List of custom fields (if any) to include in the response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the users from
  ///   - end: The end paging hash string to retrieve the users from
  ///   - count: A flag denoting whether to return the total count of users
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func manageMemberships(
    uuid metadataId: String,
    setting channelMembershipSets: [PubNubMembershipMetadata],
    removing channelMembershipDeletes: [PubNubMembershipMetadata],
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: String? = nil,
    limit: Int? = nil,
    page: Page? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<([PubNubMembershipMetadata], PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    let router = ObjectsMembershipsRouter(.setMemberships(
      uuidMetadataId: metadataId, customFields: include.customIncludes, totalCount: include.totalCount,
      changes: .init(
        set: channelMembershipSets.map { .init(metadataId: $0.channelMetadataId, custom: $0.custom) },
        delete: channelMembershipDeletes.map { .init(metadataId: $0.channelMetadataId, custom: $0.custom) }
      ),
      filter: filter, sort: sort, limit: limit, start: page?.start, end: page?.end
    ), configuration: configuration)

    route(router,
          responseDecoder: PubNubMembershipsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { response in
        (
          response.payload.data.compactMap {
            PubNubMembershipMetadataBase(from: $0, other: metadataId)
          },
          try? PubNubHashedPageBase(from: response.payload)
        )
      })
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func setMembers(
    channel metadataId: String,
    uuids members: [PubNubMembershipMetadata],
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: String? = nil,
    limit: Int? = nil,
    page: Page? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<([PubNubMembershipMetadata], PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    manageMembers(
      channel: metadataId, setting: members, removing: [],
      include: include, filter: filter, sort: sort, limit: limit, page: page,
      custom: requestConfig, completion: completion
    )
  }

  /// Get the specified user's space memberships.
  /// - Parameters:
  ///   - userID: The unique identifier of the PubNub user
  ///   - include: Whether to include the custom field in the fetch response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the users from
  ///   - end: The end paging hash string to retrieve the users from
  ///   - count: A flag denoting whether to return the total count of users
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func removeMembers(
    channel metadataId: String,
    uuids members: [PubNubMembershipMetadata],
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: String? = nil,
    limit: Int? = nil,
    page: Page? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<([PubNubMembershipMetadata], PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    manageMembers(
      channel: metadataId, setting: [], removing: members,
      include: include, filter: filter, sort: sort, limit: limit, page: page,
      custom: requestConfig, completion: completion
    )
  }

  /// Modifty the list of space memberships for a given user
  /// - Parameters:
  ///   - userID: The unique identifier of the PubNub user
  ///   - seting: The list of space identifiers to update for the user
  ///   - removing: The list of space identifiers to remove the user from
  ///   - include: List of custom fields (if any) to include in the response
  ///   - limit: The number of objects to retrieve at a time
  ///   - start: The start paging hash string to retrieve the users from
  ///   - end: The end paging hash string to retrieve the users from
  ///   - count: A flag denoting whether to return the total count of users
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func manageMembers(
    channel metadataId: String,
    setting uuidMembershipSets: [PubNubMembershipMetadata],
    removing uuidMembershipDeletes: [PubNubMembershipMetadata],
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: String? = nil,
    limit: Int? = nil,
    page: Page? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<([PubNubMembershipMetadata], PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    let router = ObjectsMembershipsRouter(.setMembers(
      channelMetadataId: metadataId, customFields: include.customIncludes, totalCount: include.totalCount,
      changes: .init(
        set: uuidMembershipSets.map { .init(metadataId: $0.uuidMetadataId, custom: $0.custom) },
        delete: uuidMembershipDeletes.map { .init(metadataId: $0.uuidMetadataId, custom: $0.custom) }
      ),
      filter: filter, sort: sort, limit: limit, start: page?.start, end: page?.end
    ), configuration: configuration)

    route(router,
          responseDecoder: PubNubMembershipsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { response in
        (
          response.payload.data.compactMap {
            PubNubMembershipMetadataBase(from: $0, other: metadataId)
          },
          try? PubNubHashedPageBase(from: response.payload)
        )
      })
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func fetchMessageActions(
    channel: String,
    start: Timetoken? = nil,
    end: Timetoken? = nil,
    limit: Int? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<([PubNubMessageAction], PubNubBoundedPage?), Error>) -> Void)?
  ) {
    route(MessageActionsRouter(.fetch(channel: channel, start: start, end: end, limit: limit),
                               configuration: configuration),
          responseDecoder: MessageActionsResponseDecoder(),
          custom: requestConfig) { result in
      switch result {
      case let .success(response):
        completion?(.success((
          response.payload.actions.map { PubNubMessageActionBase(from: $0, on: channel) },
          PubNubBoundedPageBase(
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func addMessageAction(
    channel: String,
    type actionType: String, value: String,
    messageTimetoken: Timetoken,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubMessageAction, Error>) -> Void)?
  ) {
    let router = MessageActionsRouter(
      .add(channel: channel, type: actionType, value: value, timetoken: messageTimetoken), configuration: configuration
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
  ///   - using: Custom Networking session specific to this method call
  ///   - respondOn: The queue the completion handler should be returned on
  ///   - completion: The async result of the method call
  public func removeMessageActions(
    channel: String,
    message timetoken: Timetoken,
    action actionTimetoken: Timetoken,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    // swiftlint:disable:next large_tuple
    completion: ((Result<(channel: String, message: Timetoken, action: Timetoken), Error>) -> Void)?
  ) {
    let router = MessageActionsRouter(
      .remove(channel: channel, message: timetoken, action: actionTimetoken),
      configuration: configuration
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

extension PubNub {
  /// Perfoms a lookup and returns a token for the specified resource type and ID
  /// - Parameters:
  ///   - for: The resource ID for which the token is to be retrieved.
  ///   - with: The resource type
  /// - Returns: The assigned PAMToken if one exists; otherwise `nil`
  ///
  /// If no token is found for the supplied resource type and ID,
  /// the TMS checks the resource stores in the following order: `User`, `Space`
  public func getToken(for identifier: String, with type: PAMResourceType? = nil) -> PAMToken? {
    return tokenStore.getToken(for: identifier, with: type)
  }

  /// Returns the token(s) for the specified resource type.
  /// - Returns: A dictionary of resource identifiers mapped to their PAM token
  public func getTokens(by type: PAMResourceType) -> PAMTokenStore {
    return tokenStore.getTokens(by: type)
  }

  /// Returns a map of all tokens stored by the token management system
  /// - Returns: A dictionary of resource types mapped to resource identifier/token pairs
  public func getAllTokens() -> [PAMResourceType: PAMTokenStore] {
    return tokenStore.getAllTokens()
  }

  /// Stores a single token in the Token Management System for use in API calls.
  /// - Parameter token: The token to add to the Token Management System.
  public mutating func set(token: String) {
    tokenStore.set(token: token)
  }

  /// Stores multiple tokens in the Token Management System for use in API calls.
  /// - Parameters:
  ///   - tokens: The list of tokens to add to the Token Management System.
  public mutating func set(tokens: [String]) {
    tokenStore.set(tokens: tokens)
  }

  // swiftlint:disable:next file_length
}
