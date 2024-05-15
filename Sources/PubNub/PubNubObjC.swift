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

  @objc
  public init(user: String, subKey: String, pubKey: String) {
    self.pubnub = PubNub(configuration: PubNubConfiguration(publishKey: pubKey, subscribeKey: subKey, userId: user))
    super.init()
  }
  
  @objc
  public func publish(
    channel: String,
    message: Any,
    onResponse: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.publish(channel: channel, message: AnyJSON(message), completion: { (result: Result<Timetoken, Error>) -> Void in
      print(result)
      switch result {
      case .success(let timetoken):
        onResponse(timetoken)
      case .failure(let error):
        onFailure(error)
      }
    })
  }
}
