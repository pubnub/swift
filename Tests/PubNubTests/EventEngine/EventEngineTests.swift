//
//  EventEngineTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import XCTest

@testable import PubNub

fileprivate var initialState: ExampleState {
  ExampleState(
    x: 1000,
    y: 2000,
    z: 3000
  )
}

fileprivate var stateAfterSendingEvent1: ExampleState {
  ExampleState(
    x: 50,
    y: 100,
    z: 150
  )
}

fileprivate var stateAfterSendingEvent3: ExampleState {
  ExampleState(
    x: 99,
    y: 999,
    z: 9999
  )
}

fileprivate var stateAfterSendingEvent4: ExampleState {
  ExampleState(
    x: 0,
    y: 0,
    z: 0
  )
}

// MARK: - EventEngineTests

class EventEngineTests: XCTestCase {
  func testEventEngineTransitions() {
    let eventEngine = EventEngine(
      state: initialState,
      transition: StubTransition(),
      dispatcher: StubDispatcher(),
      dependencies: EventEngineDependencies(value: Void())
    )
    
    eventEngine.send(event: .event2)
    XCTAssertTrue(eventEngine.state == initialState)
    eventEngine.send(event: .event3)
    XCTAssertTrue(eventEngine.state == stateAfterSendingEvent3)
    eventEngine.send(event: .event1)
    XCTAssertTrue(eventEngine.state == stateAfterSendingEvent1)
    eventEngine.send(event: .event4)
    XCTAssertTrue(eventEngine.state == stateAfterSendingEvent3)
  }
}

// MARK: - Helpers

fileprivate struct ExampleState: Equatable {
  let x: Int
  let y: Int
  let z: Int
}

fileprivate enum ExampleEvent {
  case event1
  case event2
  case event3
  case event4
}

fileprivate enum ExampleInvocation: AnyEffectInvocation {
  case invocation

  var id: String {
    "invocation"
  }
  
  enum Cancellable: AnyCancellableInvocation {
    case invocation
    
    var id: String {
      "invocation"
    }
  }
}

fileprivate class StubTransition: TransitionProtocol {
  typealias State = ExampleState
  typealias Event = ExampleEvent
  typealias Invocation = ExampleInvocation
  
  func canTransition(from state: ExampleState, dueTo event: ExampleEvent) -> Bool {
    switch event {
    case .event1:
      return true
    case .event2:
      return false
    case .event3:
      return true
    case .event4:
      return true
    }
  }
  
  func transition(from state: ExampleState, event: ExampleEvent) -> TransitionResult<ExampleState, ExampleInvocation> {
    switch event {
    case .event1:
      return TransitionResult(state: stateAfterSendingEvent1, invocations: [])
    case .event3:
      return TransitionResult(state: stateAfterSendingEvent3, invocations: [])
    case .event4:
      return TransitionResult(state: state, invocations: [.managed(.invocation)])
    default:
      fatalError("Unexpected condition")
    }
  }
}

fileprivate struct StubDispatcher: Dispatcher {
  typealias Invocation = ExampleInvocation
  typealias Event = ExampleEvent
  typealias Dependencies = Void
  
  func dispatch(
    invocations: [EffectInvocation<Invocation>],
    with dependencies: EventEngineDependencies<Dependencies>,
    notify listener: DispatcherListener<Event>
  ) {
    invocations.forEach {
      switch $0 {
      case .managed(_):
        // Simulates that a hypothethical Effect returns an event back to EventEngine.
        // The result of processing this event might be the new State, see implementation for Transition function
        listener.onAnyInvocationCompleted([.event3])
      default:
        fatalError("Unexpected test condition")
      }
    }
  }
}
