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

// MARK: - DispatcherListener

struct DispatcherListener<Event> {
  let onAnyInvocationCompleted: (([Event]) -> Void)
}

// MARK: - Dispatcher

protocol Dispatcher<Invocation, Event, Input> {
  associatedtype Invocation: AnyEffectInvocation
  associatedtype Event
  associatedtype Input
      
  func dispatch(
    invocations: [EffectInvocation<Invocation>],
    with customInput: EventEngineCustomInput<Input>,
    notify listener: DispatcherListener<Event>
  )
}

// MARK: - EffectDispatcher

class EffectDispatcher<Invocation: AnyEffectInvocation, Event, Input>: Dispatcher {
  private let factory: any EffectHandlerFactory<Invocation, Event, Input>
  private let effectsCache = EffectsCache<Event>()
    
  init(factory: some EffectHandlerFactory<Invocation, Event, Input>) {
    self.factory = factory
  }
  
  func hasPendingInvocation(_ invocation: Invocation) -> Bool {
    effectsCache.hasPendingEffect(with: invocation.id)
  }
    
  func dispatch(
    invocations: [EffectInvocation<Invocation>],
    with customInput: EventEngineCustomInput<Input>,
    notify listener: DispatcherListener<Event>
  ) {
    invocations.forEach {
      switch $0 {
      case .managed(let invocation):
        executeEffect(
          effect: factory.effect(for: invocation, with: customInput),
          storageId: invocation.id,
          notify: listener
        )
      case .regular(let invocation):
        executeEffect(
          effect: factory.effect(for: invocation, with: customInput),
          storageId: UUID().uuidString,
          notify: listener
        )
      case .cancel(let cancelInvocation):
        effectsCache.getEffect(with: cancelInvocation.id)?.cancelTask()
      }
    }
  }
  
  private func executeEffect(
    effect: some EffectHandler<Event>,
    storageId id: String,
    notify listener: DispatcherListener<Event>
  ) {
    effectsCache.put(effect: effect, with: id)
    effect.performTask { [weak effectsCache] results in
      effectsCache?.removeEffect(id: id)
      listener.onAnyInvocationCompleted(results)
    }
  }
}

// MARK: - EffectsCache

fileprivate class EffectsCache<Event> {
  private var managedEffects: Atomic<[String: EffectWrapper<Event>]> = Atomic([:])

  func hasPendingEffect(with id: String) -> Bool {
    managedEffects.lockedRead { $0[id] } != nil
  }
  
  func put(effect: some EffectHandler<Event>, with id: String) {
    managedEffects.lockedWrite { $0[id] = EffectWrapper<Event>(id: id, effect: effect) }
  }
    
  func getEffect(with id: String) -> (any EffectHandler<Event>)? {
    managedEffects.lockedRead() { $0[id] }?.effect
  }
  
  func removeEffect(id: String) {
    managedEffects.lockedWrite { $0[id] = nil }
  }
}

// MARK: - EffectWrapper

fileprivate struct EffectWrapper<Action> {
  let id: String
  let effect: any EffectHandler<Action>
}
