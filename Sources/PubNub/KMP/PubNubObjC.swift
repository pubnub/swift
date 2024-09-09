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

/// All public symbols in this file that are annotated with @objc are intended to allow interoperation
/// with Kotlin Multiplatform for other PubNub frameworks.
///
/// While these symbols are public, they are intended strictly for internal usage.

/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

@objc
public class PubNubObjC: NSObject {
  let pubnub: PubNub

  @objc
  public let configObjC: PubNubConfigurationObjC

  public init(pubnub: PubNub) {
    self.pubnub = pubnub
    self.configObjC = PubNubConfigurationObjC(configuration: pubnub.configuration)
    super.init()
  }

  @objc
  public init(user: String, subKey: String, pubKey: String) {
    self.pubnub = PubNub(
      configuration: PubNubConfiguration(
        publishKey: pubKey,
        subscribeKey: subKey,
        userId: user
      )
    )
    self.configObjC = PubNubConfigurationObjC(configuration: self.pubnub.configuration)
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

// MARK: - Configuration

@objc
public class PubNubConfigurationObjC: NSObject {
  let configuration: PubNubConfiguration

  public init(configuration: PubNubConfiguration) {
    self.configuration = configuration
  }

  @objc
  public var userId: String {
    configuration.userId
  }

  @objc
  public var authKey: String? {
    configuration.authKey
  }
}
