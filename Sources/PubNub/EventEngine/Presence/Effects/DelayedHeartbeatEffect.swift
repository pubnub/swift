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

class DelayedHeartbeatEffect: DelayedEffectHandler {
  typealias Event = Presence.Event
  
  private let request: PresenceHeartbeatRequest
  private let configuration: PubNubConfiguration
  private let retryAttempt: Int
  private let reason: PubNubError
  
  var workItem: DispatchWorkItem?
  
  init(
    request: PresenceHeartbeatRequest,
    retryAttempt: Int,
    reason: PubNubError,
    configuration: PubNubConfiguration
  ) {
    self.request = request
    self.retryAttempt = retryAttempt
    self.reason = reason
    self.configuration = configuration
  }
  
  func delayInterval() -> TimeInterval? {
    guard let automaticRetry = configuration.automaticRetry else {
      return nil
    }
    guard automaticRetry[.presence] != nil else {
      return nil
    }
    guard automaticRetry.retryLimit > retryAttempt else {
      return nil
    }
    guard let underlyingError = reason.underlying else {
      return automaticRetry.policy.delay(for: retryAttempt)
    }
    guard let urlResponse = reason.affected.findFirst(by: PubNubError.AffectedValue.response) else {
      return nil
    }

    let shouldRetry = automaticRetry.shouldRetry(
      response: urlResponse,
      error: underlyingError
    )
    
    return shouldRetry ? automaticRetry.policy.delay(for: retryAttempt) : nil
  }
  
  func onEarlyExit(notify completionBlock: @escaping ([Presence.Event]) -> Void) {
    completionBlock([.heartbeatGiveUp(error: reason)])
  }
  
  func onDelayExpired(notify completionBlock: @escaping ([Presence.Event]) -> Void) {
    request.execute() { result in
      switch result {
      case .success(_):
        completionBlock([.heartbeatSuccess])
      case .failure(let error):
        completionBlock([.heartbeatFailed(error: error)])
      }
    }
  }
  
  func cancelTask() {
    workItem?.cancel()
    request.cancel()
  }
  
  deinit {
    cancelTask()
  }
}
