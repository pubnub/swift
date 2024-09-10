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

  @objc
  public var name: String {
    entity.name
  }
}

@objc
public class KMPChannelEntity: KMPEntity {
  let channel: ChannelRepresentation

  init(channel: ChannelRepresentation) {
    self.channel = channel
    super.init(entity: channel)
  }
}

@objc
public class KMPChannelGroupEntity: KMPEntity {
  let channelGroup: ChannelGroupRepresentation

  init(channelGroup: ChannelGroupRepresentation) {
    self.channelGroup = channelGroup
    super.init(entity: channelGroup)
  }
}

@objc
public class KMPUserMetadataEntity: KMPEntity {
  let userMetadata: UserMetadataRepresentation

  init(userMetadata: UserMetadataRepresentation) {
    self.userMetadata = userMetadata
    super.init(entity: userMetadata)
  }
}

@objc
public class KMPChannelMetadataEntity: KMPEntity {
  let channelMetadata: ChannelMetadataRepresentation

  init(channelMetadata: ChannelMetadataRepresentation) {
    self.channelMetadata = channelMetadata
    super.init(entity: channelMetadata)
  }
}
