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
  @objc public var totalChannels: Int
  @objc public var totalOccupancy: Int
  @objc public var channels: [String: PubNubHereNowChannelDataObjC]

  init(totalChannels: Int, totalOccupancy: Int, channels: [String: PubNubHereNowChannelDataObjC]) {
    self.totalChannels = totalChannels
    self.totalOccupancy = totalOccupancy
    self.channels = channels
  }
}

@objc
public class PubNubHereNowChannelDataObjC: NSObject {
  @objc public var channelName: String
  @objc public var occupancy: Int
  @objc public var occupants: [PubNubHereNowOccupantDataObjC]

  init(channelName: String, occupancy: Int, occupants: [PubNubHereNowOccupantDataObjC]) {
    self.channelName = channelName
    self.occupancy = occupancy
    self.occupants = occupants
  }
}

@objc public class PubNubHereNowOccupantDataObjC: NSObject {
  @objc public var uuid: String
  @objc public var state: Any?

  init(uuid: String, state: Any?) {
    self.uuid = uuid
    self.state = state
  }
}
