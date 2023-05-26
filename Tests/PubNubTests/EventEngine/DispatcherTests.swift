//
//  DispatcherTests.swift
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
import XCTest

@testable import PubNub

class DispatcherTests: XCTestCase {
  func testDispatcher_FinishingAnyInvocationNotifiesListener() {
    let onResultReceivedExpectation = XCTestExpectation(description: "onResultReceived")
    onResultReceivedExpectation.expectedFulfillmentCount = 4
    onResultReceivedExpectation.assertForOverFulfill = true
        
    let queue = DispatchQueue.global(qos: .default)
    let dispatcher = EffectDispatcher(factory: MockEffectHandlerFactory(queue: queue))
    let listener = DispatcherListener<TestEvent>(onAnyInvocationCompleted: { _ in
      onResultReceivedExpectation.fulfill()
    })
    
    dispatcher.dispatch(
      invocations: [
        .managed(invocation: .first),
        .managed(invocation: .second),
        .managed(invocation: .third),
        .managed(invocation: .fourth)
    ], notify: listener)
    
    wait(for: [onResultReceivedExpectation], timeout: 1.0)
  }
  
  func testDispatcher_CancelInvocationsWithManagedInvocationsNotifiesListener() {
    let onResultReceivedExpectation = XCTestExpectation(description: "onResultReceived")
    onResultReceivedExpectation.expectedFulfillmentCount = 2
    onResultReceivedExpectation.assertForOverFulfill = true
    
    let queue = DispatchQueue.global(qos: .default)
    let dispatcher = EffectDispatcher(factory: MockEffectHandlerFactory(queue: queue))
    let listener = DispatcherListener<TestEvent>(onAnyInvocationCompleted: { _ in
      onResultReceivedExpectation.fulfill()
    })
    
    dispatcher.dispatch(
      invocations: [
        .cancel(invocation: .firstCancellable),
        .managed(invocation: .second),
        .cancel(invocation: .thirdCancellable),
        .managed(invocation: .fourth)
    ], notify: listener)
    
    wait(for: [onResultReceivedExpectation], timeout: 1.0)
  }
  
  func testDispatcher_NotifiesListenerWithExpectedEvents() {
    let dispatcher = EffectDispatcher(factory: StubEffectHandlerFactory())
    let listener = DispatcherListener<TestEvent>(onAnyInvocationCompleted: { events in
      XCTAssertEqual(events, [.event1, .event3])
    })
    
    dispatcher.dispatch(
      invocations: [.managed(invocation: TestInvocation.first)],
      notify: listener
    )
  }
  
  func testDispatcher_RemovesPendingEffectsOnFinish() {
    let onResultReceivedExpectation = XCTestExpectation(description: "onResultReceived")
    onResultReceivedExpectation.expectedFulfillmentCount = 3
    onResultReceivedExpectation.assertForOverFulfill = true

    let queue = DispatchQueue.global(qos: .default)
    let dispatcher = EffectDispatcher(factory: MockEffectHandlerFactory(queue: queue))
    let semaphore = DispatchSemaphore(value: 2)

    let listener = DispatcherListener<TestEvent>(onAnyInvocationCompleted: { results in
      semaphore.signal()
    })
        
    dispatcher.dispatch(
      invocations: [
        .managed(invocation: .first),
        .managed(invocation: .second),
        .cancel(invocation: .thirdCancellable),
        .managed(invocation: .fourth)
    ], notify: listener)
    
    _ = semaphore.wait(timeout: .now() + 1)
    _ = semaphore.wait(timeout: .now() + 1)
    _ = semaphore.wait(timeout: .now() + 1)

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
  
  enum Cancellable: String {
    case firstCancellable = "first"
    case secondCancellable = "second"
    case thirdCancellable = "third"
    case fourthCancellable = "fourth"
  }
}

fileprivate struct MockEffectHandlerFactory: EffectHandlerFactory {
  let queue: DispatchQueue
  
  func effect(for invocation: TestInvocation) -> any EffectHandler<TestEvent> {
    return MockEffectHandler(queue: queue)
  }
}

fileprivate struct MockEffectHandler: EffectHandler {
  let queue: DispatchQueue
  
  func performTask(completionBlock: @escaping ([TestEvent]) -> Void) {
    // Added an artificial delay to simulate network latency or other asynchronous computations
    queue.asyncAfter(deadline: .now() + 0.35) {
      completionBlock([])
    }
  }
}

fileprivate class StubEffectHandlerFactory: EffectHandlerFactory {
  func effect(for invocation: TestInvocation) -> any EffectHandler<TestEvent> {
    return StubEffectHandler()
  }
}

fileprivate class StubEffectHandler: EffectHandler {
  func performTask(completionBlock: @escaping ([TestEvent]) -> Void) {
    completionBlock([.event1, .event3])
  }
}
