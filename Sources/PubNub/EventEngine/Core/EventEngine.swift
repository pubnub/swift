//
//  EventEngine.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

struct EventEngineDependencies<Dependencies> {
  let value: Dependencies
}

class EventEngine<State, Event, Invocation: AnyEffectInvocation, Input> {
  private let transition: any TransitionProtocol<State, Event, Invocation>
  private let dispatcher: any Dispatcher<Invocation, Event, Input>
  private let recursiveLock = NSRecursiveLock()
  private var internalStateContainer: State

  private(set) var state: State {
    get {
      recursiveLock.lock()
      defer { recursiveLock.unlock() }
      return internalStateContainer
    } set {
      recursiveLock.lock()
      defer { recursiveLock.unlock() }
      internalStateContainer = newValue
    }
  }

  var dependencies: EventEngineDependencies<Input>
  var onStateUpdated: ((State) -> Void)?

  init(
    state: State,
    transition: some TransitionProtocol<State, Event, Invocation>,
    onStateUpdated: ((State) -> Void)? = nil,
    dispatcher: some Dispatcher<Invocation, Event, Input>,
    dependencies: EventEngineDependencies<Input>
  ) {
    self.internalStateContainer = state
    self.onStateUpdated = onStateUpdated
    self.transition = transition
    self.dispatcher = dispatcher
    self.dependencies = dependencies
  }

  func send(event: Event) {
    recursiveLock.lock()

    defer {
      recursiveLock.unlock()
    }

    let currentState = state

    guard transition.canTransition(
      from: currentState,
      dueTo: event
    ) else {
      return
    }

    let transitionResult = transition.transition(from: currentState, event: event)
    let invocations = transitionResult.invocations

    state = transitionResult.state
    onStateUpdated?(state)

    let listener = DispatcherListener<Event>(
      onAnyInvocationCompleted: { [weak self] results in
        results.forEach {
          self?.send(event: $0)
        }
      }
    )
    dispatcher.dispatch(
      invocations: invocations,
      with: dependencies,
      notify: listener
    )
  }
}
