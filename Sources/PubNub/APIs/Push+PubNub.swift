//
//  Push+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Push

public extension PubNub {
  /// All channels on which push notification has been enabled using specified pushToken.
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "listPushChannelRegistrations",
          details: "Execute listPushChannelRegistrations",
          arguments: [
            ("for", deviceToken.hexEncodedString),
            ("of", pushType),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      PushRouter(
        .listPushChannels(pushToken: deviceToken, pushType: pushType),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .devicePushNotifications),
      responseDecoder: RegisteredPushChannelsResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.channels })
    }
  }

  /// Adds or removes push notification functionality on provided set of channels.
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "managePushChannelRegistrations",
          details: "Execute managePushChannelRegistrations",
          arguments: [
            ("byRemoving", removals),
            ("thenAdding", additions),
            ("for", deviceToken.hexEncodedString),
            ("of", pushType),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    let router = PushRouter(
      .managePushChannels(pushToken: deviceToken, pushType: pushType, joining: additions, leaving: removals),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      requestOperator: configuration.automaticRetry?.retryOperator(for: .devicePushNotifications),
      responseDecoder: ModifyPushResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { (added: $0.payload.added, removed: $0.payload.removed) })
    }
  }

  /// Adds or removes push notification functionality on provided set of channels.
  ///
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
  ///
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
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "removeAllPushChannelRegistrations",
          details: "Execute removeAllPushChannelRegistrations",
          arguments: [
            ("for", deviceToken.hexEncodedString),
            ("of", pushType),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      PushRouter(
        .removeAllPushChannels(pushToken: deviceToken, pushType: pushType),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .devicePushNotifications),
      responseDecoder: ModifyPushResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in () })
    }
  }

  /// All channels on which APNS push notification has been enabled using specified device token and topic.
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "listAPNSPushChannelRegistrations",
          details: "Execute listAPNSPushChannelRegistrations",
          arguments: [
            ("for", deviceToken.hexEncodedString),
            ("on", topic),
            ("environment", environment),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      PushRouter(
        .manageAPNS(pushToken: deviceToken, environment: environment, topic: topic, adding: [], removing: []),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .devicePushNotifications),
      responseDecoder: RegisteredPushChannelsResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.channels })
    }
  }

  /// Adds or removes APNS push notification functionality on provided set of channels for a given topic
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "manageAPNSDevicesOnChannels",
          details: "Execute manageAPNSDevicesOnChannels",
          arguments: [
            ("byRemoving", removals),
            ("thenAdding", additions),
            ("device", token.hexEncodedString),
            ("on", topic),
            ("environment", environment),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    let router = PushRouter(
      .manageAPNS(
        pushToken: token, environment: environment, topic: topic,
        adding: additions, removing: removals
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    if removals.isEmpty, additions.isEmpty {
      completion?(
        .failure(PubNubError(
          .missingRequiredParameter,
          router: router,
          additional: [ErrorDescription.missingChannelsAnyGroups]
        ))
      )
    } else {
      route(
        router,
        requestOperator: configuration.automaticRetry?.retryOperator(for: .devicePushNotifications),
        responseDecoder: ModifyPushResponseDecoder(),
        custom: requestConfig
      ) { result in
        completion?(result.map { (added: $0.payload.added, removed: $0.payload.removed) })
      }
    }
  }

  /// Enable APNS2 push notifications on provided set of channels.
  ///
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
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "removeAllAPNSPushDevice",
          details: "Execute removeAllAPNSPushDevice",
          arguments: [
            ("for", deviceToken.hexEncodedString),
            ("on", topic),
            ("environment", environment),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      PushRouter(
        .removeAllAPNS(pushToken: deviceToken, environment: environment, topic: topic),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .devicePushNotifications),
      responseDecoder: ModifyPushResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in () })
    }
  }

  // swiftlint:disable:next file_length
}
