//
//  PubNubObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubObjC: NSObject {
  let pubnub: PubNub

  @objc
  public init(user: String, subKey: String, pubKey: String) {
    self.pubnub = PubNub(
      configuration: PubNubConfiguration(
        publishKey: pubKey,
        subscribeKey: subKey,
        userId: user
      )
    )
    super.init()
  }
}

// MARK: - Token

@objc
public extension PubNubObjC {
  func set(token: String) {
    pubnub.set(token: token)
  }
}

// MARK: - Disconnect

@objc
public extension PubNubObjC {
  func disconnect() {
    pubnub.disconnect()
  }
}

// MARK: - Entities

@objc
public extension PubNubObjC {
  func channel(with name: String) -> PubNubChannelEntityObjC {
    PubNubChannelEntityObjC(channel: pubnub.channel(name))
  }

  func channelGroup(with name: String) -> PubNubChannelGroupEntityObjC {
    PubNubChannelGroupEntityObjC(channelGroup: pubnub.channelGroup(name))
  }

  func userMetadata(with id: String) -> PubNubUserMetadataEntityObjC {
    PubNubUserMetadataEntityObjC(userMetadata: pubnub.userMetadata(id))
  }

  func channelMetadata(with id: String) -> PubNubChannelMetadataEntityObjC {
    PubNubChannelMetadataEntityObjC(channelMetadata: pubnub.channelMetadata(id))
  }
}
