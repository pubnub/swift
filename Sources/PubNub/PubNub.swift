//
//  PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import os

/// An object that coordinates a group of related PubNub pub/sub network events
public class PubNub {
  /// Instance identifier
  public let instanceID: UUID
  /// A copy of the configuration object used for this session
  public private(set) var configuration: PubNubConfiguration
  /// Session used for performing request/response REST calls
  public let networkSession: SessionReplaceable
  /// The URLSession used when making File upload/download requests
  public var fileURLSession: URLSessionReplaceable
  /// The URLSessionDelegate used by the `fileSession` to handle file responses
  public var fileSessionManager: FileSessionManager? { fileURLSession.delegate as? FileSessionManager }

  /// The logger to be used for the current PubNub SDK instance
  let logger: PubNubLogger
  /// Session used for performing subscription calls
  let subscription: SubscriptionSession
  // Container that holds current Presence states for given channels/channel groups
  let presenceStateContainer: PubNubPresenceStateContainer

  /// Creates a PubNub session with the specified configuration
  ///
  /// - Parameters:
  ///   - configuration: The default configurations that will be used
  ///   - session: Session used for performing request/response REST calls
  ///   - subscribeSession: The network session used for Subscription only
  ///   - fileSession: The network session used for File uploading/downloading only
  ///   - logger: The logger to be used for the PubNub SDK
  public convenience init(
    configuration: PubNubConfiguration,
    session: SessionReplaceable? = nil,
    subscribeSession: SessionReplaceable? = nil,
    fileSession: URLSessionReplaceable? = nil,
    logger: PubNubLogger = PubNubLogger.defaultLogger()
  ) {
    let container = DependencyContainer(instanceID: UUID(), configuration: configuration)
    let loggerWithInstanceId = logger.clone(withPubNubInstanceId: container.instanceID)

    container.register(value: loggerWithInstanceId, forKey: PubNubLoggerDependencyKey.self)
    container.register(value: session, forKey: DefaultHTTPSessionDependencyKey.self)
    container.register(value: subscribeSession, forKey: HTTPSubscribeSessionDependencyKey.self)
    container.register(value: fileSession, forKey: FileURLSessionDependencyKey.self)

    self.init(container: container)
  }

  init(container: DependencyContainer) {
    self.instanceID = container.instanceID
    self.logger = container.logger
    self.configuration = container.configuration
    self.subscription = container.subscriptionSession
    self.networkSession = container.defaultHTTPSession
    self.fileURLSession = container.fileURLSession
    self.presenceStateContainer = container.presenceStateContainer

    logger.debug(
      .customObject(LogMessageContent.CustomObject(
        operation: "init",
        details: "Initialize a new PubNub instance",
        arguments: [
          ("instanceID", self.instanceID.uuidString),
          ("configuration.publishKey", self.configuration.publishKey),
          ("configuration.subscribeKey", self.configuration.subscribeKey),
          ("configuration.userId", self.configuration.userId),
          ("configuration.cryptoModule", self.configuration.cryptoModule),
          ("configuration.authKey", self.configuration.authKey),
          ("configuration.authToken", self.configuration.authToken),
          ("configuration.useSecureConnections", self.configuration.useSecureConnections),
          ("configuration.origin", self.configuration.origin),
          ("configuration.useInstanceId", self.configuration.useInstanceId),
          ("configuration.useRequestId", self.configuration.useRequestId),
          ("configuration.automaticRetry.policy", self.configuration.automaticRetry?.policy),
          ("configuration.automaticRetry.retryLimit", self.configuration.automaticRetry?.retryLimit),
          ("configuration.automaticRetry.excluded", self.configuration.automaticRetry?.excluded),
          ("configuration.automaticRetry.validations", self.configuration.automaticRetry?.validationWarnings),
          ("configuration.durationUntilTimeout", self.configuration.durationUntilTimeout),
          ("configuration.heartbeatInterval", self.configuration.heartbeatInterval),
          ("configuration.supressLeaveEvents", self.configuration.supressLeaveEvents),
          ("configuration.requestMessageCountThreshold", self.configuration.requestMessageCountThreshold),
          ("configuration.filterExpression", self.configuration.filterExpression),
          ("configuration.enableEventEngine", self.configuration.enableEventEngine),
          ("configuration.maintainPresenceState", self.configuration.maintainPresenceState)
        ]
      )), category: .pubNub
    )
  }

  func route<Decoder>(
    _ router: HTTPRouter,
    requestOperator: RequestOperator? = nil,
    responseDecoder: Decoder,
    custom requestConfig: RequestConfiguration,
    completion: @escaping (Result<EndpointResponse<Decoder.Payload>, Error>) -> Void
  ) where Decoder: ResponseDecoder {
    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        requestOperator: requestOperator,
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
  enum PushService: Codable, Hashable {
    @available(*, deprecated, renamed: "fcm")
    case gcm
    /// Apple Push Notification Service
    case apns
    /// Firebase Cloud Messaging
    case fcm

    func stringValue() -> String {
      switch self {
      case .gcm:
        return "gcm"
      case .fcm:
        return "fcm"
      case .apns:
        return "apns"
      }
    }
  }

  /// Configuration overrides for a single request
  struct RequestConfiguration {
    /// The custom Network session that that will be used to make the request
    public var customSession: SessionReplaceable?
    /// The endpoint configuration used by the request
    public var customConfiguration: RouterConfiguration?
    /// The queue that will be used for dispatching a response
    public var responseQueue: DispatchQueue

    /// Default init for all fields
    ///
    /// - Parameters:
    ///   - customSession: The custom Network session that that will be used to make the request
    ///   - customConfiguration: The endpoint configuration used by the request
    ///   - responseQueue: The queue that will be used for dispatching a response
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
    ///
    /// - Parameters:
    ///   - start: The value of the  start of a next page
    ///   - end: The value of the end of a slice of paged data
    ///   - totalCount: Number of items to fetch
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

// MARK: - Subscription

public extension PubNub {
  /// Subscribe to channels and/or channel groups
  ///
  /// - Parameters:
  ///   - to: List of channels to subscribe on
  ///   - and: List of channel groups to subscribe on
  ///   - at: The initial timetoken to subscribe with
  ///   - withPresence: If true it also subscribes to presence events on the specified channels.
  func subscribe(
    to channels: [String],
    and channelGroups: [String] = [],
    at timetoken: Timetoken? = nil,
    withPresence: Bool = false
  ) {
    logger.debug(
      .customObject(
        .init(
          operation: "subscribe",
          details: "Execute subscribe",
          arguments: [
            ("to", channels),
            ("and", channelGroups),
            ("at", timetoken),
            ("withPresence", withPresence)
          ]
        )
      ), category: .pubNub
    )

    let finalChanelList = if withPresence {
      channels + channels.map { $0.presenceChannelName }
    } else {
      channels
    }

    let finalChannelGroupList = if withPresence {
      channelGroups + channelGroups.map { $0.presenceChannelName }
    } else {
      channelGroups
    }

    let channelSubscriptions = Set(finalChanelList).compactMap {
      channel($0).subscription(queue: queue)
    }
    let channelGroupSubscriptions = Set(finalChannelGroupList).compactMap {
      channelGroup($0).subscription(queue: queue)
    }

    subscription.subscribe(
      to: channelSubscriptions,
      and: channelGroupSubscriptions,
      at: SubscribeCursor(timetoken: timetoken)
    )
  }

  /// Unsubscribe from channels and/or channel groups
  ///
  /// - Parameters:
  ///   - from: List of channels to unsubscribe from
  ///   - and: List of channel groups to unsubscribe from
  func unsubscribe(from channels: [String], and channelGroups: [String] = []) {
    logger.debug(
      .customObject(
        .init(
          operation: "unsubscribe",
          details: "Execute unsubscribe",
          arguments: [
            ("from", channels),
            ("and", channelGroups)
          ]
        )
      ), category: .pubNub
    )
    subscription.unsubscribe(
      from: channels,
      and: channelGroups
    )
  }

  /// Unsubscribe from all channels and channel groups
  func unsubscribeAll() {
    logger.debug(
      .customObject(
        .init(
          operation: "unsubscribeAll",
          details: "Execute unsubscribeAll"
        )
      ), category: .pubNub
    )
    subscription.unsubscribeAll()
  }

  /// Stops the subscriptions in progress
  func disconnect() {
    logger.debug(
      .customObject(
        .init(
          operation: "disconnect",
          details: "Execute disconnect"
        )
      ), category: .pubNub
    )
    subscription.disconnect()
  }

  /// Reconnets to a stopped subscription with the previous subscribed channels and channel groups
  /// - Parameter at: The timetoken value used to reconnect or nil to use the previous stored value
  func reconnect(at timetoken: Timetoken? = nil) {
    logger.debug(
      .customObject(
        .init(
          operation: "reconnect",
          details: "Execute reconnect",
          arguments: [("at", timetoken)]
        )
      ), category: .pubNub
    )

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
  var subscribeFilterExpression: String? {
    get {
      return subscription.filterExpression
    }
    set {
      subscription.filterExpression = newValue
      configuration.filterExpression = newValue
    }
  }
}

extension PubNub {
  func registerAdapter(_ adapter: BaseSubscriptionListenerAdapter) {
    subscription.registerAdapter(adapter)
  }

  func hasRegisteredAdapter(with uuid: UUID) -> Bool {
    subscription.hasRegisteredAdapter(with: uuid)
  }

  func internalSubscribe(
    with channels: [Subscription],
    and groups: [Subscription],
    at timetoken: Timetoken?
  ) {
    logger.debug(
      .customObject(
        .init(
          operation: "internalSubscribe",
          details: "Triggering subscribe operation from Subscription objects",
          arguments: [
            ("channels", channels.flatMap { $0.subscriptionNames }),
            ("channelGroups", groups.flatMap { $0.subscriptionNames }),
            ("timetoken", timetoken)
          ]
        )
      ), category: .pubNub
    )

    subscription.internalSubscribe(
      with: channels,
      and: groups,
      at: timetoken
    )
  }

  func internalUnsubscribe(
    from channels: [Subscription],
    and groups: [Subscription]
  ) {
    subscription.internalUnsubscribe(
      from: channels,
      and: groups
    )
  }
}

// MARK: - EntityCreator

extension PubNub: EntityCreator {
  public func channel(_ name: String) -> ChannelRepresentation {
    ChannelRepresentation(name: name, pubnub: self)
  }

  public func channelGroup(_ name: String) -> ChannelGroupRepresentation {
    ChannelGroupRepresentation(name: name, pubnub: self)
  }

  public func userMetadata(_ name: String) -> UserMetadataRepresentation {
    UserMetadataRepresentation(id: name, pubnub: self)
  }

  public func channelMetadata(_ name: String) -> ChannelMetadataRepresentation {
    ChannelMetadataRepresentation(id: name, pubnub: self)
  }
}

// MARK: - PAM Token

public extension PubNub {
  /// Stores token for use in API calls.
  ///
  /// - Parameter token: The token to add to the Token Management System.
  func set(token: String) {
    logger.debug(
      .customObject(
        .init(
          operation: "set",
          details: "Set auth token",
          arguments: [("token", token)]
        )
      ), category: .pubNub
    )

    configuration.authToken = token
    subscription.configuration.authToken = token
  }
}

// MARK: - Consumer

public extension PubNub {
  /// Set consumer identifying value for components usage.
  ///
  /// - Parameters:
  ///   - identifier: Identifier of consumer with which value will be associated.
  ///   - value: Value which should be associated with consumer identifier.
  func setConsumer(identifier: String, value: String) {
    configuration.consumerIdentifiers[identifier] = value
  }
}

// MARK: - Global EventEmitter

/// An extension to the PubNub class, making it conform to the `EventListenerInterface` protocol and serving
/// as a global emitter for all entities.
///
/// This extension enables `PubNub` instances to act as event emitters, allowing them to dispatch
/// various types of events for all registered entities in the Subscribe loop.
extension PubNub: EventListenerInterface {
  public var queue: DispatchQueue {
    subscription.queue
  }

  public var uuid: UUID {
    subscription.uuid
  }

  public var onEvent: ((PubNubEvent) -> Void)? {
    get { subscription.onEvent }
    set { subscription.onEvent = newValue }
  }

  public var onEvents: (([PubNubEvent]) -> Void)? {
    get { subscription.onEvents }
    set { subscription.onEvents = newValue }
  }

  public var onMessage: ((PubNubMessage) -> Void)? {
    get { subscription.onMessage }
    set { subscription.onMessage = newValue }
  }

  public var onSignal: ((PubNubMessage) -> Void)? {
    get { subscription.onSignal }
    set { subscription.onSignal = newValue }
  }

  public var onPresence: ((PubNubPresenceChange) -> Void)? {
    get { subscription.onPresence }
    set { subscription.onPresence = newValue }
  }

  public var onMessageAction: ((PubNubMessageActionEvent) -> Void)? {
    get { subscription.onMessageAction }
    set { subscription.onMessageAction = newValue }
  }

  public var onFileEvent: ((PubNubFileChangeEvent) -> Void)? {
    get { subscription.onFileEvent }
    set { subscription.onFileEvent = newValue }
  }

  public var onAppContext: ((PubNubAppContextEvent) -> Void)? {
    get { subscription.onAppContext }
    set { subscription.onAppContext = newValue }
  }
}

/// An extension to the `PubNub` class, making it conform to the `StatusListenerInterface` protocol and serving
/// as a global listener for connection changes and possible errors along the way.
extension PubNub: StatusListenerInterface {
  public var onConnectionStateChange: ((ConnectionStatus) -> Void)? {
    get { subscription.onConnectionStateChange }
    set { subscription.onConnectionStateChange = newValue }
  }

  /// Adds additional status listeners
  public func addStatusListener(_ listener: StatusListener) {
    subscription.addStatusListener(listener)
  }

  /// Removes status listener
  public func removeStatusListener(_ listener: StatusListener) {
    subscription.removeStatusListener(listener)
  }

  /// Removes all status listeners
  public func removeAllStatusListeners() {
    subscription.removeAllStatusListeners()
  }
}

extension PubNub: EventListenerHandler {
  public func addEventListener(_ listener: EventListener) {
    subscription.addEventListener(listener)
  }

  public func removeEventListener(_ listener: EventListener) {
    subscription.removeEventListener(listener)
  }

  public func removeAllListeners() {
    subscription.removeAllListeners()
  }
}

public extension PubNub {
  /// The current log level, determining the severity of messages to be logged
  var logLevel: LogLevel {
    get {
      logger.levels
    }
    set {
      logger.levels = newValue
    }
  }

  // swiftlint:disable:next file_length
}
