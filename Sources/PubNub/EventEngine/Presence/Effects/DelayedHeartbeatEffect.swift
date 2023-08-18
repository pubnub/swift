//
//  DelayedHeartbeatEffect.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2023 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

class DelayedHeartbeatEffect: EffectHandler {
  private let request: PresenceHeartbeatRequest
  private let configuration: SubscriptionConfiguration
  private let currentAttempt: Int
  private let reason: PubNubError
  
  private var workItem: DispatchWorkItem?
  private var completionBlock: (([Presence.Event]) -> Void)?
  
  init(
    request: PresenceHeartbeatRequest,
    currentAttempt: Int,
    reason: PubNubError,
    configuration: SubscriptionConfiguration
  ) {
    self.request = request
    self.currentAttempt = currentAttempt
    self.reason = reason
    self.configuration = configuration
  }
  
  func performTask(completionBlock: @escaping ([Presence.Event]) -> Void) {
    if currentAttempt <= 2 {
      let workItem = DispatchWorkItem() { [weak self] in
        self?.request.execute() { result in
          switch result {
          case .success(_):
            completionBlock([.heartbeatSuccess])
          case .failure(let error):
            completionBlock([.heartbeatFailed(error: error)])
          }
        }
      }
      self.workItem = workItem
      self.completionBlock = completionBlock

      DispatchQueue.global(qos: .default).asyncAfter(
        deadline: .now() + computeDelay(),
        execute: workItem
      )
    } else {
      completionBlock([.heartbeatGiveUp(error: reason)])
    }
  }
  
  func cancelTask() {
    workItem?.cancel()
    completionBlock?([])
    completionBlock = nil
  }
  
  deinit {
    cancelTask()
  }
}

fileprivate extension DelayedHeartbeatEffect {
  func computeDelay() -> TimeInterval {
    if currentAttempt == 0 {
      return 0
    } else if currentAttempt == 1 {
      return 0.5 * Double(configuration.durationUntilTimeout)
    } else {
      return Double(configuration.durationUntilTimeout) - 1.0
    }
  }
}
