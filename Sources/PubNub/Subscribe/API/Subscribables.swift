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

// MARK: - Data Sync

/// A reference to a Data Sync user by identifier.
public class DataSyncUser: Subscribable {
  /// The identifier of the Data Sync user
  public let id: String

  init(id: String, pubnub: PubNub) {
    self.id = id
    super.init(pubnub: pubnub)
  }

  override func subscriptionTopology(includingPresence: Bool) -> SubscriptionTopology {
    SubscriptionTopology(channels: [id])
  }

  /// Creates a subscription to a projection of this Data Sync user.
  public func subscription(
    projection projectionName: String,
    queue: DispatchQueue = .main,
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) -> Subscription {
    makeProjectionSubscription(projectionName, id: id, queue: queue, options: options)
  }
}

/// A reference to a Data Sync channel by identifier.
public class DataSyncChannel: Subscribable {
  /// The identifier of the Data Sync channel
  public let id: String

  init(id: String, pubnub: PubNub) {
    self.id = id
    super.init(pubnub: pubnub)
  }

  override func subscriptionTopology(includingPresence: Bool) -> SubscriptionTopology {
    SubscriptionTopology(channels: [id])
  }

  /// Creates a subscription to a projection of this Data Sync channel.
  public func subscription(
    projection projectionName: String,
    queue: DispatchQueue = .main,
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) -> Subscription {
    makeProjectionSubscription(projectionName, id: id, queue: queue, options: options)
  }
}

/// A reference to a Data Sync membership by identifier.
public class DataSyncMembership: Subscribable {
  /// The identifier of the Data Sync membership
  public let id: String

  init(id: String, pubnub: PubNub) {
    self.id = id
    super.init(pubnub: pubnub)
  }

  override func subscriptionTopology(includingPresence: Bool) -> SubscriptionTopology {
    SubscriptionTopology(channels: [id])
  }

  /// Creates a subscription to a projection of this Data Sync membership.
  public func subscription(
    projection projectionName: String,
    queue: DispatchQueue = .main,
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) -> Subscription {
    makeProjectionSubscription(projectionName, id: id, queue: queue, options: options)
  }
}

/// A reference to a Data Sync entity by identifier.
public class DataSyncEntity: Subscribable {
  /// The identifier of the Data Sync entity
  public let id: String

  init(id: String, pubnub: PubNub) {
    self.id = id
    super.init(pubnub: pubnub)
  }

  override func subscriptionTopology(includingPresence: Bool) -> SubscriptionTopology {
    SubscriptionTopology(channels: [id])
  }

  /// Creates a subscription to a projection of this Data Sync entity.
  public func subscription(
    projection projectionName: String,
    queue: DispatchQueue = .main,
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) -> Subscription {
    makeProjectionSubscription(projectionName, id: id, queue: queue, options: options)
  }
}

/// A reference to a Data Sync relationship by identifier.
public class DataSyncRelationship: Subscribable {
  /// The identifier of the Data Sync relationship
  public let id: String

  init(id: String, pubnub: PubNub) {
    self.id = id
    super.init(pubnub: pubnub)
  }

  override func subscriptionTopology(includingPresence: Bool) -> SubscriptionTopology {
    SubscriptionTopology(channels: [id])
  }

  /// Creates a subscription to a projection of this Data Sync relationship.
  public func subscription(
    projection projectionName: String,
    queue: DispatchQueue = .main,
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) -> Subscription {
    makeProjectionSubscription(projectionName, id: id, queue: queue, options: options)
  }
}

private extension Subscribable {
  func makeProjectionSubscription(
    _ projectionName: String,
    id: String,
    queue: DispatchQueue,
    options: SubscriptionOptions
  ) -> Subscription {
    Subscription(
      queue: queue,
      target: DataSyncProjection(
        channelName: projectionName == "default" ? id : "__\(projectionName)__\(id)",
        pubnub: pubnub
      ),
      options: options
    )
  }
}

private final class DataSyncProjection: Subscribable {
  private let channelName: String

  init(channelName: String, pubnub: PubNub?) {
    self.channelName = channelName
    super.init(pubnub: pubnub)
  }

  override func subscriptionTopology(includingPresence: Bool) -> SubscriptionTopology {
    SubscriptionTopology(channels: [channelName])
  }
}
