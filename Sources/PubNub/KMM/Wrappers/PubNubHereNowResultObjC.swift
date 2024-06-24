//
//  PubNubHereNowResultObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubHereNowResultObjC: NSObject {
  @objc public let totalChannels: Int
  @objc public let totalOccupancy: Int
  @objc public let channels: [String: PubNubHereNowChannelDataObjC]

  init(totalChannels: Int, totalOccupancy: Int, channels: [String: PubNubHereNowChannelDataObjC]) {
    self.totalChannels = totalChannels
    self.totalOccupancy = totalOccupancy
    self.channels = channels
  }
}

@objc
public class PubNubHereNowChannelDataObjC: NSObject {
  @objc public let channelName: String
  @objc public let occupancy: Int
  @objc public let occupants: [PubNubHereNowOccupantDataObjC]

  init(channelName: String, occupancy: Int, occupants: [PubNubHereNowOccupantDataObjC]) {
    self.channelName = channelName
    self.occupancy = occupancy
    self.occupants = occupants
  }
}

@objc public class PubNubHereNowOccupantDataObjC: NSObject {
  @objc public let uuid: String
  @objc public let state: AnyJSONObjC?

  init(uuid: String, state: AnyJSONObjC?) {
    self.uuid = uuid
    self.state = state
  }
}
