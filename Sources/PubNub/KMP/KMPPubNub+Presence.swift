//
//  KMPPubNub+MessageActions.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
//
// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
// While these symbols are public, they are intended strictly for internal usage.
//
// External developers should refrain from directly using these symbols in their code, as their implementation details
// may change in future versions of the framework, potentially leading to breaking changes.

import Foundation

@objc
public extension KMPPubNub {
  func hereNow(
    channels: [String],
    channelGroups: [String],
    includeState: Bool,
    includeUUIDs: Bool,
    limit: Int,
    offset: NSNumber?,
    onSuccess: @escaping ((KMPHereNowResult) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.hereNow(
      on: channels,
      and: channelGroups,
      includeUUIDs: includeUUIDs,
      includeState: includeState
    ) {
      switch $0 {
      case let .success(response):
        onSuccess(
          KMPHereNowResult(
            totalChannels: response.presenceByChannel.count,
            totalOccupancy: response.presenceByChannel.values.reduce(0, { accResult, channel in accResult + channel.occupancy }),
            channels: response.presenceByChannel.mapValues { value in
              KMPHereNowChannelData(
                channelName: value.channel,
                occupancy: value.occupancy,
                occupants: value.occupants.map {
                  let stateValue: KMPAnyJSON? = if let state = value.occupantsState[$0]?.rawValue {
                    KMPAnyJSON(state)
                  } else {
                    nil
                  }
                  return KMPHereNowOccupantData(
                    uuid: $0,
                    state: stateValue
                  )
                }
              )
            },
            nextOffset: response.nextOffset?.asNumber
          )
        )
      case let .failure(error):
        onFailure(KMPError(underlying: error))
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
        onFailure(KMPError(underlying: error))
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
        onFailure(KMPError(underlying: error))
      }
    }
  }

  // swiftlint:disable todo
  // TODO: It's not possible to set Presence state other than [String: JSONCodableScalar] in Swift SDK

  func setPresenceState(
    channels: [String],
    channelGroups: [String],
    state: KMPAnyJSON,
    onSuccess: @escaping ((KMPAnyJSON) -> Void),
    onFailure: @escaping (Error) -> Void
  ) {
    pubnub.setPresence(
      state: [:],
      on: channels,
      and: channelGroups
    ) {
      switch $0 {
      case .success(let codable):
        onSuccess(KMPAnyJSON(codable.rawValue))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  // swiftlint:enable todo
}
