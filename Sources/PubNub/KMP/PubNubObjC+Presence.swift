//
//  PubNubObjC+MessageActions.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
///
/// All public symbols in this file that are annotated with @objc are intended to allow interoperation
/// with Kotlin Multiplatform for other PubNub frameworks.
///
/// While these symbols are public, they are intended strictly for internal usage.

/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

// MARK: - Presence

@objc
public extension PubNubObjC {
  func hereNow(
    channels: [String],
    channelGroups: [String],
    includeState: Bool,
    includeUUIDs: Bool,
    onSuccess: @escaping ((PubNubHereNowResultObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.hereNow(
      on: channels,
      and: channelGroups,
      includeUUIDs: includeUUIDs,
      includeState: includeState
    ) {
      switch $0 {
      case let .success(map):
        onSuccess(
          PubNubHereNowResultObjC(
            totalChannels: map.count,
            totalOccupancy: map.values.reduce(0, { accResult, channel in accResult + channel.occupancy }),
            channels: map.mapValues { value in
              PubNubHereNowChannelDataObjC(
                channelName: value.channel,
                occupancy: value.occupancy,
                occupants: value.occupants.map {
                  let stateValue: AnyJSONObjC? = if let state = value.occupantsState[$0]?.rawValue {
                    AnyJSONObjC(state)
                  } else {
                    nil
                  }
                  return PubNubHereNowOccupantDataObjC(
                    uuid: $0,
                    state: stateValue
                  )
                }
              )
            }
          )
        )
      case let .failure(error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func whereNow(
    uuid: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping (Error) -> Void
  ) {
    pubnub.whereNow(for: uuid) {
      switch $0 {
      case .success(let map):
        onSuccess(map[uuid] ?? [])
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func getPresenceState(
    channels: [String],
    channelGroups: [String],
    uuid: String,
    onSuccess: @escaping (([String: Any]) -> Void),
    onFailure: @escaping (Error) -> Void
  ) {
    pubnub.getPresenceState(
      for: uuid,
      on: channels,
      and: channelGroups
    ) {
      switch $0 {
      case .success(let response):
        onSuccess(response.stateByChannel.mapValues { $0.rawValue })
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  // TODO: It's not possible to set Presence state other than [String: JSONCodableScalar] in Swift SDK

  func setPresenceState(
    channels: [String],
    channelGroups: [String],
    state: AnyJSONObjC,
    onSuccess: @escaping ((AnyJSONObjC) -> Void),
    onFailure: @escaping (Error) -> Void
  ) {
    pubnub.setPresence(
      state: [:],
      on: channels,
      and: channelGroups
    ) {
      switch $0 {
      case .success(let codable):
        onSuccess(AnyJSONObjC(codable.rawValue))
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }
}
