//
//  KMPPubNub.swift
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
// may change in future versions of the framework, potentially leading to breaking changes..

import Foundation

@objc
public class KMPPubNub: NSObject {
  let pubnub: PubNub

  @objc
  public let configObjC: KMPPubNubConfiguration

  public init(pubnub: PubNub) {
    self.pubnub = pubnub
    self.configObjC = KMPPubNubConfiguration(configuration: pubnub.configuration)
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
    self.configObjC = KMPPubNubConfiguration(configuration: self.pubnub.configuration)
    super.init()
  }
}

// MARK: - Token

@objc
public extension KMPPubNub {
  func set(token: String) {
    pubnub.set(token: token)
  }
}

// MARK: - Disconnect

@objc
public extension KMPPubNub {
  func disconnect() {
    pubnub.disconnect()
  }
}

// MARK: - Entities

@objc
public extension KMPPubNub {
  func channel(with name: String) -> KMPChannelEntity {
    KMPChannelEntity(channel: pubnub.channel(name))
  }

  func channelGroup(with name: String) -> KMPChannelGroupEntity {
    KMPChannelGroupEntity(channelGroup: pubnub.channelGroup(name))
  }

  func userMetadata(with id: String) -> KMPUserMetadataEntity {
    KMPUserMetadataEntity(userMetadata: pubnub.userMetadata(id))
  }

  func channelMetadata(with id: String) -> KMPChannelMetadataEntity {
    KMPChannelMetadataEntity(channelMetadata: pubnub.channelMetadata(id))
  }
}

// MARK: - Configuration

@objc
public class KMPPubNubConfiguration: NSObject {
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
