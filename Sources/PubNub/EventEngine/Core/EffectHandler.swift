//
//  EffectHandler.swift
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

// MARK: - EffectHandlerFactory

protocol EffectHandlerFactory<EffectInvocation, Event, Input> {
  associatedtype EffectInvocation
  associatedtype Event
  associatedtype Input
  
  func effect(
    for invocation: EffectInvocation,
    with customInput: EventEngineCustomInput<Input>
  ) -> any EffectHandler<Event>
}

// MARK: - EffectHandler

protocol EffectHandler<Event> {
  associatedtype Event
    
  func performTask(completionBlock: @escaping ([Event]) -> Void)
  func cancelTask()
}

extension EffectHandler {
  func cancelTask() {}
}

// MARK: - Delayed Effect Handler

protocol DelayedEffectHandler: AnyObject, EffectHandler {
  var workItem: DispatchWorkItem? { get set }
  
  func delayInterval() -> TimeInterval?
  func onEarlyExit(notify completionBlock: @escaping ([Event]) -> Void)
  func onDelayExpired(notify completionBlock: @escaping ([Event]) -> Void)
}

extension DelayedEffectHandler {
  func performTask(completionBlock: @escaping ([Event]) -> Void) {
    guard let delay = delayInterval() else {
      onEarlyExit(notify: completionBlock); return
    }
    let workItem = DispatchWorkItem() { [weak self] in
      self?.onDelayExpired(notify: completionBlock)
    }
    DispatchQueue.global(qos: .default).asyncAfter(
      deadline: .now() + delay,
      execute: workItem
    )
    self.workItem = workItem
  }
  
  func cancelTask() {
    workItem?.cancel()
  }
}
