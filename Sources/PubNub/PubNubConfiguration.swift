//
//  PubNubConfiguration.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A configuration object that defines behavior and policies for a PubNub session.
public struct PubNubConfiguration: Hashable {
  /// Creates a configuration from the Info.plist contents of the specified Bundle
  ///
  /// You can set these values in the Info.plist of the application by using:
  ///
  /// `PubNubPublishKey` for your PubNub Publish Key
  ///
  /// `PubNubSubscribeKey` for your PubNub Subscribe Key
  ///
  /// - Parameters:
  ///   - from: `Bundle` that will provide the Info Dictionary containing the PubNub Pub/Sub keys.
  ///   - publishKeyAt: The dictionary key used to search the Info Dictionary of the `Bundle` for the Publish Key Value
  ///   - subscribeKeyAt: The dictionary key used to search the Info Dictionary of the `Bundle` for the Subscribe Key Value
  ///   - uuidAt: The dictionary key used to search the Info Dictionary of the `Bundle` for the UUID value
  /// - Precondition: You must set a String value for the PubNub SubscribeKey
  public init(
    from bundle: Bundle = .main,
    publishKeyAt pubPlistKey: String = "PubNubPublishKey",
    subscribeKeyAt subPlistKey: String = "PubNubSubscribeKey",
    uuidAt uuidPlistKey: String = "PubNubUuid"
  ) {
    guard let subscribeKey = bundle.infoDictionary?[subPlistKey] as? String else {
      preconditionFailure("The Subscribe Key was not found inside the plist file.")
    }
    guard let uuid = bundle.infoDictionary?[uuidPlistKey] as? String else {
      preconditionFailure("The uuid was not found inside the plist file.")
    }

    self.init(
      publishKey: bundle.infoDictionary?[pubPlistKey] as? String,
      subscribeKey: subscribeKey,
      userId: uuid
    )
  }

  /// Creates a configuration using the specified PubNub Publish and Subscribe Keys
  ///
  /// - Attention: It is recommended that you use this initializer only if you have a
  /// custom way to pass your PubNub Publish and Subscribe keys without storing them
  /// inside your source code/code repository.
  ///
  /// - Parameters:
  ///   - publishKey: The PubNub Publish Key to be used when publishing data to a channel
  ///   - subscribeKey: The PubNub Subscribe Key to be used when getting data from a channel
  ///   - userId: The unique identifier to be used as a device identifier
  ///   - cipherKey: ~~If set, all communication will be encrypted with this key~~
  ///   - cryptoModule: If set, all communication will be encrypted with this module
  ///   - authKey: If Access Manager (PAM) is enabled, client will use  `authToken` instead of `authKey` on all requests
  ///   - authToken: If Access Manager (PAM) is enabled, client will use  `authToken` instead of `authKey` on all requests
  ///   - useSecureConnections: The PubNub Publish Key to be used when publishing data to a channel
  ///   - origin: Full origin (`subdomain`.`domain`) used for requests
  ///   - useInstanceId: Whether a PubNub object instanceId should be included on outgoing requests
  ///   - useRequestId: Whether a request identifier should be included on outgoing requests
  ///   - automaticRetry: Reconnection policy which will be used if/when a request fails
  ///   - urlSessionConfiguration: URLSessionConfiguration used for URLSession network events
  ///   - durationUntilTimeout: How long (in seconds) the server will consider the client alive for presence
  ///   - heartbeatInterval: How often (in seconds) the client will announce itself to server
  ///   - supressLeaveEvents: Whether to send out the leave requests
  ///   - requestMessageCountThreshold: The number of messages into the payload before emitting `RequestMessageCountExceeded`
  ///   - filterExpression: PSV2 feature to subscribe with a custom filter expression.
  ///   - enableEventEngine: Whether to enable a new, experimental implementation of Subscription and Presence handling
  ///   - maintainPresenceState: Whether to automatically resend the last Presence channel state,
  public init(
    publishKey: String?,
    subscribeKey: String,
    userId: String,
    cipherKey: Crypto? = nil,
    cryptoModule: CryptoModule? = nil,
    authKey: String? = nil,
    authToken: String? = nil,
    useSecureConnections: Bool = true,
    origin: String = "ps.pndsn.com",
    useInstanceId: Bool = false,
    useRequestId: Bool = false,
    automaticRetry: AutomaticRetry? = .default,
    urlSessionConfiguration: URLSessionConfiguration = .pubnub,
    durationUntilTimeout: UInt = 300,
    heartbeatInterval: UInt = 0,
    supressLeaveEvents: Bool = false,
    requestMessageCountThreshold: UInt = 100,
    filterExpression: String? = nil,
    enableEventEngine: Bool = true,
    maintainPresenceState: Bool = true
  ) {
    guard userId.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else {
      preconditionFailure("UserId should not be empty.")
    }
    if let cryptoModule {
      self.cryptoModule = cryptoModule
    } else if let cipherKey {
      self.cryptoModule = CryptoModule.legacyCryptoModule(with: cipherKey.key, withRandomIV: cipherKey.randomizeIV)
    } else {
      self.cryptoModule = nil
    }

    self.publishKey = publishKey
    self.subscribeKey = subscribeKey
    self.authKey = authKey
    self.authToken = authToken
    self.userId = userId
    self.origin = origin
    self.useInstanceId = useInstanceId
    self.useRequestId = useRequestId
    self.automaticRetry = automaticRetry
    self.useSecureConnections = useSecureConnections
    self.urlSessionConfiguration = urlSessionConfiguration
    self.durationUntilTimeout = durationUntilTimeout
    self.heartbeatInterval = heartbeatInterval
    self.supressLeaveEvents = supressLeaveEvents
    self.requestMessageCountThreshold = requestMessageCountThreshold
    self.filterExpression = filterExpression
    self.enableEventEngine = enableEventEngine
    self.maintainPresenceState = maintainPresenceState
  }

  // swiftlint:disable:next line_length
  @available(*, deprecated, renamed: "init(publishKey:subscribeKey:userId:cipherKey:authKey:authToken:useSecureConnections:origin:useInstanceId:useRequestId:automaticRetry:urlSessionConfiguration:urlSessionConfiguration:durationUntilTimeout:heartbeatInterval:supressLeaveEvents:requestMessageCountThreshold:filterExpression:)")
  /// Creates a configuration using the specified PubNub Publish and Subscribe Keys
  ///
  /// - Attention: It is recommended that you use this initializer only if you have a
  /// custom way to pass your PubNub Publish and Subscribe keys without storing them
  /// inside your source code/code repository.
  ///
  /// - Parameters:
  ///   - publishKey: The PubNub Publish Key to be used when publishing data to a channel
  ///   - subscribeKey: The PubNub Subscribe Key to be used when getting data from a channel
  public init(
    publishKey: String?,
    subscribeKey: String,
    uuid: String,
    cipherKey: Crypto? = nil,
    authKey: String? = nil,
    authToken: String? = nil,
    useSecureConnections: Bool = true,
    origin: String = "ps.pndsn.com",
    useInstanceId: Bool = false,
    useRequestId: Bool = false,
    automaticRetry: AutomaticRetry? = nil,
    urlSessionConfiguration: URLSessionConfiguration = .pubnub,
    durationUntilTimeout: UInt = 300,
    heartbeatInterval: UInt = 0,
    supressLeaveEvents: Bool = false,
    requestMessageCountThreshold: UInt = 100,
    filterExpression: String? = nil
  ) {
    guard uuid.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else {
      preconditionFailure("UUID should not be empty.")
    }

    self.init(
      publishKey: publishKey,
      subscribeKey: subscribeKey,
      userId: uuid,
      cipherKey: cipherKey,
      authKey: authKey,
      authToken: authToken,
      useSecureConnections: useSecureConnections,
      origin: origin,
      useInstanceId: useInstanceId,
      useRequestId: useRequestId,
      automaticRetry: automaticRetry,
      urlSessionConfiguration: urlSessionConfiguration,
      durationUntilTimeout: durationUntilTimeout,
      heartbeatInterval: heartbeatInterval,
      supressLeaveEvents: supressLeaveEvents,
      requestMessageCountThreshold: requestMessageCountThreshold,
      filterExpression: filterExpression
    )
  }

  /// Specifies the PubNub Publish Key to be used when publishing messages to a channel
  public var publishKey: String?
  /// Specifies the PubNub Subscribe Key to be used when subscribing to a channel
  public var subscribeKey: String
  /// If set, all communication will be encrypted with this key
  public var cryptoModule: CryptoModule?
  /// If Access Manager (PAM) is enabled, client will use `authKey` on all requests
  public var authKey: String?
  /// If Access Manager (PAM) is enabled, client will use  `authToken` instead of `authKey` on all requests
  public var authToken: String?
  /// UUID to be used as a device identifier
  public var uuid: String {
    get {
      userId
    }
    set {
      userId = newValue
    }
  }

  /// UserId to be used as a device identifier
  public var userId: String
  /// If true, requests will be made over `https`, otherwise they will use 'http'
  ///
  /// You will still need to disable ATS for the system to allow insecure network traffic.
  ///
  /// See Apple's
  /// [documentation](https://developer.apple.com/documentation/security/preventing_insecure_network_connections)
  /// for further details.
  public var useSecureConnections: Bool
  /// Full origin (`subdomain`.`domain`) used for requests
  public var origin: String
  /// Whether a PubNub object instanceId should be included on outgoing requests
  public var useInstanceId: Bool
  /// Whether a request identifier should be included on outgoing requests
  public var useRequestId: Bool
  /// This controls whether to enable a new, experimental implementation of Subscription and Presence handling.
  ///
  /// This switch can help you verify the behavior of the PubNub SDK with the new engine enabled
  /// in your app. It will default to true in a future SDK release.
  public var enableEventEngine: Bool = true
  /// When `true` the SDK will resend the last channel state that was set using ``PubNub/setPresence(state:on:and:custom:completion:)``.
  ///
  /// Applies only if `enableEventEngine` is true
  public var maintainPresenceState: Bool = false
  /// Reconnection policy which will be used if/when a request fails
  public var automaticRetry: AutomaticRetry?
  /// URLSessionConfiguration used for URLSession network events
  public var urlSessionConfiguration: URLSessionConfiguration
  /// How long (in seconds) the server will consider the client alive for presence
  ///
  /// - NOTE: The minimum value this field can be is 20
  @BoundedValue(min: 20, max: UInt.max) public var durationUntilTimeout: UInt = 300

  /// How often (in seconds) the client will announce itself to server
  ///
  /// - NOTE: The minimum value this field can be is 0
  public var heartbeatInterval: UInt
  /// Whether to send out the leave requests
  public var supressLeaveEvents: Bool
  /// The number of messages into the payload before emitting `RequestMessageCountExceeded`
  public var requestMessageCountThreshold: UInt
  /// PSV2 feature to subscribe with a custom filter expression.
  public var filterExpression: String?
  /// Ordered list of key-value pairs which identify various consumers.
  public var consumerIdentifiers: [String: String] = [:]
}
