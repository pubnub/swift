//
//  DispatcherTests.swift
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

class DispatcherTests: XCTestCase {
  func testDispatcher_FinishingAnyInvocationNotifiesListener() {
    let onResultReceivedExpectation = XCTestExpectation(description: "onResultReceived")
    onResultReceivedExpectation.expectedFulfillmentCount = 4
    onResultReceivedExpectation.assertForOverFulfill = true
        
    let dispatcher = EffectDispatcher(factory: MockEffectHandlerFactory())
    let listener = DispatcherListener<TestEvent>(onAnyInvocationCompleted: { _ in
      onResultReceivedExpectation.fulfill()
    })
    
    dispatcher.dispatch(
      invocations: [
        .managed(.first),
        .managed(.second),
        .managed(.third),
        .managed(.fourth)
      ],
      with: EventEngineDependencies(value: Void()),
      notify: listener
    )
    
    wait(for: [onResultReceivedExpectation], timeout: 1.0)
  }
  
  func testDispatcher_CancelInvocationsWithManagedInvocationsNotifiesListener() {
    let onResultReceivedExpectation = XCTestExpectation(description: "onResultReceived")
    onResultReceivedExpectation.expectedFulfillmentCount = 2
    onResultReceivedExpectation.assertForOverFulfill = true
    
    let dispatcher = EffectDispatcher(factory: MockEffectHandlerFactory())
    let listener = DispatcherListener<TestEvent>(onAnyInvocationCompleted: { _ in
      onResultReceivedExpectation.fulfill()
    })
    
    dispatcher.dispatch(
      invocations: [
        .cancel(.firstCancellable),
        .managed(.second),
        .cancel(.thirdCancellable),
        .managed(.fourth)
      ],
      with: EventEngineDependencies(value: Void()),
      notify: listener
    )
    
    wait(for: [onResultReceivedExpectation], timeout: 1.0)
  }
  
  func testDispatcher_NotifiesListenerWithExpectedEvents() {
    let dispatcher = EffectDispatcher(factory: StubEffectHandlerFactory())
    let listener = DispatcherListener<TestEvent>(onAnyInvocationCompleted: { events in
      XCTAssertEqual(events, [.event1, .event3])
    })
    
    dispatcher.dispatch(
      invocations: [.managed(.first)],
      with: EventEngineDependencies(value: Void()),
      notify: listener
    )
  }
  
  func testDispatcher_RemovesEffectsOnFinish() {
    let onResultReceivedExpectation = XCTestExpectation(description: "onResultReceived")
    onResultReceivedExpectation.expectedFulfillmentCount = 3
    onResultReceivedExpectation.assertForOverFulfill = true

    let dispatcher = EffectDispatcher(factory: MockEffectHandlerFactory())
    let listener = DispatcherListener<TestEvent>(onAnyInvocationCompleted: { results in
      onResultReceivedExpectation.fulfill()
    })
        
    dispatcher.dispatch(
      invocations: [
        .managed(.first),
        .managed(.second),
        .cancel(.thirdCancellable),
        .managed(.fourth)
      ],
      with: EventEngineDependencies(value: Void()),
      notify: listener
    )
    
    wait(for: [onResultReceivedExpectation], timeout: 2.0)
    
    XCTAssertFalse(dispatcher.hasPendingInvocation(.first))
    XCTAssertFalse(dispatcher.hasPendingInvocation(.second))
    XCTAssertFalse(dispatcher.hasPendingInvocation(.third))
    XCTAssertFalse(dispatcher.hasPendingInvocation(.fourth))
  }
}

fileprivate enum TestEvent {
  case event1
  case event2
  case event3
}

fileprivate enum TestInvocation: String, AnyEffectInvocation {
  case first = "first"
  case second = "second"
  case third = "third"
  case fourth = "fourth"
  
  var id: String {
    rawValue
  }
  
  enum Cancellable: AnyCancellableInvocation {
    var id: String {
      switch self {
      case .firstCancellable:
        return TestInvocation.first.rawValue
      case .secondCancellable:
        return TestInvocation.second.rawValue
      case .thirdCancellable:
        return TestInvocation.third.rawValue
      case .fourthCancellable:
        return TestInvocation.fourth.rawValue
      }
    }
    
    case firstCancellable
    case secondCancellable
    case thirdCancellable
    case fourthCancellable
  }
}

fileprivate struct MockEffectHandlerFactory: EffectHandlerFactory {
  func effect(
    for invocation: TestInvocation,
    with dependencies: EventEngineDependencies<Void>
  ) -> any EffectHandler<TestEvent> {
    MockEffectHandler()
  }
}

fileprivate struct MockEffectHandler: EffectHandler {
  func performTask(completionBlock: @escaping ([TestEvent]) -> Void) {
    // Added an artificial delay to simulate network latency or other asynchronous computations
    DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 0.35) {
      completionBlock([])
    }
  }
}

fileprivate class StubEffectHandlerFactory: EffectHandlerFactory {
  func effect(
    for invocation: TestInvocation,
    with dependencies: EventEngineDependencies<Void>
  ) -> any EffectHandler<TestEvent> {
    StubEffectHandler()
  }
}

fileprivate class StubEffectHandler: EffectHandler {
  func performTask(completionBlock: @escaping ([TestEvent]) -> Void) {
    completionBlock([.event1, .event3])
  }
}
