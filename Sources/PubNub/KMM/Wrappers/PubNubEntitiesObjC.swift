//
//  PubNubEntitiesObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

protocol PubNubEntityObjC {
  var entity: Subscribable { get }
}

@objc
public class PubNubChannelEntityObjC: NSObject, PubNubEntityObjC {
  let channel: ChannelRepresentation
   
  var entity: Subscribable {
    channel
  }
  
  @objc
  public var name: String {
    channel.name
  }
  
  init(channel: ChannelRepresentation) {
    self.channel = channel
  }
}

@objc
public class PubNubChannelGroupEntityObjC: NSObject, PubNubEntityObjC {
  let channelGroup: ChannelGroupRepresentation

  var entity: Subscribable {
    channelGroup
  }
  
  @objc
  public var name: String {
    channelGroup.name
  }
  
  init(channelGroup: ChannelGroupRepresentation) {
    self.channelGroup = channelGroup
  }
}

@objc
public class PubNubUserMetadataEntityObjC: NSObject, PubNubEntityObjC {
  let userMetadata: UserMetadataRepresentation
  
  var entity: Subscribable {
    userMetadata
  }
  
  @objc
  public var name: String {
    userMetadata.name
  }
  
  init(userMetadata: UserMetadataRepresentation) {
    self.userMetadata = userMetadata
  }

}

@objc
public class PubNubChannelMetadataEntityObjC: NSObject, PubNubEntityObjC {
  let channelMetadata: ChannelMetadataRepresentation
  
  var entity: Subscribable {
    channelMetadata
  }
  
  @objc
  public var name: String {
    channelMetadata.name
  }
  
  init(channelMetadata: ChannelMetadataRepresentation) {
    self.channelMetadata = channelMetadata
  }
}
