//
//  SubscribeTarget.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - SubscribeTarget

/// A base class for entities that can be subscribed to and unsubscribed from using the PubNub service.
public class SubscribeTarget: SubscriptionProvider {
  /// An entity name
  public let name: String
  /// The PubNub client associated with this channel.
  internal weak var pubnub: PubNub?
  /// An underlying subscription type
  internal let targetType: SubscribeTargetType
  /// A helper property returning underlying channel and/or channel groups.
  internal var subscriptionTopology: [SubscribeTargetType: [String]] { [targetType: [name]] }

  init(name: String, targetType: SubscribeTargetType, pubnub: PubNub) {
    self.name = name
    self.targetType = targetType
    self.pubnub = pubnub
  }

  /// Creates a `Subscription` object with default options for the conforming entity.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled
  ///   - options: Additional options for configuring the subscription
  public func subscription(
    queue: DispatchQueue = .main,
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) -> any SubscriptionInterface {
    Subscription(
      queue: queue,
      entity: self,
      options: options
    )
  }
}

// MARK: - SubscribeTargetType

/// An enumeration representing the type of subscription target.
public enum SubscribeTargetType {
  /// A channel subscription target
  case channel
  /// A channel group subscription target
  case channelGroup
}

// MARK: - PubNubChannelRepresentation

/// Represents a channel that can be subscribed to and unsubscribed from using the PubNub service.
public class ChannelRepresentation: SubscribeTarget {
  init(name: String, pubnub: PubNub) {
    super.init(name: name, targetType: .channel, pubnub: pubnub)
  }
}

// MARK: - PubNubChannelGroupRepresentation

/// Represents a channel group that can be subscribed to and unsubscribed from using the PubNub service.
public class ChannelGroupRepresentation: SubscribeTarget {
  init(name: String, pubnub: PubNub) {
    super.init(name: name, targetType: .channelGroup, pubnub: pubnub)
  }
}

// MARK: - PubNubUserMetadataRepresentation

/// Represents user metadata that can be subscribed to and unsubscribed from using the PubNub service.
public class UserMetadataRepresentation: SubscribeTarget {
  init(id: String, pubnub: PubNub) {
    super.init(name: id, targetType: .channel, pubnub: pubnub)
  }
}

// MARK: - PubNubChannelMetadataRepresentation

/// Represents channel metadata that can be subscribed to and unsubscribed from using the PubNub service.
public class ChannelMetadataRepresentation: SubscribeTarget {
  init(id: String, pubnub: PubNub) {
    super.init(name: id, targetType: .channel, pubnub: pubnub)
  }
}
