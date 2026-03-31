//
//  MessageActions+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Message Actions

public extension PubNub {
  /// Fetch a list of Message Actions for a channel
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "fetchMessageActions",
          details: "Execute fetchMessageActions",
          arguments: [
            ("channel", channel),
            ("page", page),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      MessageActionsRouter(
        .fetch(channel: channel, start: page?.start, end: page?.end, limit: page?.limit),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .messageActions),
      responseDecoder: MessageActionsResponseDecoder(),
      custom: requestConfig
    ) { result in
      switch result {
      case let .success(response):
        completion?(.success((
          actions: response.payload.actions.map { PubNubMessageActionBase(from: $0, on: channel) },
          next: PubNubBoundedPageBase(start: response.payload.start, end: response.payload.end, limit: response.payload.limit)
        )))
      case let .failure(error):
        completion?(.failure(error))
      }
    }
  }

  /// Add an Action to a parent Message
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "addMessageAction",
          details: "Execute addMessageAction",
          arguments: [
            ("channel", channel),
            ("type", actionType),
            ("value", value),
            ("messageTimetoken", messageTimetoken),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    let router = MessageActionsRouter(
      .add(channel: channel, type: actionType, value: value, timetoken: messageTimetoken),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      requestOperator: configuration.automaticRetry?.retryOperator(for: .messageActions),
      responseDecoder: MessageActionResponseDecoder(),
      custom: requestConfig
    ) { result in
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
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "removeMessageActions",
          details: "Execute removeMessageActions",
          arguments: [
            ("channel", channel),
            ("message", timetoken),
            ("action", actionTimetoken),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    let router = MessageActionsRouter(
      .remove(channel: channel, message: timetoken, action: actionTimetoken),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      requestOperator: configuration.automaticRetry?.retryOperator(for: .messageActions),
      responseDecoder: DeleteResponseDecoder(),
      custom: requestConfig
    ) { result in
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
