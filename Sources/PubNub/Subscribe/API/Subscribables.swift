//
//  Subscribables.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Channel

/// A channel you can subscribe to and unsubscribe from.
public class Channel: Subscribable {
  init(name: String, pubnub: PubNub) {
    super.init(name: name, subscribeTarget: .channel, pubnub: pubnub)
  }
}

// MARK: - ChannelGroup

/// A channel group you can subscribe to and unsubscribe from.
public class ChannelGroup: Subscribable {
  init(name: String, pubnub: PubNub) {
    super.init(name: name, subscribeTarget: .channelGroup, pubnub: pubnub)
  }
}

// MARK: - UserMetadata

/// A user metadata record whose App Context changes you can subscribe to.
public class UserMetadata: Subscribable {
  init(id: String, pubnub: PubNub) {
    super.init(name: id, subscribeTarget: .channel, pubnub: pubnub)
  }
}

// MARK: - ChannelMetadata

/// A channel metadata record whose App Context changes you can subscribe to.
public class ChannelMetadata: Subscribable {
  init(id: String, pubnub: PubNub) {
    super.init(name: id, subscribeTarget: .channel, pubnub: pubnub)
  }
}
