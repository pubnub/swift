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
    onResponse: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.publish(
      channel: channel,
      message: AnyJSON(message),
      shouldStore: shouldStore?.boolValue,
      storeTTL: shouldStore?.intValue,
      meta: resolveJSONObject(meta),
      completion: { (result: Result<Timetoken, Error>) -> Void in
        switch result {
        case .success(let timetoken):
          onResponse(timetoken)
        case .failure(let error):
          onFailure(error)
        }
      })
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
    onResponse: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.signal(
      channel: channel,
      message: AnyJSON(message),
      completion: { result in
        switch result {
        case .success(let timetoken):
          onResponse(timetoken)
        case .failure(let error):
          onFailure(error)
        }
      }
    )
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
}
