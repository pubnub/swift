//
//  KMPPubNub+Subscribe.swift
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

// MARK: - Subscribed channels & channel groups

@objc
public extension KMPPubNub {
  var subscribedChannels: [String] {
    pubnub.subscribedChannels
  }

  var subscribedChannelGroups: [String] {
    pubnub.subscribedChannelGroups
  }
}

// MARK: - Subscribe & Unsubscribe

@objc
public extension KMPPubNub {
  func subscribe(
    channels: [String],
    channelGroups: [String],
    withPresence: Bool,
    timetoken: Timetoken
  ) {
    pubnub.subscribe(
      to: channels,
      and: channelGroups,
      at: timetoken,
      withPresence: withPresence
    )
  }

  func unsubscribe(
    from channels: [String],
    channelGroups: [String]
  ) {
    pubnub.unsubscribe(
      from: channels,
      and: channelGroups
    )
  }

  func unsubscribeAll() {
    pubnub.unsubscribeAll()
  }
}
