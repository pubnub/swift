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
  private let isCancelled = Atomic<Bool>(false)

  init(request: PresenceHeartbeatRequest) {
    self.request = request
  }

  func performTask(completionBlock: @escaping ([Presence.Event]) -> Void) {
    request.execute { [isCancelled] result in
      guard !isCancelled.lockedRead({ $0 }) else {
        return
      }

      switch result {
      case .success:
        completionBlock([.heartbeatSuccess])
      case .failure(let error):
        completionBlock([.heartbeatFailed(error: error)])
      }
    }
  }

  func cancelTask() {
    isCancelled.lockedWrite { $0 = true }
    request.cancel()
  }

  deinit {
    cancelTask()
  }
}
