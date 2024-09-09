//
//  PubNubEntityRepresentableObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// All public symbols in this file that are annotated with @objc are intended to allow interoperation
/// with Kotlin Multiplatform for other PubNub frameworks.
///
/// While these symbols are public, they are intended strictly for internal usage.

/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

@objc public class PubNubEntityRepresentableObjC: NSObject {
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
public class PubNubChannelEntityObjC: PubNubEntityRepresentableObjC {
  let channel: ChannelRepresentation

  init(channel: ChannelRepresentation) {
    self.channel = channel
    super.init(entity: channel)
  }
}

@objc
public class PubNubChannelGroupEntityObjC: PubNubEntityRepresentableObjC {
  let channelGroup: ChannelGroupRepresentation

  init(channelGroup: ChannelGroupRepresentation) {
    self.channelGroup = channelGroup
    super.init(entity: channelGroup)
  }
}

@objc
public class PubNubUserMetadataEntityObjC: PubNubEntityRepresentableObjC {
  let userMetadata: UserMetadataRepresentation

  init(userMetadata: UserMetadataRepresentation) {
    self.userMetadata = userMetadata
    super.init(entity: userMetadata)
  }
}

@objc
public class PubNubChannelMetadataEntityObjC: PubNubEntityRepresentableObjC {
  let channelMetadata: ChannelMetadataRepresentation

  init(channelMetadata: ChannelMetadataRepresentation) {
    self.channelMetadata = channelMetadata
    super.init(entity: channelMetadata)
  }
}
