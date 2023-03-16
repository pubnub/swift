//
//  Dispatcher.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

///
/// Protocol for any type that can dispatch, track and schedule Effects.
/// Concrete implementations are responsible to schedule effects, tracking pending operations, and canceling them on behalf caller's request.
///
protocol Dispatcher<Kind, Action> {
  associatedtype Kind
  associatedtype Action
    
  var factory: any EffectHandlerFactory<Kind, Action> { get }
  
  func dispatch(invocations: [EffectInvocation<Kind, Action>])
}

///
/// Default implementation for Dispatcher.
///
class EffectDispatcher<Kind, Action>: Dispatcher {
  private(set) var factory: any EffectHandlerFactory<Kind, Action>
  // private(set) var pendingEffects: [String: any EffectHandler<Kind, Action>] = [:]
  
  init(factory: some EffectHandlerFactory<Kind, Action>) {
    self.factory = factory
  }
  
  func dispatch(invocations: [EffectInvocation<Kind, Action>]) {
    for invocation in invocations {
      let effect = factory.effect(for: invocation)
//      pendingEffects[invocation.identifier]?.cancel()
//      pendingEffects[invocation.identifier] = effect
      effect.start()
    }
  }
}
