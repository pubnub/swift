//
//  Presence+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Presence Management

public extension PubNub {
  /// Set state dictionary pairs specific to a subscriber uuid
  ///
  /// - Parameters:
  ///   - state: The UUID for which to query the subscribed channels of
  ///   - on: Additional network configuration to use on the request
  ///   - and: The queue the completion handler should be returned on
  ///   - custom: Custom configuration overrides for this request
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
    logger.debug(
      .customObject(
        .init(
          operation: "setPresence",
          details: "Execute setPresence",
          arguments: [
            ("state", state),
            ("on", channels),
            ("and", groups),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    let router = PresenceRouter(
      .setState(channels: channels, groups: groups, state: state),
      configuration: requestConfig.customConfiguration ?? configuration
    )
    let shouldMaintainPresenceState = configuration.enableEventEngine && configuration.maintainPresenceState

    route(
      router,
      requestOperator: configuration.automaticRetry?.retryOperator(for: .presence),
      responseDecoder: PresenceResponseDecoder<AnyPresencePayload<AnyJSON>>(),
      custom: requestConfig
    ) { [weak self] result in
      if case .success = result {
        if shouldMaintainPresenceState {
          self?.presenceStateContainer.registerState(AnyJSON(state), forChannels: channels)
        }
      }
      completion?(result.map { $0.payload.payload })
    }
  }

  /// Get state dictionary pairs from a specific subscriber uuid
  ///
  /// - Parameters:
  ///   - for: The UUID for which to query the subscribed channels of
  ///   - on: Additional network configuration to use on the request
  ///   - and: The queue the completion handler should be returned on
  ///   - custom: Custom configuration overrides for this request
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
    logger.debug(
      .customObject(
        .init(
          operation: "getPresenceState",
          details: "Execute getPresenceState",
          arguments: [
            ("for", uuid),
            ("on", channels),
            ("and", groups),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    let router = PresenceRouter(
      .getState(uuid: uuid, channels: channels, groups: groups),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      requestOperator: configuration.automaticRetry?.retryOperator(for: .presence),
      responseDecoder: GetPresenceStateResponseDecoder(),
      custom: requestConfig
    ) { result in
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
  ///   - on: The list of channels to return occupancy results from
  ///   - and: The list of channel groups to return occupancy results from
  ///   - includeUUIDs: `true` will include the UUIDs of those present on the channel
  ///   - includeState: `true` will return the presence channel state information if available
  ///   - limit: The number of occupants to fetch per channel. The maximum value is 1000.
  ///   - offset: The offset to return occupancy results from.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Dictionary` of channels mapped to their respective `PubNubPresence`
  ///     - **Failure**: An `Error` describing the failure
  func hereNow(
    on channels: [String],
    and groups: [String] = [],
    includeUUIDs: Bool = true,
    includeState: Bool = false,
    limit: Int = 1000,
    offset: Int? = 0,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<[String: PubNubPresence], Error>) -> Void)?
  ) {
    logger.debug(
      .customObject(
        .init(
          operation: "hereNow",
          details: "Execute hereNow",
          arguments: [
            ("on", channels),
            ("and", groups),
            ("includeUUIDs", includeUUIDs),
            ("includeState", includeState),
            ("limit", limit),
            ("offset", offset),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    let router: PresenceRouter
    let currentOffset = offset ?? 0
    let finalLimit = limit > 1000 ? 1000 : limit

    if channels.isEmpty, groups.isEmpty {
      router = PresenceRouter(
        .hereNowGlobal(
          includeUUIDs: includeUUIDs,
          includeState: includeState
        ),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    } else {
      router = PresenceRouter(
        .hereNow(
          channels: channels,
          groups: groups,
          includeUUIDs: includeUUIDs,
          includeState: includeState,
          limit: finalLimit,
          offset: currentOffset
        ),
        configuration: requestConfig.customConfiguration ?? configuration
      )
    }

    let decoder = HereNowResponseDecoder(channels: channels, groups: groups)

    route(
      router,
      requestOperator: configuration.automaticRetry?.retryOperator(for: .presence),
      responseDecoder: decoder,
      custom: requestConfig
    ) { result in
        completion?(result.map { $0.payload.asPubNubPresenceBase })
    }
  }

  /// Obtain information about the current list of channels a UUID is subscribed to
  ///
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
    logger.debug(
      .customObject(
        .init(
          operation: "whereNow",
          details: "Execute whereNow",
          arguments: [
            ("for", uuid),
            ("custom", requestConfig)
          ]
        )
      ), category: .pubNub
    )

    route(
      PresenceRouter(.whereNow(uuid: uuid), configuration: requestConfig.customConfiguration ?? configuration),
      requestOperator: configuration.automaticRetry?.retryOperator(for: .presence),
      responseDecoder: PresenceResponseDecoder<AnyPresencePayload<WhereNowPayload>>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { [uuid: $0.payload.payload.channels] })
    }
  }
}
