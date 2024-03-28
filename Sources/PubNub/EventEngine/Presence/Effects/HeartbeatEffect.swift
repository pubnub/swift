//
//  HeartbeatEffect.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class HeartbeatEffect: EffectHandler {
  private let request: PresenceHeartbeatRequest

  init(request: PresenceHeartbeatRequest) {
    self.request = request
  }

  func performTask(completionBlock: @escaping ([Presence.Event]) -> Void) {
    request.execute { result in
      switch result {
      case .success:
        completionBlock([.heartbeatSuccess])
      case .failure(let error):
        completionBlock([.heartbeatFailed(error: error)])
      }
    }
  }

  deinit {
    request.cancel()
  }
}
