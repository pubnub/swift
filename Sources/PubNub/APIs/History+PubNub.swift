//
//  History+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

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
  ///   - includeCustomMessageType: If `true` the user-provided custom message type will be included with each message
  ///   - page: The paging object used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing a `Dictionary` mapping channels to `PubNubMessage` arrays, and an optional next `PubNubBoundedPage`.
  ///     - **Failure**: An `Error` describing the failure
  func fetchMessageHistory(
    for channels: [String],
    includeActions: Bool = false,
    includeMeta: Bool = false,
    includeUUID: Bool = true,
    includeMessageType: Bool = true,
    includeCustomMessageType: Bool = false,
    page: PubNubBoundedPage? = PubNubBoundedPageBase(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(messagesByChannel: [String: [PubNubMessage]], next: PubNubBoundedPage?), Error>) -> Void)?
  ) {
    logger.debug(
      .customObject(
        .init(
          operation: "fetchMessageHistory",
          details: "Execute fetchMessageHistory",
          arguments: [
            ("for", channels),
            ("includeActions", includeActions),
            ("includeMeta", includeMeta),
            ("includeUUID", includeUUID),
            ("includeMessageType", includeMessageType),
            ("includeCustomMessageType", includeCustomMessageType),
            ("page", page),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    let router: HistoryRouter

    switch (channels.count > 1, includeActions) {
    case (_, true):
      router = HistoryRouter(
        .fetchWithActions(
          channel: channels.first ?? "",
          max: page?.limit ?? 25, start: page?.start, end: page?.end,
          includeMeta: includeMeta, includeMessageType: includeMessageType, includeCustomMessageType: includeCustomMessageType,
          includeUUID: includeUUID
        ),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    case (false, _):
      router = HistoryRouter(
        .fetch(
          channels: channels, max: page?.limit ?? 100,
          start: page?.start, end: page?.end,
          includeMeta: includeMeta, includeMessageType: includeMessageType, includeCustomMessageType: includeCustomMessageType,
          includeUUID: includeUUID
        ),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    case (true, _):
      router = HistoryRouter(
        .fetch(
          channels: channels, max: page?.limit ?? 25,
          start: page?.start, end: page?.end,
          includeMeta: includeMeta, includeMessageType: includeMessageType, includeCustomMessageType: includeCustomMessageType,
          includeUUID: includeUUID
        ),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    }

    route(
      router,
      requestOperator: configuration.automaticRetry?.retryOperator(for: .messageStorage),
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
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "deleteMessageHistory",
          details: "Execute deleteMessageHistory",
          arguments: [
            ("from", channel),
            ("start", start),
            ("end", end),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      HistoryRouter(
        .delete(channel: channel, start: start, end: end),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .messageStorage),
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
    logger.debug(
      .customObject(
        .init(
          operation: "messageCounts",
          details: "Execute messageCounts",
          arguments: [
            ("channels", channels),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    let router = HistoryRouter(
      .messageCounts(channels: channels.map { $0.key }, timetoken: nil, channelsTimetoken: channels.map { $0.value }),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      requestOperator: configuration.automaticRetry?.retryOperator(for: .messageStorage),
      responseDecoder: MessageCountsResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.channels })
    }
  }

  /// Returns the number of messages published for each channels for a single time
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "messageCounts",
          details: "Execute messageCounts",
          arguments: [
            ("channels", channels),
            ("timetoken", timetoken),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    let router = HistoryRouter(
      .messageCounts(channels: channels, timetoken: timetoken, channelsTimetoken: nil),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      requestOperator: configuration.automaticRetry?.retryOperator(for: .messageStorage),
      responseDecoder: MessageCountsResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.channels })
    }
  }
}
