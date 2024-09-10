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

/// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
///
/// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
/// While these symbols are public, they are intended strictly for internal usage.
///
/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

@objc
public class KMPHereNowResult: NSObject {
  @objc public let totalChannels: Int
  @objc public let totalOccupancy: Int
  @objc public let channels: [String: KMPHereNowChannelData]

  init(totalChannels: Int, totalOccupancy: Int, channels: [String: KMPHereNowChannelData]) {
    self.totalChannels = totalChannels
    self.totalOccupancy = totalOccupancy
    self.channels = channels
  }
}

@objc
public class KMPHereNowChannelData: NSObject {
  @objc public let channelName: String
  @objc public let occupancy: Int
  @objc public let occupants: [KMPHereNowOccupantData]

  init(channelName: String, occupancy: Int, occupants: [KMPHereNowOccupantData]) {
    self.channelName = channelName
    self.occupancy = occupancy
    self.occupants = occupants
  }
}

@objc public class KMPHereNowOccupantData: NSObject {
  @objc public let uuid: String
  @objc public let state: KMPAnyJSON?

  init(uuid: String, state: KMPAnyJSON?) {
    self.uuid = uuid
    self.state = state
  }
}
