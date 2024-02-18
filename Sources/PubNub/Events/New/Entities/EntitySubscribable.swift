//
//  EntitySubscribable.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - PubNubChannelRepresentation

/// Represents a channel that can be subscribed to and unsubscribed from using the PubNub service.
public class ChannelRepresentation: Subscribable {
  init(name: String, receiver: SubscribeReceiver) {
    super.init(name: name, subscriptionType: .channel, receiver: receiver)
  }
}

// MARK: - PubNubChannelGroupRepresentation

/// Represents a channel group that can be subscribed to and unsubscribed from using the PubNub service.
public class ChannelGroupRepresentation: Subscribable {
  init(name: String, receiver: SubscribeReceiver) {
    super.init(name: name, subscriptionType: .channelGroup, receiver: receiver)
  }
}

// MARK: - PubNubUserMetadataRepresentation

/// Represents user metadata that can be subscribed to and unsubscribed from using the PubNub service.
public class UserMetadataRepresentation: Subscribable {
  init(id: String, receiver: SubscribeReceiver) {
    super.init(name: id, subscriptionType: .channel, receiver: receiver)
  }
}

// MARK: - PubNubChannelMetadataRepresentation

/// Represents channel metadata that can be subscribed to and unsubscribed from using the PubNub service.
public class ChannelMetadataRepresentation: Subscribable {
  init(id: String, receiver: SubscribeReceiver) {
    super.init(name: id, subscriptionType: .channel, receiver: receiver)
  }
}
