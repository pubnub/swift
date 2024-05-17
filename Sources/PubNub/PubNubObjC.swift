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
public class PubNubObjC : NSObject {
  private let pubnub: PubNub
  
  // MARK: - Init
  
  @objc
  public init(user: String, subKey: String, pubKey: String) {
    self.pubnub = PubNub(configuration: PubNubConfiguration(publishKey: pubKey, subscribeKey: subKey, userId: user))
    super.init()
  }
  
  // MARK: - Publish
  
  @objc
  public func publish(
    channel: String,
    message: Any,
    meta: Any?,
    shouldStore: NSNumber?,
    ttl: NSNumber?,
    onSuccess: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.publish(
      channel: channel,
      message: AnyJSON(message),
      shouldStore: shouldStore?.boolValue,
      storeTTL: shouldStore?.intValue,
      meta: resolveJSONObject(meta)
    ) {
      switch $0 {
      case .success(let timetoken):
        onSuccess(timetoken)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  private func resolveJSONObject(_ object: Any?) -> AnyJSON? {
    if let object = object {
      return AnyJSON(object)
    } else {
      return nil
    }
  }
  
  // MARK: Signal
  
  @objc
  public func signal(
    channel: String,
    message: Any,
    onSuccess: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.signal(channel: channel, message: AnyJSON(message)) {
      switch $0 {
      case .success(let timetoken):
        onSuccess(timetoken)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  // MARK: Subscribed channels & channel groups
  
  @objc
  public var subscribedChannels: [String] {
    pubnub.subscribedChannels
  }
  
  @objc
  public var subscribedChannelGroups: [String] {
    pubnub.subscribedChannelGroups
  }
  
  // MARK: Push
  
  @objc
  public func addChannelsToPushNotifications(
    channels: [String],
    deviceId: Data,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.addPushChannelRegistrations(channels, for: deviceId) {
      switch $0 {
      case .success(let channels):
        onSuccess(channels)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  public func listPushChannels(
    deviceId: Data,
    pushType: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushType = PubNub.PushService(rawValue: pushType) else {
      onFailure(PubNubError(.invalidArguments, additional: ["Invalid pushType"])); return
    }
    pubnub.listPushChannelRegistrations(for: deviceId, of: pushType) {
      switch $0 {
      case .success(let channels):
        onSuccess(channels)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  public func removeChannelsFromPush(
    channels: [String],
    deviceId: Data,
    pushType: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.removePushChannelRegistrations(channels, for: deviceId) {
      switch $0 {
      case .success(let channels):
        onSuccess(channels)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
}
