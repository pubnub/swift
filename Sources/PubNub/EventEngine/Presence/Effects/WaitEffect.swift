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

class WaitEffect: DelayedEffectHandler {
  typealias Event = Presence.Event
  
  private let configuration: SubscriptionConfiguration
  var workItem: DispatchWorkItem?
  
  init(configuration: SubscriptionConfiguration) {
    self.configuration = configuration
  }

  func delayInterval() -> TimeInterval? {
    configuration.heartbeatInterval > 0 ? TimeInterval(configuration.heartbeatInterval) : nil
  }
  
  func onEarlyExit(notify completionBlock: @escaping ([Presence.Event]) -> Void) {
    completionBlock([])
  }
  
  func onDelayExpired(notify completionBlock: @escaping ([Presence.Event]) -> Void) {
    completionBlock([.timesUp])
  }
  
  func cancelTask() {
    workItem?.cancel()
  }
}
