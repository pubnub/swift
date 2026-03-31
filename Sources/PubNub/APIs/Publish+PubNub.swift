//
//  Publish+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

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
  ///   - channel: The destination of the message.
  ///   - message: The message to publish.
  ///   - customMessageType: Custom message type.
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
    customMessageType: String? = nil,
    shouldStore: Bool? = nil,
    storeTTL: Int? = nil,
    meta: JSONCodable? = nil,
    shouldCompress: Bool = false,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Timetoken, Error>) -> Void)?
  ) {
    logger.debug(
      .customObject(
        .init(
          operation: "publish",
          details: "Execute publish",
          arguments: [
            ("channel", channel),
            ("message", message.jsonStringify),
            ("customMessageType", customMessageType),
            ("storeTTL", storeTTL),
            ("meta", meta?.jsonStringify),
            ("shouldCompress", shouldCompress),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    let router: PublishRouter

    if shouldCompress {
      router = PublishRouter(
        .compressedPublish(
          message: message.codableValue,
          channel: channel,
          customMessageType: customMessageType,
          shouldStore: shouldStore,
          ttl: storeTTL,
          meta: meta?.codableValue
        ),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    } else {
      router = PublishRouter(
        .publish(
          message: message.codableValue,
          channel: channel,
          customMessageType: customMessageType,
          shouldStore: shouldStore,
          ttl: storeTTL,
          meta: meta?.codableValue
        ),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    }

    route(
      router,
      requestOperator: configuration.automaticRetry?.retryOperator(for: .messageSend),
      responseDecoder: PublishResponseDecoder(),
      custom: requestConfig
    ) { result in
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
    logger.debug(
      .customObject(
        .init(
          operation: "fire",
          details: "Execute fire",
          arguments: [
            ("channel", channel),
            ("message", message.jsonStringify),
            ("meta", meta?.jsonStringify),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      PublishRouter(
        .fire(message: message.codableValue, channel: channel, meta: meta?.codableValue),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .messageSend),
      responseDecoder: PublishResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.timetoken })
    }
  }

  /// Publish a message to PubNub Functions Event Handlers
  ///
  /// - Parameters:
  ///   - channel: The destination of the message
  ///   - message: The message to publish
  ///   - customMessageType: Custom signal type.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `Timetoken` of the published Message
  ///     - **Failure**: An `Error` describing the failure
  func signal(
    channel: String,
    message: JSONCodable,
    customMessageType: String? = nil,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Timetoken, Error>) -> Void)?
  ) {
    logger.debug(
      .customObject(
        .init(
          operation: "signal",
          details: "Execute signal",
          arguments: [
            ("channel", channel),
            ("message", message.jsonStringify),
            ("customMessageType", customMessageType),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      PublishRouter(
        .signal(message: message.codableValue, channel: channel, customMessageType: customMessageType),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .messageSend),
      responseDecoder: PublishResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.timetoken })
    }
  }
}
