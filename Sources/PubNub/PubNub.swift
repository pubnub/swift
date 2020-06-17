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

  /// Creates a PubNub session with the specified configuration
  ///
  /// - Parameters:
  ///   - configuration: The default configurations that will be used
  ///   - session: Session used for performing request/response REST calls
  ///   - subscribeSession: The network session used for Subscription only
  ///   - presenceSession: The network session used by Subscription for `leave` and `heartbeat` requests
  public init(
    configuration: PubNubConfiguration,
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

extension Array where Element == PubNub.ObjectSortField {
  var urlValue: [String] {
    return map { "\($0.property.rawValue)\($0.ascending ? "" : ":desc")" }
  }
}

extension Array where Element == PubNub.MembershipSortField {
  var memberURLValue: [String] {
    return map { "\($0.property.memberRawValue)\($0.ascending ? "" : ":desc")" }
  }

  var membershipURLValue: [String] {
    return map { "\($0.property.membershipRawValue)\($0.ascending ? "" : ":desc")" }
  }
}

// MARK: - Request Helpers

extension PubNub {
  /// The APNs Environment that notifications will be sent through
  ///
  /// This should match the value mapped to the `aps-environment` key in your Info.plist
  ///
  /// See [APS Environment Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/aps-environment)
  /// for more information.
  public enum PushEnvironment: String, Codable {
    /// The APNs development environment.
    case development
    /// The APNs production environment.
    case production
  }

  /// The identifier of the Push Service being used
  public enum PushService: String, Codable {
    /// Applee Push Notification Service
    case apns
    /// Firebase Cloude Messaging
    case gcm
    /// Microsoft Push Notification Service
    case mpns
  }

  /// Configuration overrides for a single request
  public struct RequestConfiguration {
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
  public struct Page: PubNubHashedPage {
    public var start: String?
    public var end: String?
    public let totalCount: Int? = nil

    /// Default init
    /// - Parameters:
    ///   - start: The value of the  start of a next page
    ///   - end: The value of the end of a slice of paged data
    public init(start: String? = nil, end: String? = nil) {
      self.start = start
      self.end = end
    }

    public init(from other: PubNubHashedPage) throws {
      self.init(start: other.start, end: other.end)
    }
  }

  /// Fields that include additional data inside the response
  public struct IncludeFields {
    /// The `custom` dictionary for the Object
    public var customFields: Bool
    /// The `totalCount` of how many Objects are available
    public var totalCount: Bool

    /// Default init
    ///  - Parameters:
    ///   - custom: Whether to include `custom` data in the response
    ///   - totalCount: Whether to include `totalCount` in the response
    public init(custom: Bool = true, totalCount: Bool = true) {
      customFields = custom
      self.totalCount = totalCount
    }
  }

  /// The sort properties for UUID and Channel metadata objects
  public enum ObjectSortProperty: String {
    /// Sort on the unique identifier property
    case id
    /// Sort on the name property
    case name
    /// Sort on the last updated property
    case updated
  }

  /// The property and direction to sort a multi-object-metadata response
  public struct ObjectSortField {
    /// The property to sort by
    public let property: ObjectSortProperty
    /// The direction of the sort
    public let ascending: Bool

    public init(property: ObjectSortProperty, ascending: Bool = true) {
      self.property = property
      self.ascending = ascending
    }
  }

  /// The sort properties for Membership metadata objects
  public enum MembershipSortProperty {
    /// Sort based on the nested object (UUID or Channel) belonging to the Membership
    case object(ObjectSortProperty)
    /// Sort on the last updated property of the Membership
    case updated

    func rawValue(_ objectType: String) -> String {
      switch self {
      case let .object(property):
        return "\(objectType).\(property)"
      case .updated:
        return "updated"
      }
    }

    var membershipRawValue: String {
      return rawValue("channel")
    }

    var memberRawValue: String {
      return rawValue("uuid")
    }
  }

  /// The property and direction to sort a multi-membership-metadata response
  public struct MembershipSortField {
    /// The property to sort by
    public let property: MembershipSortProperty
    /// The direction of the sort
    public let ascending: Bool

    public init(property: MembershipSortProperty, ascending: Bool = true) {
      self.property = property
      self.ascending = ascending
    }
  }

  /// Fields that include additional data inside a Membership metadata response
  public struct MembershipInclude {
    /// The `custom` dictionary for the Object
    public var customFields: Bool
    /// The `PubNubChannelMetadata` instance of the Membership
    public var channelFields: Bool
    /// The `custom` dictionary of the `PubNubChannelMetadata` for the Membership object
    public var channelCustomFields: Bool
    /// The `totalCount` of how many Objects are available
    public var totalCount: Bool

    /// Default init
    /// - Parameters:
    ///   - customFields: The `custom` dictionary for the Object
    ///   - channelFields: The `PubNubChannelMetadata` instance of the Membership
    ///   - channelCustomFields: The `custom` dictionary of the `PubNubChannelMetadata` for the Membership object
    ///   - totalCount The `totalCount` of how many Objects are available
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
    /// The `custom` dictionary for the Object
    public var customFields: Bool
    /// The `PubNubUUIDMetadata` instance of the Membership
    public var uuidFields: Bool
    /// The `custom` dictionary of the `PubNubUUIDMetadata` for the Membership object
    public var uuidCustomFields: Bool
    /// The `totalCount` of how many Objects are available
    public var totalCount: Bool

    /// Default init
    /// - Parameters:
    ///   - customFields: The `custom` dictionary for the Object
    ///   - uuidFields: The `PubNubUUIDMetadata` instance of the Membership
    ///   - uuidCustomFields: The `custom` dictionary of the `PubNubUUIDMetadata` for the Membership object
    ///   - totalCount The `totalCount` of how many Objects are available
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The current `Timetoken`
  ///     - **Failure**: An `Error` describing the failure
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `Timetoken` of the published Message
  ///     - **Failure**: An `Error` describing the failure
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `Timetoken` of the published Message
  ///     - **Failure**: An `Error` describing the failure
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `Timetoken` of the published Message
  ///     - **Failure**: An `Error` describing the failure
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
  ///   - region: The region code from a previous `SubscribeCursor`
  ///   - filterOverride: Overrides the previous filter on the next successful request
  public func subscribe(
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
  public func reconnect(at timetoken: Timetoken? = nil) {
    subscription.reconnect(at: SubscribeCursor(timetoken: timetoken))
  }

  /// The `Timetoken` used for the last successful subscription request
  public var previousTimetoken: Timetoken? {
    return subscription.previousTokenResponse?.timetoken
  }

  /// Add a listener to enable the receiving of subscription events
  /// - Parameter listener: The subscription listener to be added
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

  /// An override for the default filter expression set during initialization
  var subscribeFilterExpression: String? {
    get { return subscription.filterExpression }
    set {
      subscription.filterExpression = newValue
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
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The presence State set as a `JSONCodable`
  ///     - **Failure**: An `Error` describing the failure
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
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the UUID that set the State and a `Dictionary` of channels mapped to their respective State
  ///     - **Failure**: An `Error` describing the failure
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
  ///   - includeUUIDs: `true` will include the UUIDs of those present on the channel
  ///   - includeState: `true` will return the presence channel state information if available
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Dictionary` of channels mapped to their respective `PubNubPresence`
  ///     - **Failure**: An `Error` describing the failure
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**:  A `Dictionary` of UUIDs mapped to their respective `Array` of channels they have presence on
  ///     - **Failure**: An `Error` describing the failure
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: List of all channel-groups
  ///     - **Failure**: An `Error` describing the failure
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The channel-group that was removed
  ///     - **Failure**: An `Error` describing the failure
  ///   - result: A `Result` containing  either the removed channel-group  **or** an `Error`
  public func remove(
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the channel-group and the `Array` of  its channels
  ///     - **Failure**: An `Error` describing the failure
  public func listChannels(
    for group: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(group: String, channels: [String]), Error>) -> Void)?
  ) {
    route(ChannelGroupsRouter(.channelsForGroup(group: group), configuration: configuration),
          responseDecoder: ChannelGroupResponseDecoder<ChannelListPayloadResponse>(),
          custom: requestConfig) { result in
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
  public func add(
    channels: [String],
    to group: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(group: String, channels: [String]), Error>) -> Void)?
  ) {
    route(ChannelGroupsRouter(.addChannelsToGroup(group: group, channels: channels), configuration: configuration),
          responseDecoder: GenericServiceResponseDecoder(),
          custom: requestConfig) { result in
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
  public func remove(
    channels: [String],
    from group: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(group: String, channels: [String]), Error>) -> Void)?
  ) {
    route(ChannelGroupsRouter(.removeChannelsForGroup(group: group, channels: channels), configuration: configuration),
          responseDecoder: GenericServiceResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { _ in (group, channels) })
    }
  }
}

// MARK: - Push

extension PubNub {
  /// All channels on which push notification has been enabled using specified pushToken.
  /// - Parameters:
  ///   - for: The Channel Group to remove the list of channels from
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An `Array` of all channels registered to the device token
  ///     - **Failure**: An `Error` describing the failure
  public func listPushChannelRegistrations(
    for deviceToken: Data,
    of pushType: PushService = .apns,
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of channels added and an `Array` of channels removed for notifications on a specific device token
  ///     - **Failure**: An `Error` describing the failure
  public func managePushChannelRegistrations(
    byRemoving removals: [String],
    thenAdding additions: [String],
    for deviceToken: Data,
    of pushType: PushService = .apns,
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
  ///   - additions: The list of channels to add the device registration to
  ///   - for: A device token to identify the device for registration changes
  ///   - of: The type of Remote Notification service used to send the notifications
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An `Array` of channels added for notifications on a specific device token
  ///     - **Failure**: An `Error` describing the failure
  public func addPushChannelRegistrations(
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
  public func removePushChannelRegistrations(
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
  public func removeAllPushChannelRegistrations(
    for deviceToken: Data,
    of pushType: PushService = .apns,
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An `Array` of all channels registered to the device token
  ///     - **Failure**: An `Error` describing the failure
  public func listAPNSPushChannelRegistrations(
    for deviceToken: Data,
    on topic: String,
    environment: PushEnvironment = .development,
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of channels added and an `Array` of channels removed for notifications on a specific device token
  ///     - **Failure**: An `Error` describing the failure
  public func manageAPNSDevicesOnChannels(
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
  public func addAPNSDevicesOnChannels(
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
    ) { completion?($0.map { $0.removed }) }
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
  public func removeAPNSDevicesOnChannels(
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
  public func removeAllAPNSPushDevice(
    for deviceToken: Data,
    on topic: String,
    environment: PushEnvironment = .development,
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
  ///   - includeActions: If `true` any Message Actions will be included in the response
  ///   - includeMeta: If `true` the meta properties of messages will be included in the response
  ///   - page: The paging object used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` of a `Dictionary` of channels mapped to an `Array` their respective `PubNubMessages`, and the next request `PubNubBoundedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  public func fetchMessageHistory(
    for channels: [String],
    includeActions actions: Bool = false,
    includeMeta: Bool = false,
    page: PubNubBoundedPage? = PubNubBoundedPageBase(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(messagesByChannel: [String: [PubNubMessage]], next: PubNubBoundedPage?), Error>) -> Void)?
  ) {
    let router: HistoryRouter
    if actions {
      router = HistoryRouter(
        .fetchWithActions(channel: channels.first ?? "",
                          max: page?.limit, start: page?.start, end: page?.end, includeMeta: includeMeta),
        configuration: configuration
      )
    } else {
      router = HistoryRouter(
        .fetch(channels: channels, max: page?.limit, start: page?.start, end: page?.end, includeMeta: includeMeta),
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
  public func deleteMessageHistory(
    from channel: String,
    start: Timetoken? = nil,
    end: Timetoken? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    route(
      HistoryRouter(.delete(channel: channel, start: start, end: end), configuration: configuration),
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Dictionary` of channels mapped to their respective message count
  ///     - **Failure**: An `Error` describing the failure
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
  /// Gets metadata for all UUIDs
  ///
  /// Returns a paginated list of UUID Metadata objects, optionally including the custom data object for each.
  /// - Parameters:
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubUUIDMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  public func allUUIDMetadata(
    include: IncludeFields = IncludeFields(),
    filter: String? = nil,
    sort: [ObjectSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(uuids: [PubNubUUIDMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    let router = ObjectsUUIDRouter(
      .all(customFields: include.customFields, totalCount: include.totalCount,
           filter: filter, sort: sort.urlValue,
           limit: limit, start: page?.start, end: page?.end),
      configuration: configuration
    )

    route(router,
          responseDecoder: PubNubUUIDsMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { (
        uuids: $0.payload.data,
        next: try? PubNubHashedPageBase(from: $0.payload)
      ) })
    }
  }

  /// Get Metadata for a UUID
  ///
  /// Returns metadata for the specified UUID, optionally including the custom data object for each.
  /// - Parameters:
  ///   - uuid: Unique UUID Metadata identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubUUIDMetadata` object belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  public func fetch(
    uuid metadata: String?,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubUUIDMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsUUIDRouter(
      .fetch(metadataId: metadata ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid),
             customFields: customFields),
      configuration: configuration
    )

    route(router,
          responseDecoder: PubNubUUIDMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Set UUID Metadata
  ///
  ///  Set metadata for a UUID in the database, optionally including the custom data object for each.
  /// - Parameters:
  ///   - uuid: The `PubNubUUIDMetadata` to set
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubUUIDMetadata` containing the set changes
  ///     - **Failure**: An `Error` describing the failure
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

  /// Remove UUID Metadata
  ///
  /// Remove metadata for a specified UUID.
  /// - Parameters:
  ///   - uuid: Unique UUID Metadata identifier to remove. If not supplied, then it will use the request configuration and then the default configuration
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The UUID identifier of the removed object
  ///     - **Failure**: An `Error` describing the failure
  public func remove(
    uuid metadataId: String?,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    // Capture the response or current configuration uuid
    let metadataId = metadataId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

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
  /// Get Metadata for All Channels
  ///
  ///  Returns a paginated list of metadata objects for channels, optionally including custom data objects.
  /// - Parameters:
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubChannelMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  public func allChannelMetadata(
    include: IncludeFields = IncludeFields(),
    filter: String? = nil,
    sort: [ObjectSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(channels: [PubNubChannelMetadata], next: PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .all(customFields: include.customFields, totalCount: include.totalCount,
           filter: filter, sort: sort.map { "\($0.property.rawValue)\($0.ascending ? "" : ":desc")" },
           limit: limit, start: page?.start, end: page?.end),
      configuration: configuration
    )

    route(router,
          responseDecoder: PubNubChannelsMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { (
        channels: $0.payload.data,
        next: try? PubNubHashedPageBase(from: $0.payload)
      ) })
    }
  }

  /// Get Metadata for a Channel
  ///
  /// Returns metadata for the specified channel including the channel's custom data.
  /// - Parameters:
  ///   - channel: Unique Channel Metadata identifier
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubChannelMetadata` object belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
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

  /// Set Channel Metadata
  ///
  /// Set metadata for a channel in the database.
  /// - Parameters:
  ///   - channel: The `PubNubChannelMetadata` to set
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubChannelMetadata` containing the set changes
  ///     - **Failure**: An `Error` describing the failure
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

  /// Remove Channel Metadata
  ///
  /// Remove metadata for a specified channel
  /// - Parameters:
  ///   - channel: Unique Channel Metadata identifier to remove.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The Channel identifier of the removed object
  ///     - **Failure**: An `Error` describing the failure
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
  /// Get Channel Memberships
  ///
  /// The method returns a list of channel memberships for a user. It does not return a user's subscriptions.
  /// - Parameters:
  ///   - uuid: Unique UUID identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  public func fetchMemberships(
    uuid: String?,
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    let metadataId = uuid ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

    let router = ObjectsMembershipsRouter(
      .fetchMemberships(
        uuidMetadataId: metadataId,
        customFields: include.customIncludes,
        totalCount: include.totalCount, filter: filter,
        sort: sort.membershipURLValue,
        limit: limit, start: page?.start, end: page?.end
      ),
      configuration: configuration
    )

    route(router,
          responseDecoder: PubNubMembershipsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { response in
        (
          memberships: response.payload.data.compactMap {
            PubNubMembershipMetadataBase(from: $0, other: metadataId)
          },
          next: try? PubNubHashedPageBase(from: response.payload)
        )
      })
    }
  }

  /// Get Channel Members
  ///
  /// The method returns a list of members in a channel. The list will include user metadata for members that have additional metadata stored in the database.
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  public func fetchMembers(
    channel metadataId: String,
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    let router = ObjectsMembershipsRouter(.fetchMembers(
      channelMetadataId: metadataId, customFields: include.customIncludes,
      totalCount: include.totalCount, filter: filter,
      sort: sort.memberURLValue,
      limit: limit, start: page?.start, end: page?.end
    ),
                                          configuration: configuration)

    route(router,
          responseDecoder: PubNubMembershipsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { response in
        (
          memberships: response.payload.data.compactMap {
            PubNubMembershipMetadataBase(from: $0, other: metadataId)
          },
          next: try? PubNubHashedPageBase(from: response.payload)
        )
      })
    }
  }

  /// Set Channel memberships for a UUID.
  /// - Parameters:
  ///   - uuid: Unique UUID identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - channels: Array of `PubNubMembershipMetadata` with the `PubNubChannelMetadata` or `channelMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  public func setMemberships(
    uuid metadataId: String?,
    channels memberships: [PubNubMembershipMetadata],
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    manageMemberships(
      uuid: metadataId, setting: memberships, removing: [],
      include: include, filter: filter, sort: sort, limit: limit, page: page,
      custom: requestConfig, completion: completion
    )
  }

  /// Remove Channel memberships for a UUID.
  /// - Parameters:
  ///   - uuid: Unique UUID identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - channels: Array of `PubNubMembershipMetadata` with the `PubNubChannelMetadata` or `channelMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  public func removeMemberships(
    uuid metadataId: String?,
    channels memberships: [PubNubMembershipMetadata],
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = nil,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    manageMemberships(
      uuid: metadataId, setting: [], removing: memberships,
      include: include, filter: filter, sort: sort, limit: limit, page: page,
      custom: requestConfig, completion: completion
    )
  }

  /// Modify the Channel membership list for a UUID
  /// - Parameters:
  ///   - uuid: Unique UUID identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - setting: Array of `PubNubMembershipMetadata` with the `PubNubChannelMetadata` or `channelMetadataId` provided
  ///   - removing: Array of `PubNubMembershipMetadata` with the `PubNubChannelMetadata` or `channelMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  public func manageMemberships(
    uuid: String?,
    setting channelMembershipSets: [PubNubMembershipMetadata],
    removing channelMembershipDeletes: [PubNubMembershipMetadata],
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    let metadataId = uuid ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

    let router = ObjectsMembershipsRouter(.setMemberships(
      uuidMetadataId: metadataId, customFields: include.customIncludes, totalCount: include.totalCount,
      changes: .init(
        set: channelMembershipSets.map { .init(metadataId: $0.channelMetadataId, custom: $0.custom) },
        delete: channelMembershipDeletes.map { .init(metadataId: $0.channelMetadataId, custom: $0.custom) }
      ),
      filter: filter, sort: sort.membershipURLValue,
      limit: limit, start: page?.start, end: page?.end
    ), configuration: configuration)

    route(router,
          responseDecoder: PubNubMembershipsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { response in
        (
          memberships: response.payload.data.compactMap {
            PubNubMembershipMetadataBase(from: $0, other: metadataId)
          },
          next: try? PubNubHashedPageBase(from: response.payload)
        )
      })
    }
  }

  /// Get the specified user's space memberships.
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - uuids: Array of `PubNubMembershipMetadata` with the `PubNubUUIDMetadata` or `uuidMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  public func setMembers(
    channel metadataId: String,
    uuids members: [PubNubMembershipMetadata],
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    manageMembers(
      channel: metadataId, setting: members, removing: [],
      include: include, filter: filter, sort: sort, limit: limit, page: page,
      custom: requestConfig, completion: completion
    )
  }

  /// Remove UUID members from a Channel.
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - uuids: Array of `PubNubMembershipMetadata` with the `PubNubUUIDMetadata` or `uuidMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  public func removeMembers(
    channel metadataId: String,
    uuids members: [PubNubMembershipMetadata],
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    manageMembers(
      channel: metadataId, setting: [], removing: members,
      include: include, filter: filter, sort: sort,
      limit: limit, page: page, custom: requestConfig, completion: completion
    )
  }

  /// Modify the UUID member list for a Channel
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - setting: Array of `PubNubMembershipMetadata` with the `PubNubUUIDMetadata` or `uuidMetadataId` provided
  ///   - removing: Array of `PubNubMembershipMetadata` with the `PubNubUUIDMetadata` or `uuidMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  public func manageMembers(
    channel metadataId: String,
    setting uuidMembershipSets: [PubNubMembershipMetadata],
    removing uuidMembershipDeletes: [PubNubMembershipMetadata],
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPageBase?), Error>) -> Void)?
  ) {
    let router = ObjectsMembershipsRouter(.setMembers(
      channelMetadataId: metadataId, customFields: include.customIncludes, totalCount: include.totalCount,
      changes: .init(
        set: uuidMembershipSets.map { .init(metadataId: $0.uuidMetadataId, custom: $0.custom) },
        delete: uuidMembershipDeletes.map { .init(metadataId: $0.uuidMetadataId, custom: $0.custom) }
      ),
      filter: filter, sort: sort.memberURLValue,
      limit: limit, start: page?.start, end: page?.end
    ), configuration: configuration)

    route(router,
          responseDecoder: PubNubMembershipsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { response in
        (
          memberships: response.payload.data.compactMap {
            PubNubMembershipMetadataBase(from: $0, other: metadataId)
          },
          next: try? PubNubHashedPageBase(from: response.payload)
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
  ///   - page: The paging object used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An `Array` of `PubNubMessageAction` for the request channel, and the next request `PubNubBoundedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  public func fetchMessageActions(
    channel: String,
    page: PubNubBoundedPage? = PubNubBoundedPageBase(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(actions: [PubNubMessageAction], next: PubNubBoundedPage?), Error>) -> Void)?
  ) {
    route(
      MessageActionsRouter(
        .fetch(channel: channel, start: page?.start, end: page?.end, limit: page?.limit), configuration: configuration
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
  public func addMessageAction(
    channel: String,
    type actionType: String,
    value: String,
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
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing the channel, message `Timetoken`, and action `Timetoken` of the action that was removed
  ///     - **Failure**: An `Error` describing the failure
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
