//
//  DelayedHeartbeatEffect.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class DelayedHeartbeatEffect: EffectHandler {
  private let request: PresenceHeartbeatRequest
  private let reason: PubNubError
  private let timerEffect: TimerEffect?

  init(
    request: PresenceHeartbeatRequest,
    retryAttempt: Int,
    reason: PubNubError
  ) {
    self.request = request
    self.reason = reason
    self.timerEffect = TimerEffect(interval: request.reconnectionDelay(dueTo: reason, retryAttempt: retryAttempt))
  }

  func performTask(completionBlock: @escaping ([Presence.Event]) -> Void) {
    guard let timerEffect = timerEffect else {
      completionBlock([.heartbeatGiveUp(error: reason)]); return
    }
    timerEffect.performTask { [weak self] _ in
      self?.request.execute { result in
        switch result {
        case .success:
          completionBlock([.heartbeatSuccess])
        case .failure(let error):
          completionBlock([.heartbeatFailed(error: error)])
        }
      }
    }
  }

  func cancelTask() {
    timerEffect?.cancelTask()
    request.cancel()
  }

  deinit {
    cancelTask()
  }
}
