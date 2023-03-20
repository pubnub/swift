//
//  Dispatcher.swift
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

///
/// Protocol for any type that can dispatch, track and schedule Effects.
/// Concrete implementations are responsible to schedule effects, tracking pending operations, and canceling them on behalf caller's request.
///
protocol Dispatcher<EffectKind, Event> {
  associatedtype EffectKind
  associatedtype Event
    
  var factory: any EffectHandlerFactory<EffectKind, Event> { get }
  
  func dispatch(
    invocations: [EffectInvocation<EffectKind, Event>],
    receiver: some EventReceiver<Event>
  )
}

///
/// Default implementation for Dispatcher.
///
class EffectDispatcher<EffectKind, Event>: Dispatcher {
  private(set) var factory: any EffectHandlerFactory<EffectKind, Event>
  private(set) var pendingEffects: [String: Box<EffectKind, Event>] = [:]
  
  class Box<EffectKind, Action> {
    let effect: any EffectHandler<EffectKind, Action>
    
    init(effect: any EffectHandler<EffectKind, Action>) {
      self.effect = effect
    }
  }
  
  init(factory: some EffectHandlerFactory<EffectKind, Event>) {
    self.factory = factory
  }
  
  func dispatch(
    invocations: [EffectInvocation<EffectKind, Event>],
    receiver: some EventReceiver<Event>
  ) {
    for invocation in invocations {
      let effect = factory.effect(for: invocation, with: eventDispatcher)
      pendingEffects[invocation.identifier]?.effect.cancel()
      pendingEffects[invocation.identifier] = Box<EffectKind, Event>(effect: effect)
      effect.start(onCompletion: {})
    }
  }
}
