//
//  EmitStatusEffect.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
import Foundation

struct EmitStatusEffect: EffectHandler {
  let statusChange: Subscribe.ConnectionStatusChange
  let listeners: [BaseSubscriptionListener]

  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    if let error = statusChange.error {
      listeners.forEach {
        $0.emit(subscribe: .errorReceived(error))
      }
    }
    listeners.forEach {
      $0.emit(subscribe: .connectionChanged(statusChange.newStatus))
    }
    completionBlock([])
  }
}
