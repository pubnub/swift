//
//  PubNubPresenceEventResultObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubPresenceEventResultObjC: NSObject {
  @objc public var event: String?
  @objc public var uuid: String?
  @objc public var occupancy: NSNumber?
  @objc public var state: Any?
  @objc public var channel: String?
  @objc public var subscription: String?
  @objc public var timetoken: NSNumber?
  @objc public var join: [String]?
  @objc public var leave: [String]?
  @objc public var timeout: [String]?
  @objc public var refreshHereNow: NSNumber?
  @objc public var userMetadata: Any?

  static func from(change: PubNubPresenceChange) -> [PubNubPresenceEventResultObjC] {
    change.actions.map { PubNubPresenceEventResultObjC(change: change, action: $0) }
  }

  private init(change: PubNubPresenceChange, action: PubNubPresenceChangeAction) {
    occupancy = NSNumber(value: change.occupancy)
    channel = change.channel
    subscription = change.subscription
    timetoken = NSNumber(value: change.timetoken)
    refreshHereNow = NSNumber(booleanLiteral: change.refreshHereNow)
    userMetadata = change.metadata?.rawValue

    switch action {
    case .join(let uuids):
      event = "join"
      join = uuids
    case .leave(let uuids):
      event = "leave"
      leave = uuids
    case .stateChange(let affectedUUID, let newState):
      event = "state-change"
      state = newState.rawValue
      uuid = affectedUUID
    case .timeout(let uuids):
      event = "interval"
      timeout = uuids
    }
  }
}
