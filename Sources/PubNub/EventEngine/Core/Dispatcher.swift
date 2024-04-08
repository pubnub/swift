//
//  Dispatcher.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - DispatcherListener

struct DispatcherListener<Event> {
  let onAnyInvocationCompleted: (([Event]) -> Void)
}

// MARK: - Dispatcher

protocol Dispatcher<Invocation, Event, Dependencies> {
  associatedtype Invocation: AnyEffectInvocation
  associatedtype Event
  associatedtype Dependencies

  func dispatch(
    invocations: [EffectInvocation<Invocation>],
    with dependencies: EventEngineDependencies<Dependencies>,
    notify listener: DispatcherListener<Event>
  )
}

// MARK: - EffectDispatcher

class EffectDispatcher<Invocation: AnyEffectInvocation, Event, Dependencies>: Dispatcher {
  private let factory: any EffectHandlerFactory<Invocation, Event, Dependencies>
  private let effectsCache = EffectsCache<Event>()

  init(factory: some EffectHandlerFactory<Invocation, Event, Dependencies>) {
    self.factory = factory
  }

  func hasPendingInvocation(_ invocation: Invocation) -> Bool {
    effectsCache.hasPendingEffect(with: invocation.id)
  }

  func dispatch(
    invocations: [EffectInvocation<Invocation>],
    with dependencies: EventEngineDependencies<Dependencies>,
    notify listener: DispatcherListener<Event>
  ) {
    invocations.forEach {
      switch $0 {
      case .managed(let invocation):
        executeEffect(
          effect: factory.effect(for: invocation, with: dependencies),
          storageId: invocation.id,
          notify: listener
        )
      case .regular(let invocation):
        executeEffect(
          effect: factory.effect(for: invocation, with: dependencies),
          storageId: UUID().uuidString,
          notify: listener
        )
      case .cancel(let cancelInvocation):
        effectsCache.getEffect(with: cancelInvocation.id)?.cancelTask()
        effectsCache.removeEffect(id: cancelInvocation.id)
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

private class EffectsCache<Event> {
  private var managedEffects: Atomic<[String: EffectWrapper<Event>]> = Atomic([:])

  func hasPendingEffect(with id: String) -> Bool {
    managedEffects.lockedRead { $0[id] } != nil
  }

  func put(effect: some EffectHandler<Event>, with id: String) {
    managedEffects.lockedWrite { $0[id] = EffectWrapper<Event>(id: id, effect: effect) }
  }

  func getEffect(with id: String) -> (any EffectHandler<Event>)? {
    managedEffects.lockedRead { $0[id] }?.effect
  }

  func removeEffect(id: String) {
    managedEffects.lockedWrite { $0[id] = nil }
  }
}

// MARK: - EffectWrapper

private struct EffectWrapper<Action> {
  let id: String
  let effect: any EffectHandler<Action>
}
