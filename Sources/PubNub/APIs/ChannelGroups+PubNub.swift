//
//  ChannelGroups+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Channel Group Management

public extension PubNub {
  /// Lists all the channel groups
  ///
  /// - Parameters:
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: List of all channel-groups
  ///     - **Failure**: An `Error` describing the failure
  func listChannelGroups(
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String], Error>) -> Void)?
  ) {
    logger.debug(
      .customObject(
        .init(
          operation: "listChannelGroups",
          details: "Execute listChannelGroups",
          arguments: [("custom", requestConfig)]
        )
      ), category: .pubNub
    )

    route(
      ChannelGroupsRouter(.channelGroups, configuration: requestConfig.customConfiguration ?? configuration),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .channelGroups),
      responseDecoder: ChannelGroupResponseDecoder<GroupListPayloadResponse>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.payload.groups })
    }
  }

  /// Removes the channel group.
  ///
  /// - Parameters:
  ///   - channelGroup: The channel group to remove.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The channel-group that was removed
  ///     - **Failure**: An `Error` describing the failure
  func remove(
    channelGroup: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    logger.debug(
      .customObject(
        .init(
          operation: "removeChannelGroup",
          details: "Execute remove",
          arguments: [
            ("channelGroup", channelGroup),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      ChannelGroupsRouter(
        .deleteGroup(group: channelGroup),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .channelGroups),
      responseDecoder: GenericServiceResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in channelGroup })
    }
  }

  /// Lists all the channels of the channel group.
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "listChannels",
          details: "Execute listChannels",
          arguments: [
            ("for", group),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      ChannelGroupsRouter(
        .channelsForGroup(group: group),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .channelGroups),
      responseDecoder: ChannelGroupResponseDecoder<ChannelListPayloadResponse>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { ($0.payload.payload.group, $0.payload.payload.channels) })
    }
  }

  /// Adds a channel to a channel group.
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "addChannelsToGroup",
          details: "Execute add",
          arguments: [
            ("channels", channels),
            ("to", group),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      ChannelGroupsRouter(
        .addChannelsToGroup(group: group, channels: channels),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .channelGroups),
      responseDecoder: GenericServiceResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in (group, channels) })
    }
  }

  /// Removes the channels from the channel group.
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "removeChannelsFromGroup",
          details: "Execute remove",
          arguments: [
            ("channels", channels),
            ("from", group),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      ChannelGroupsRouter(
        .removeChannelsForGroup(group: group, channels: channels),
        configuration: requestConfig.customConfiguration ?? configuration
      ),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .channelGroups),
      responseDecoder: GenericServiceResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in (group, channels) })
    }
  }
}
