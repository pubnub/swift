//
//  WaitEffect.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class WaitEffect: EffectHandler {
  private let timerEffect: TimerEffect?

  init(configuration: PubNubConfiguration) {
    if configuration.heartbeatInterval > 0 {
      self.timerEffect = TimerEffect(interval: TimeInterval(configuration.heartbeatInterval))
    } else {
      self.timerEffect = nil
    }
  }

  func performTask(completionBlock: @escaping ([Presence.Event]) -> Void) {
    guard let timerEffect = timerEffect else {
      completionBlock([]); return
    }
    timerEffect.performTask(completionBlock: { _ in
      completionBlock([.timesUp])
    })
  }

  func cancelTask() {
    timerEffect?.cancelTask()
  }
}
