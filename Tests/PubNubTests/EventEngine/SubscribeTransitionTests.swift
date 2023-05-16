//
//  SubscribeTransitionTests.swift
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

class SubscribeTransitionTests: XCTestCase {
  private let transition = SubscribeTransition()
  private let input = SubscribeInput(channels: ["test-channel"])
    
  // MARK: - Subscription Changed
  
  func test_SubscriptionChangedForUnsubscribedState() throws {
    let results = transition.transition(
      from: Subscribe.UnsubscribedState(input: input),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expHandshakeInv = Subscribe.Invocation.handshakeRequest(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    )
    let expState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    ))
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.HandshakingState) == expState)
    XCTAssertTrue(results.invocations.count == 1)
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expHandshakeInv)))
  }
  
  func test_SubscriptionChangedForHandshakeFailedState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeFailedState(input: input, error: SubscribeError(underlying: PubNubError(.unknown))),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expHandshakeInv = Subscribe.Invocation.handshakeRequest(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    )
    let expState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    ))
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.HandshakingState) == expState)
    XCTAssertTrue(results.invocations.count == 1)
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expHandshakeInv)))
  }
  
  func test_SubscriptionChangedForHandshakeStoppedState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeStoppedState(input: input),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expHandshakeInv = Subscribe.Invocation.handshakeRequest(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    )
    let expState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    ))
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.HandshakingState) == expState)
    XCTAssertTrue(results.invocations.count == 1)
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expHandshakeInv)))
  }
  
  func test_SubscriptionChangedForHandshakeReconnectingState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(input: input, currentAttempt: 1),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expHandshakeInv = Subscribe.Invocation.handshakeRequest(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    )
    let expState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    ))
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.HandshakingState) == expState)
    XCTAssertTrue(results.invocations.count == 2)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.HandshakeReconnect)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expHandshakeInv)))
  }
  
  func test_SubscriptionChangedForReceivingState() throws {
    let results = transition.transition(
      from: Subscribe.ReceivingState(input: input, cursor: SubscribeCursor(timetoken: 5001000, region: 22)),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expHandshakeInv = Subscribe.Invocation.handshakeRequest(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    )
    let expState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    ))
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.HandshakingState) == expState)
    XCTAssertTrue(results.invocations.count == 2)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.ReceiveMessages)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expHandshakeInv)))
  }
  
  func test_SubscriptionChangedForReceiveFailedState() throws {
    let results = transition.transition(
      from: Subscribe.ReceiveFailedState(
        input: input,
        cursor: SubscribeCursor(timetoken: 500100900, region: 11),
        error: SubscribeError(underlying: PubNubError(.unknown))
      ),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expHandshakeInv = Subscribe.Invocation.handshakeRequest(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    )
    let expState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    ))
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.HandshakingState) == expState)
    XCTAssertTrue(results.invocations.count == 1)
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expHandshakeInv)))
  }
  
  func test_SubscriptionChangedForReceiveStoppedState() throws {
    let results = transition.transition(
      from: Subscribe.ReceiveStoppedState(input: input, cursor: SubscribeCursor(timetoken: 500100900, region: 11)),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expHandshakeInv = Subscribe.Invocation.handshakeRequest(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    )
    let expState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    ))
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.HandshakingState) == expState)
    XCTAssertTrue(results.invocations.count == 1)
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expHandshakeInv)))
  }
  
  func test_SubscriptionChangedForReceiveReconnectingState() throws {
    let results = transition.transition(
      from: Subscribe.ReceiveReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 500100900, region: 11),
        currentAttempt: 1
      ),
      event: .subscriptionChanged(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"]
      )
    )
    let expHandshakeInv = Subscribe.Invocation.handshakeRequest(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    )
    let expState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: ["new-channel"],
      groups: ["new-group1", "new-group2"]
    ))
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.HandshakingState) == expState)
    XCTAssertTrue(results.invocations.count == 2)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.ReceiveReconnect)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expHandshakeInv)))
  }
  
  // MARK: - Subscription Restored
  
  func test_SubscriptionRestoredForReceivingState() throws {
    let results = transition.transition(
      from: Subscribe.ReceivingState(input: input, cursor: SubscribeCursor(timetoken: 1500100900, region: 41)),
      event: .subscriptionRestored(
        channels: ["new-channel"],
        gropus: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expReceiveMssgsInv = Subscribe.Invocation.receiveMessages(
      channels: ["new-channel"], groups: ["new-group1", "new-group2"],
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )
    let expState = Subscribe.ReceivingState(
      input: SubscribeInput(channels: ["new-channel"], groups: ["new-group1", "new-group2"]),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.ReceivingState) == expState)
    XCTAssertTrue(results.invocations.count == 2)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.ReceiveMessages)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expReceiveMssgsInv)))
  }
  
  func test_SubscriptionRestoredForReceiveReconnectingState() {
    let results = transition.transition(
      from: Subscribe.ReceiveReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 1500100900, region: 41),
        currentAttempt: 1
      ),
      event: .subscriptionRestored(
        channels: ["new-channel"],
        gropus: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expReceiveMssgsInv = Subscribe.Invocation.receiveMessages(
      channels: ["new-channel"], groups: ["new-group1", "new-group2"],
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )
    let expState = Subscribe.ReceivingState(
      input: SubscribeInput(channels: ["new-channel"], groups: ["new-group1", "new-group2"]),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.ReceivingState) == expState)
    XCTAssertTrue(results.invocations.count == 2)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.ReceiveReconnect)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expReceiveMssgsInv)))
  }
  
  func test_SubscriptionRestoredForReceiveFailedState() {
    let results = transition.transition(
      from: Subscribe.ReceiveFailedState(
        input: input,
        cursor: SubscribeCursor(timetoken: 1500100900, region: 41),
        error: SubscribeError(underlying: PubNubError(.unknown))
      ),
      event: .subscriptionRestored(
        channels: ["new-channel"], gropus: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expReceiveMssgsInv = Subscribe.Invocation.receiveMessages(
      channels: ["new-channel"], groups: ["new-group1", "new-group2"],
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )
    let expState = Subscribe.ReceivingState(
      input: SubscribeInput(channels: ["new-channel"], groups: ["new-group1", "new-group2"]),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.ReceivingState) == expState)
    XCTAssertTrue(results.invocations.count == 1)
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expReceiveMssgsInv)))
  }
  
  func test_SubscriptionRestoredForHandshakingState() {
    let results = transition.transition(
      from: Subscribe.HandshakingState(input: input),
      event: .subscriptionRestored(
        channels: ["new-channel"],
        gropus: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expReceiveMssgsInv = Subscribe.Invocation.receiveMessages(
      channels: ["new-channel"], groups: ["new-group1", "new-group2"],
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )
    let expState = Subscribe.ReceivingState(
      input: SubscribeInput(channels: ["new-channel"], groups: ["new-group1", "new-group2"]),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.ReceivingState) == expState)
    XCTAssertTrue(results.invocations.count == 2)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.HandshakeRequest)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expReceiveMssgsInv)))
  }
  
  func test_SubscriptionRestoredForHandshakeReconnectingState() {
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(input: input, currentAttempt: 1),
      event: .subscriptionRestored(
        channels: ["new-channel"],
        gropus: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expReceiveMssgsInv = Subscribe.Invocation.receiveMessages(
      channels: ["new-channel"], groups: ["new-group1", "new-group2"],
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )
    let expState = Subscribe.ReceivingState(
      input: SubscribeInput(channels: ["new-channel"], groups: ["new-group1", "new-group2"]),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.ReceivingState) == expState)
    XCTAssertTrue(results.invocations.count == 2)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.HandshakeReconnect)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expReceiveMssgsInv)))
  }
  
  func test_SubscriptionRestoredForHandshakeFailedState() {
    let results = transition.transition(
      from: Subscribe.HandshakeFailedState(
        input: input,
        error: SubscribeError(underlying: PubNubError(.unknown))
      ),
      event: .subscriptionRestored(
        channels: ["new-channel"],
        gropus: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expReceiveMssgsInv = Subscribe.Invocation.receiveMessages(
      channels: ["new-channel"], groups: ["new-group1", "new-group2"],
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )
    let expState = Subscribe.ReceivingState(
      input: SubscribeInput(channels: ["new-channel"], groups: ["new-group1", "new-group2"]),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.ReceivingState) == expState)
    XCTAssertTrue(results.invocations.count == 1)
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expReceiveMssgsInv)))
  }
  
  // MARK: - Handshake Success
  
  func test_HandshakeSuccessForHandshakingState() {
    let cursor = SubscribeCursor(timetoken: 1500100900, region: 41)
    let results = transition.transition(
      from: Subscribe.HandshakingState(input: input),
      event: .handshakeSucceess(cursor: cursor)
    )
    
    let expEmitStatusInv = Subscribe.Invocation.emitStatus(status: .connected)
    let expEmitMssgsInv = Subscribe.Invocation.emitMessages(events: [], forCursor: cursor)
    
    let expReceiveMssgsInv = Subscribe.Invocation.receiveMessages(
      channels: input.channels,
      groups: input.groups,
      cursor: SubscribeCursor(timetoken: 1500100900, region: 41)
    )
    let expectedState = Subscribe.ReceivingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 1500100900, region: 41)
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.ReceivingState) == expectedState)
    XCTAssertTrue(results.invocations.count == 4)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.HandshakeRequest)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expEmitStatusInv)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expEmitMssgsInv)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expReceiveMssgsInv)))
  }
  
  // MARK: - Handshake Failure
  
  func test_HandshakeFailureForHandshakingState() {
    let results = transition.transition(
      from: Subscribe.HandshakingState(input: input),
      event: .handshakeFailure(error: SubscribeError(underlying: PubNubError(.unknown)))
    )
    let expReconnectInv = Subscribe.Invocation.handshakeReconnect(
      channels: input.channels,
      groups: input.groups,
      currentAttempt: 0,
      reason: SubscribeError(underlying: PubNubError(.unknown))
    )
    let expState = Subscribe.HandshakeReconnectingState(
      input: input,
      currentAttempt: 0
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.HandshakeReconnectingState) == expState)
    XCTAssertTrue(results.invocations.count == 2)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.HandshakeRequest)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expReconnectInv)))
  }
  
  // MARK: - Handshake Reconnect Success
  
  func test_HandshakeReconnectSuccessForReconnectingState() {
    let cursor = SubscribeCursor(timetoken: 200400600, region: 45)
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(input: input, currentAttempt: 1),
      event: .handshakeReconnectSuccess(cursor: cursor)
    )
    
    let expEmitStatusInv = Subscribe.Invocation.emitStatus(status: .connected)
    let expEmitMssgsInv = Subscribe.Invocation.emitMessages(events: [], forCursor: cursor)
    
    let expReceiveMssgsInv = Subscribe.Invocation.receiveMessages(
      channels: input.channels,
      groups: input.groups,
      cursor: SubscribeCursor(timetoken: 200400600, region: 45)
    )
    let expState = Subscribe.ReceivingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 200400600, region: 45)
    )

    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.ReceivingState) == expState)
    XCTAssertTrue(results.invocations.count == 4)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.HandshakeReconnect)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expEmitStatusInv)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expEmitMssgsInv)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expReceiveMssgsInv)))
  }
  
  // MARK: - Handshake Reconnect Failure
  
  func test_HandshakeReconnectFailureForReconnectingState() {
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(input: input, currentAttempt: 0),
      event: .handshakeReconnectFailure(error: SubscribeError(underlying: PubNubError(.unknown)))
    )
    let expHandshakeReconnectingInv = Subscribe.Invocation.handshakeReconnect(
      channels: input.channels, groups: input.groups,
      currentAttempt: 1, reason: SubscribeError(underlying: PubNubError(.unknown))
    )
    let expState = Subscribe.HandshakeReconnectingState(
      input: input,
      currentAttempt: 1
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.HandshakeReconnectingState) == expState)
    XCTAssertTrue(results.invocations.count == 2)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.HandshakeReconnect)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expHandshakeReconnectingInv)))
  }
  
  // MARK: - Handshake Give Up
  
  func test_HandshakeGiveUpForReconnectingState() {
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(input: input, currentAttempt: 3),
      event: .handshakeReconnectGiveUp(error: SubscribeError(underlying: PubNubError(.unknown)))
    )
    let expState = Subscribe.HandshakeFailedState(
      input: input,
      error: SubscribeError(underlying: PubNubError(.unknown))
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.HandshakeFailedState) == expState)
    XCTAssertTrue(results.invocations.count == 1)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.HandshakeReconnect)))
  }
  
  // MARK: - Receive Give Up
  
  func test_ReceiveGiveUpForReconnectingState() {
    let results = transition.transition(
      from: Subscribe.ReceiveReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 18001000, region: 123), currentAttempt: 3
      ),
      event: .receiveReconnectGiveUp(error: SubscribeError(underlying: PubNubError(.unknown)))
    )
    let expState = Subscribe.ReceiveFailedState(
      input: input,
      cursor: SubscribeCursor(timetoken: 18001000, region: 123),
      error: SubscribeError(underlying: PubNubError(.unknown))
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.ReceiveFailedState) == expState)
    XCTAssertTrue(results.invocations.count == 1)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.ReceiveReconnect)))
  }
  
  // MARK: - Receiving With Messages
  
  func test_ReceivingStateWithMessages() {
    let results = transition.transition(
      from: Subscribe.ReceivingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 18001000, region: 123)
      ),
      event: .receiveSuccess(
        cursor: SubscribeCursor(timetoken: 18002000, region: 123),
        messages: [firstMessage, secondMessage]
      )
    )
    let expEmitMssgsInv = Subscribe.Invocation.emitMessages(
      events: [firstMessage, secondMessage],
      forCursor: SubscribeCursor(timetoken: 18002000, region: 123)
    )    
    let expReceiveMssgsInv = Subscribe.Invocation.receiveMessages(
      channels: input.channels,
      groups: input.groups,
      cursor: SubscribeCursor(timetoken: 18002000, region: 123)
    )
    let expState = Subscribe.ReceivingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 18002000, region: 123)
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.ReceivingState) == expState)
    XCTAssertTrue(results.invocations.count == 4)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.ReceiveMessages)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: .emitStatus(status: .connected))))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expEmitMssgsInv)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expReceiveMssgsInv)))
  }
  
  // MARK: - Receive Failed
  
  func test_ReceiveFailedFromReceivingState() {
    let results = transition.transition(
      from: Subscribe.ReceivingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 100500900, region: 11)
      ),
      event: .receiveFailure(error: SubscribeError(underlying: PubNubError(.unknown)))
    )
    let expReconnectInv = Subscribe.Invocation.receiveReconnect(
      channels: input.channels,
      group: input.groups,
      cursor: SubscribeCursor(timetoken: 100500900, region: 11),
      currentAttempt: 0,
      reason: SubscribeError(underlying: PubNubError(.unknown))
    )
    let expState = Subscribe.ReceiveReconnectingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 100500900, region: 11),
      currentAttempt: 0
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.ReceiveReconnectingState) == expState)
    XCTAssertTrue(results.invocations.count == 2)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.ReceiveMessages)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expReconnectInv)))
  }
  
  func test_ReceiveFailedFromReceiveReconnectingState() {
    let results = transition.transition(
      from: Subscribe.ReceiveReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 100500900, region: 11),
        currentAttempt: 1
      ),
      event: .receiveFailure(error: SubscribeError(underlying: PubNubError(.unknown)))
    )
    let expReconnectInv = Subscribe.Invocation.receiveReconnect(
      channels: input.channels,
      group: input.groups,
      cursor: SubscribeCursor(timetoken: 100500900, region: 11),
      currentAttempt: 2,
      reason: SubscribeError(underlying: PubNubError(.unknown))
    )
    let expState = Subscribe.ReceiveReconnectingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 100500900, region: 11),
      currentAttempt: 2
    )
    
    XCTAssertTrue(try XCTUnwrap(results.state as? Subscribe.ReceiveReconnectingState) == expState)
    XCTAssertTrue(results.invocations.count == 2)
    XCTAssertTrue(results.invocations.contains(.cancel(id: Subscribe.Invocation.ID.ReceiveReconnect)))
    XCTAssertTrue(results.invocations.contains(.managed(invocation: expReconnectInv)))
  }
}

fileprivate let firstMessage = SubscribeMessagePayload(
  shard: "",
  subscription: nil,
  channel: "test-channel",
  messageType: .message,
  payload: ["message": "hello!"],
  flags: 123,
  publisher: "publisher",
  subscribeKey: "FakeKey",
  originTimetoken: nil,
  publishTimetoken: SubscribeCursor(timetoken: 12312412412, region: 12),
  meta: nil
)

fileprivate let secondMessage = SubscribeMessagePayload(
  shard: "",
  subscription: nil,
  channel: "test-channel",
  messageType: .messageAction,
  payload: ["reaction": "👍"],
  flags: 456,
  publisher: "second-publisher",
  subscribeKey: "FakeKey",
  originTimetoken: nil,
  publishTimetoken: SubscribeCursor(timetoken: 12312412555, region: 12),
  meta: nil
)
