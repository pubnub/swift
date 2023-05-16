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
  func testDispatcher_FinishingAllInvocationsNotifiesListener() {
    let onCompleteExpectation = XCTestExpectation(description: "onCompletion")
    onCompleteExpectation.assertForOverFulfill = true
    onCompleteExpectation.expectedFulfillmentCount = 1
            
    let dispatcher = EffectDispatcher(factory: MockEffectHandlerFactory())
    let listener = DispatcherListener<TestEvent>(onAllInvocationsCompleted: {
      onCompleteExpectation.fulfill()
    })
    
    dispatcher.dispatch(
      invocations: [
        .managed(invocation: .first),
        .managed(invocation: .second),
        .managed(invocation: .third),
        .managed(invocation: .fourth)
    ], notify: listener)
    
    wait(for: [onCompleteExpectation], timeout: 3.0)
  }
  
  func testDispatcher_FinishingAnyInvocationNotifiesListenerWithResult() {
    let onResultReceivedExpectation = XCTestExpectation(description: "onResultReceived")
    onResultReceivedExpectation.expectedFulfillmentCount = 4
    onResultReceivedExpectation.assertForOverFulfill = true
        
    let dispatcher = EffectDispatcher(factory: MockEffectHandlerFactory())
    let listener = DispatcherListener<TestEvent>(onAnyInvocationCompleted: { id, events in
      onResultReceivedExpectation.fulfill()
    })
    
    dispatcher.dispatch(
      invocations: [
        .managed(invocation: .first),
        .managed(invocation: .second),
        .managed(invocation: .third),
        .managed(invocation: .fourth)
    ], notify: listener)
    
    wait(for: [onResultReceivedExpectation], timeout: 3.0)
  }
  
  func testDispatcher_CancelInvocationsNotifiesListener() {
    let onCompleteExpectation = XCTestExpectation(description: "onCompletion")
    onCompleteExpectation.assertForOverFulfill = true
    onCompleteExpectation.expectedFulfillmentCount = 1
    
    let dispatcher = EffectDispatcher(factory: MockEffectHandlerFactory())
    let listener = DispatcherListener<TestEvent>(onAllInvocationsCompleted: {
      onCompleteExpectation.fulfill()
    })
    
    dispatcher.dispatch(
      invocations: [
        .cancel(id: TestInvocation.first.rawValue),
        .cancel(id: TestInvocation.second.rawValue),
        .cancel(id: TestInvocation.third.rawValue),
        .cancel(id: TestInvocation.fourth.rawValue)
    ], notify: listener)
    
    wait(for: [onCompleteExpectation], timeout: 3.0)
  }
  
  func testDispatcher_CancelInvocationsWithManagedInvocationsNotifiesListener() {
    let onCompleteExpectation = XCTestExpectation(description: "onCompletion")
    onCompleteExpectation.assertForOverFulfill = true
    onCompleteExpectation.expectedFulfillmentCount = 1
    
    let onResultReceivedExpectation = XCTestExpectation(description: "onResultReceived")
    onResultReceivedExpectation.expectedFulfillmentCount = 2
    onResultReceivedExpectation.assertForOverFulfill = true
    
    let dispatcher = EffectDispatcher(factory: MockEffectHandlerFactory())
    let listener = DispatcherListener<TestEvent>(onAllInvocationsCompleted: {
      onCompleteExpectation.fulfill()
    }, onAnyInvocationCompleted: { id, events in
      onResultReceivedExpectation.fulfill()
    })
    
    dispatcher.dispatch(
      invocations: [
        .cancel(id: TestInvocation.first.rawValue),
        .managed(invocation: TestInvocation.second),
        .cancel(id: TestInvocation.third.rawValue),
        .managed(invocation: TestInvocation.fourth)
    ], notify: listener)
    
    wait(for: [onCompleteExpectation, onResultReceivedExpectation], timeout: 3.0)
  }
  
  func testDispatcher_NotifiesListenerWithExpectedEvents() {
    let dispatcher = EffectDispatcher(factory: StubEffectHandlerFactory())
    let listener = DispatcherListener<TestEvent>(onAnyInvocationCompleted: { id, events in
      XCTAssertEqual(events, [.event1, .event3])
    })
    
    dispatcher.dispatch(
      invocations: [.managed(invocation: TestInvocation.first)],
      notify: listener
    )
  }
  
  func testDispatcher_RemovesPendingEffectsOnFinish() {
    let onCompleteExpectation = XCTestExpectation(description: "onCompletion")
    onCompleteExpectation.assertForOverFulfill = true
    onCompleteExpectation.expectedFulfillmentCount = 1
        
    let dispatcher = EffectDispatcher(factory: MockEffectHandlerFactory())
    let listener = DispatcherListener<TestEvent>(onAllInvocationsCompleted: {
      XCTAssertFalse(dispatcher.hasPendingEffect(with: TestInvocation.first.rawValue))
      XCTAssertFalse(dispatcher.hasPendingEffect(with: TestInvocation.second.rawValue))
      XCTAssertFalse(dispatcher.hasPendingEffect(with: TestInvocation.third.rawValue))
      XCTAssertFalse(dispatcher.hasPendingEffect(with: TestInvocation.fourth.rawValue))
      onCompleteExpectation.fulfill()
    })
    
    dispatcher.dispatch(
      invocations: [
        .managed(invocation: .first),
        .managed(invocation: .second),
        .cancel(id: TestInvocation.third.rawValue),
        .managed(invocation: .fourth)
    ], notify: listener)
    
    wait(for: [onCompleteExpectation], timeout: 3.0)
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
}

fileprivate class MockEffectHandlerFactory: EffectHandlerFactory {
  func effect(for invocation: TestInvocation) -> any EffectHandler<TestEvent> {
    return MockEffectHandler()
  }
}

fileprivate class MockEffectHandler: EffectHandler {  
  func performTask(completionBlock: @escaping ([TestEvent]) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
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
