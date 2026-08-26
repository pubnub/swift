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

/// A reference to a channel by name.
public class Channel: Subscribable {
  /// The name identifying this channel
  public let name: String

  init(name: String, pubnub: PubNub) {
    self.name = name
    super.init(pubnub: pubnub)
  }

  override func subscriptionTopology(includingPresence: Bool) -> SubscriptionTopology {
    SubscriptionTopology(channels: includingPresence ? [name, name.presenceChannelName] : [name])
  }
}

// MARK: - ChannelGroup

/// A reference to a channel group by name.
public class ChannelGroup: Subscribable {
  /// The name identifying this channel group
  public let name: String

  init(name: String, pubnub: PubNub) {
    self.name = name
    super.init(pubnub: pubnub)
  }

  override func subscriptionTopology(includingPresence: Bool) -> SubscriptionTopology {
    SubscriptionTopology(channelGroups: includingPresence ? [name, name.presenceChannelName] : [name])
  }
}

// MARK: - UserMetadata

/// A reference to an App Context user metadata record by identifier.
public class UserMetadata: Subscribable {
  /// The identifier of the user metadata record
  public let id: String

  init(id: String, pubnub: PubNub) {
    self.id = id
    super.init(pubnub: pubnub)
  }

  override func subscriptionTopology(includingPresence: Bool) -> SubscriptionTopology {
    SubscriptionTopology(channels: [id])
  }
}

// MARK: - ChannelMetadata

/// A reference to an App Context channel metadata record by identifier.
public class ChannelMetadata: Subscribable {
  /// The identifier of the channel metadata record
  public let id: String

  init(id: String, pubnub: PubNub) {
    self.id = id
    super.init(pubnub: pubnub)
  }

  override func subscriptionTopology(includingPresence: Bool) -> SubscriptionTopology {
    SubscriptionTopology(channels: [id])
  }
}
