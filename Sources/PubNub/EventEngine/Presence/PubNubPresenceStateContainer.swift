//
//  PresenceStateContainer.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class PubNubPresenceStateContainer {
  static let shared: PubNubPresenceStateContainer = PubNubPresenceStateContainer()

  private var channelStates: Atomic<[String: JSONCodable]> = Atomic([:])
  private init() {}

  func registerState(_ state: JSONCodable, forChannels channels: [String]) {
    channelStates.lockedWrite { channelStates in
      channels.forEach {
        channelStates[$0] = state
      }
    }
  }

  func removeState(forChannels channels: [String]) {
    channelStates.lockedWrite { channelStates in
      channels.map {
        channelStates[$0] = nil
      }
    }
  }

  func getStates(forChannels channels: [String]) -> [String: JSONCodable] {
    channelStates.lockedRead {
      $0.filter {
        channels.contains($0.key)
      }
    }
  }

  func removeAll() {
    channelStates.lockedWrite {
      $0.removeAll()
    }
  }
}
