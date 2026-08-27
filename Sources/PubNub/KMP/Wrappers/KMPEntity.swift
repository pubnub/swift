//
//  PubNubEntityRepresentableObjC.swift
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

@objc public class KMPEntity: NSObject {
  let entity: Subscribable

  init(entity: Subscribable) {
    self.entity = entity
  }
}

@objc
public class KMPChannelEntity: KMPEntity {
  let channel: Channel

  init(channel: Channel) {
    self.channel = channel
    super.init(entity: channel)
  }
}

@objc
public class KMPChannelGroupEntity: KMPEntity {
  let channelGroup: ChannelGroup

  init(channelGroup: ChannelGroup) {
    self.channelGroup = channelGroup
    super.init(entity: channelGroup)
  }
}

@objc
public class KMPUserMetadataEntity: KMPEntity {
  let userMetadata: UserMetadata

  init(userMetadata: UserMetadata) {
    self.userMetadata = userMetadata
    super.init(entity: userMetadata)
  }
}

@objc
public class KMPChannelMetadataEntity: KMPEntity {
  let channelMetadata: ChannelMetadata

  init(channelMetadata: ChannelMetadata) {
    self.channelMetadata = channelMetadata
    super.init(entity: channelMetadata)
  }
}

// MARK: - Data Sync

@objc
public class KMPDataSyncReference: KMPEntity {
  @objc public let id: String

  init(id: String, entity: Subscribable) {
    self.id = id
    super.init(entity: entity)
  }

  @objc
  public func subscription(withProjection projection: String) -> KMPSubscription {
    KMPSubscription(subscription: dataSyncSubscription(projection: projection))
  }

  func dataSyncSubscription(projection: String) -> Subscription {
    fatalError("Subclasses must implement dataSyncSubscription(projection:)")
  }
}

@objc
public class KMPDataSyncUserReference: KMPDataSyncReference {
  private let user: DataSyncUser

  init(user: DataSyncUser) {
    self.user = user
    super.init(id: user.id, entity: user)
  }

  override func dataSyncSubscription(projection: String) -> Subscription {
    user.subscription(projection: projection)
  }
}

@objc
public class KMPDataSyncChannelReference: KMPDataSyncReference {
  private let channel: DataSyncChannel

  init(channel: DataSyncChannel) {
    self.channel = channel
    super.init(id: channel.id, entity: channel)
  }

  override func dataSyncSubscription(projection: String) -> Subscription {
    channel.subscription(projection: projection)
  }
}

@objc
public class KMPDataSyncMembershipReference: KMPDataSyncReference {
  private let membership: DataSyncMembership

  init(membership: DataSyncMembership) {
    self.membership = membership
    super.init(id: membership.id, entity: membership)
  }

  override func dataSyncSubscription(projection: String) -> Subscription {
    membership.subscription(projection: projection)
  }
}

@objc
public class KMPDataSyncEntityReference: KMPDataSyncReference {
  private let dataSyncEntity: DataSyncEntity

  init(entity: DataSyncEntity) {
    self.dataSyncEntity = entity
    super.init(id: entity.id, entity: entity)
  }

  override func dataSyncSubscription(projection: String) -> Subscription {
    dataSyncEntity.subscription(projection: projection)
  }
}

@objc
public class KMPDataSyncRelationshipReference: KMPDataSyncReference {
  private let relationship: DataSyncRelationship

  init(relationship: DataSyncRelationship) {
    self.relationship = relationship
    super.init(id: relationship.id, entity: relationship)
  }

  override func dataSyncSubscription(projection: String) -> Subscription {
    relationship.subscription(projection: projection)
  }
}
