//
//  PubNubPresenceChangeObjC.swift
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

@objc
public class PubNubPresenceChangeObjC: NSObject {
  @objc public let event: String?
  @objc public let uuid: String?
  @objc public let occupancy: NSNumber?
  @objc public let state: AnyJSONObjC?
  @objc public let channel: String?
  @objc public let subscription: String?
  @objc public let timetoken: NSNumber?
  @objc public let join: [String]?
  @objc public let leave: [String]?
  @objc public let timeout: [String]?
  @objc public let refreshHereNow: NSNumber?
  @objc public let userMetadata: AnyJSONObjC?

  static func from(change: PubNubPresenceChange) -> [PubNubPresenceChangeObjC] {
    change.actions.map { PubNubPresenceChangeObjC(change: change, action: $0) }
  }

  private init(change: PubNubPresenceChange, action: PubNubPresenceChangeAction) {
    occupancy = NSNumber(value: change.occupancy)
    channel = change.channel
    subscription = change.subscription
    timetoken = NSNumber(value: change.timetoken)
    refreshHereNow = NSNumber(value: change.refreshHereNow)
    userMetadata = if let value = change.metadata?.rawValue { AnyJSONObjC(value) } else { nil }

    switch action {
    case .join(let uuids):
      event = "join"
      join = uuids
      uuid = nil
      state = nil
      leave = nil
      timeout = nil
    case .leave(let uuids):
      event = "leave"
      leave = uuids
      uuid = nil
      state = nil
      join = nil
      timeout = nil
    case let .stateChange(affectedUUID, newState):
      event = "state-change"
      state = AnyJSONObjC(newState.codableValue)
      uuid = affectedUUID
      join = nil
      leave = nil
      timeout = nil
    case .timeout(let uuids):
      event = "interval"
      timeout = uuids
      uuid = nil
      state = nil
      join = nil
      leave = nil
    }
  }
}
