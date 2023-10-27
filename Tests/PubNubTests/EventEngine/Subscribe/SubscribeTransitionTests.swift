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

extension SubscribeState {
  func isEqual(to otherState: some SubscribeState) -> Bool {
    (otherState as? Self) == self
  }
}

extension Subscribe.Invocation : Equatable {
  public static func ==(lhs: Subscribe.Invocation, rhs: Subscribe.Invocation) -> Bool {
    switch (lhs, rhs) {
    case let (.handshakeRequest(lC, lG), .handshakeRequest(rC, rG)):
      return lC.sorted(by: <) == rC.sorted(by: <) && lG.sorted(by: <) == rG.sorted(by: <)
    case let (.handshakeReconnect(lC, lG, lAtt, lErr),.handshakeReconnect(rC, rG, rAtt, rErr)):
      return lC.sorted(by: <) == rC.sorted(by: <) && lG.sorted(by: <) == rG.sorted(by: <) && lAtt == rAtt && lErr == rErr
    case let (.receiveMessages(lC, lG, lCrsr),.receiveMessages(rC, rG, rCrsr)):
      return lC.sorted(by: <) == rC.sorted(by: <) && lG.sorted(by: <) == rG.sorted(by: <) && lCrsr == rCrsr
    case let (.receiveReconnect(lC, lG, lCrsr, lAtt, lErr), .receiveReconnect(rC, rG, rCrsr, rAtt, rErr)):
      return lC.sorted(by: <) == rC.sorted(by: <) && lG.sorted(by: <) == rG.sorted(by: <) && lCrsr == rCrsr && lAtt == rAtt && lErr == rErr
    case let (.emitStatus(lhsChange), .emitStatus(rhsChange)):
      return lhsChange == rhsChange
    case let (.emitMessages(lhsMssgs, lhsCrsr), .emitMessages(rhsMssgs, rhsCrsr)):
      return lhsMssgs == rhsMssgs && lhsCrsr == rhsCrsr
    default:
      return false
    }
  }
}

extension Subscribe.Event: Equatable {  
  public static func == (lhs: Subscribe.Event, rhs: Subscribe.Event) -> Bool {
    switch (lhs, rhs) {
    case let (.subscriptionChanged(lC, lG), .subscriptionChanged(rC, rG)):
      return lC.sorted(by: <) == rC.sorted(by: <) && lG.sorted(by: <) == rG.sorted(by: <)
    case let (.subscriptionRestored(lC, lG, lCursor), .subscriptionRestored(rC, rG, rCursor)):
      return lC.sorted(by: <) == rC.sorted(by: <) && lG.sorted(by: <) == rG.sorted(by: <) && lCursor == rCursor
    case let (.handshakeSuccess(lCursor), .handshakeSuccess(rCursor)):
      return lCursor == rCursor
    case let (.handshakeReconnectSuccess(lCursor), .handshakeReconnectSuccess(rCursor)):
      return lCursor == rCursor
    case let (.handshakeFailure(lError), .handshakeFailure(rError)):
      return lError == rError
    case let (.handshakeReconnectFailure(lError), .handshakeReconnectFailure(rError)):
      return lError == rError
    case let (.handshakeReconnectGiveUp(lError), .handshakeReconnectGiveUp(rError)):
      return lError == rError
    case let (.receiveSuccess(lCursor, lMssgs), .receiveSuccess(rCursor, rMssgs)):
      return lCursor == rCursor && lMssgs == rMssgs
    case let (.receiveFailure(lError), .receiveFailure(rError)):
      return lError == rError
    case let (.receiveReconnectSuccess(lCursor, lMssgs), .receiveReconnectSuccess(rCursor, rMssgs)):
      return lCursor == rCursor && lMssgs == rMssgs
    case let (.receiveReconnectFailure(lError), .receiveReconnectFailure(rError)):
      return lError == rError
    case let (.receiveReconnectGiveUp(lError), .receiveReconnectGiveUp(rError)):
      return lError == rError
    case (.disconnect, .disconnect):
      return true
    case (.reconnect, .reconnect):
      return true
    case (.unsubscribeAll, .unsubscribeAll):
      return true
    default:
      return false
    }
  }
}

class SubscribeTransitionTests: XCTestCase {
  private let transition = SubscribeTransition()
  private let input = SubscribeInput(channels: [PubNubChannel(channel: "test-channel")])
    
  // MARK: - Subscription Changed
  
  func test_SubscriptionChangedForUnsubscribedState() throws {
    let results = transition.transition(
      from: Subscribe.UnsubscribedState(),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: [PubNubChannel(id: "new-channel")],
      groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
    ), cursor: SubscribeCursor(timetoken: 0)!)
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_SubscriptionChangedForHandshakeFailedState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeFailedState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        error: SubscribeError(underlying: PubNubError(.unknown))
      ),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: [PubNubChannel(id: "new-channel")],
      groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
    ), cursor: SubscribeCursor(timetoken: 0, region: 0))
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_SubscriptionChangedForHandshakeStoppedState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeStoppedState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expectedState = Subscribe.HandshakeStoppedState(input: SubscribeInput(
      channels: [PubNubChannel(id: "new-channel")],
      groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
    ), cursor: SubscribeCursor(timetoken: 0, region: 0))
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.isEmpty)
  }
  
  func test_SubscriptionChangedForHandshakeReconnectingState() throws {
    let reason = SubscribeError(
      underlying: PubNubError(.unknown)
    )
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        retryAttempt: 1, reason: reason
      ),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .managed(.handshakeRequest(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: [PubNubChannel(id: "new-channel")],
      groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
    ), cursor: SubscribeCursor(timetoken: 0, region: 0))
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_SubscriptionChangedForHandshakingState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakingState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeRequest),
      .managed(.handshakeRequest(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: [PubNubChannel(id: "new-channel")],
      groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
    ), cursor: SubscribeCursor(timetoken: 0, region: 0))
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_SubscriptionChangedForReceivingState() throws {
    let results = transition.transition(
      from: Subscribe.ReceivingState(input: input, cursor: SubscribeCursor(timetoken: 5001000, region: 22)),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveMessages),
      .managed(.receiveMessages(
        channels: ["new-channel"], groups: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 5001000, region: 22)
      ))
    ]
    let expectedState = Subscribe.ReceivingState(
      input: SubscribeInput(
        channels: [PubNubChannel(id: "new-channel")],
        groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
      ), cursor: SubscribeCursor(
        timetoken: 5001000,
        region: 22
      )
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
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
    
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(
        channels: [PubNubChannel(id: "new-channel")],
        groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
      ), cursor: SubscribeCursor(timetoken: 500100900, region: 11)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  func test_SubscriptionChangedForReceiveStoppedState() throws {
    let results = transition.transition(
      from: Subscribe.ReceiveStoppedState(input: input, cursor: SubscribeCursor(timetoken: 500100900, region: 11)),
      event: .subscriptionChanged(channels: ["new-channel"], groups: ["new-group1", "new-group2"])
    )
    let expectedState = Subscribe.ReceiveStoppedState(
      input: SubscribeInput(
        channels: [PubNubChannel(id: "new-channel")],
        groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
      ), cursor: SubscribeCursor(
        timetoken: 500100900,
        region: 11
      )
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.isEmpty)
  }

  func test_SubscriptionChangedForReceiveReconnectingState() throws {
    let results = transition.transition(
      from: Subscribe.ReceiveReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 500100900, region: 11),
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(.unknown))
      ),
      event: .subscriptionChanged(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"]
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveReconnect),
      .managed(.receiveMessages(
        channels: ["new-channel"], groups: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 500100900, region: 11)
      ))
    ]
    let expectedState = Subscribe.ReceivingState(
      input: SubscribeInput(
        channels: [PubNubChannel(id: "new-channel")],
        groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
      ), cursor: SubscribeCursor(
        timetoken: 500100900,
        region: 11
      )
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  // MARK: - Subscription Restored

  func test_SubscriptionRestoredForReceivingState() throws {
    let results = transition.transition(
      from: Subscribe.ReceivingState(input: input, cursor: SubscribeCursor(timetoken: 1500100900, region: 41)),
      event: .subscriptionRestored(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveMessages),
      .managed(.receiveMessages(
        channels: ["new-channel"], groups: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      ))
    ]
    let expectedState = Subscribe.ReceivingState(
      input: SubscribeInput(
        channels: [PubNubChannel(id: "new-channel")],
        groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
      ),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  func test_SubscriptionRestoredForReceiveReconnectingState() {
    let results = transition.transition(
      from: Subscribe.ReceiveReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 1500100900, region: 41),
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(.unknown))
      ),
      event: .subscriptionRestored(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveReconnect),
      .managed(.receiveMessages(
        channels: ["new-channel"], groups: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      ))
    ]
    let expectedState = Subscribe.ReceivingState(
      input: SubscribeInput(
        channels: [PubNubChannel(id: "new-channel")],
        groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
      ),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  func test_SubscriptionRestoredForReceiveFailedState() {
    let results = transition.transition(
      from: Subscribe.ReceiveFailedState(
        input: input,
        cursor: SubscribeCursor(timetoken: 1500100900, region: 41),
        error: SubscribeError(underlying: PubNubError(.unknown))
      ),
      event: .subscriptionRestored(
        channels: ["new-channel"], groups: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(
        channels: [PubNubChannel(id: "new-channel")],
        groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
      ), cursor: SubscribeCursor(timetoken: 100, region: 55)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_SubscriptionRestoredForReceiveStoppedState() {
    let results = transition.transition(
      from: Subscribe.ReceiveStoppedState(
        input: input,
        cursor: SubscribeCursor(timetoken: 99, region: 9)
      ),
      event: .subscriptionRestored(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedState = Subscribe.ReceiveStoppedState(
      input: SubscribeInput(
        channels: [PubNubChannel(id: "new-channel")],
        groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
      ),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.isEmpty)
  }

  func test_SubscriptionRestoredForHandshakingState() {
    let results = transition.transition(
      from: Subscribe.HandshakingState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .subscriptionRestored(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeRequest),
      .managed(.handshakeRequest(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(
        channels: [PubNubChannel(id: "new-channel")],
        groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
      ),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  func test_SubscriptionRestoredForHandshakeReconnectingState() {
    let reason = SubscribeError(
      underlying: PubNubError(.unknown)
    )
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        retryAttempt: 1, reason: reason
      ),
      event: .subscriptionRestored(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .managed(.handshakeRequest(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(
        channels: [PubNubChannel(id: "new-channel")],
        groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
      ),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  func test_SubscriptionRestoredForHandshakeFailedState() {
    let results = transition.transition(
      from: Subscribe.HandshakeFailedState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        error: SubscribeError(underlying: PubNubError(.unknown))
      ),
      event: .subscriptionRestored(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(
        channels: [PubNubChannel(id: "new-channel")],
        groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
      ), cursor: SubscribeCursor(timetoken: 100, region: 55)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_SubscriptionRestoredForHandshakeStoppedState() {
    let results = transition.transition(
      from: Subscribe.HandshakeStoppedState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .subscriptionRestored(
        channels: ["new-channel"],
        groups: ["new-group1", "new-group2"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedState = Subscribe.HandshakeStoppedState(
      input: SubscribeInput(
        channels: [PubNubChannel(id: "new-channel")],
        groups: [PubNubChannel(id: "new-group1"), PubNubChannel(id: "new-group2")]
      ),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.isEmpty)
  }
  
  // MARK: - Handshake Success

  func test_HandshakeSuccessForHandshakingState() {
    let cursor = SubscribeCursor(
      timetoken: 1500100900,
      region: 41
    )
    let results = transition.transition(
      from: Subscribe.HandshakingState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .handshakeSuccess(cursor: cursor)
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeRequest),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .connected,
        error: nil
      ))),
      .managed(.receiveMessages(channels: input.allSubscribedChannels,
        groups: input.allSubscribedGroups,
        cursor: cursor
      ))
    ]
    let expectedState = Subscribe.ReceivingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 1500100900, region: 41)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  // MARK: - Handshake Failure

  func test_HandshakeFailureForHandshakingState() {
    let results = transition.transition(
      from: Subscribe.HandshakingState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .handshakeFailure(error: SubscribeError(underlying: PubNubError(.unknown)))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeRequest),
      .managed(.handshakeReconnect(
        channels: input.allSubscribedChannels,
        groups: input.allSubscribedGroups,
        retryAttempt: 0,
        reason: SubscribeError(underlying: PubNubError(.unknown))
      ))
    ]
    let expectedState = Subscribe.HandshakeReconnectingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 0, region: 0),
      retryAttempt: 0,
      reason: SubscribeError(underlying: PubNubError(.unknown))
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  // MARK: - Handshake Reconnect Success

  func test_HandshakeReconnectSuccessForReconnectingState() {
    let reason = SubscribeError(
      underlying: PubNubError(.unknown)
    )
    let cursor = SubscribeCursor(
      timetoken: 200400600,
      region: 45
    )
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        retryAttempt: 1, reason: reason
      ),
      event: .handshakeReconnectSuccess(cursor: cursor)
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .connected,
        error: nil
      ))),
      .managed(.receiveMessages(
        channels: input.allSubscribedChannels,
        groups: input.allSubscribedGroups,
        cursor: SubscribeCursor(timetoken: 200400600, region: 45)
      ))
    ]
    let expectedState = Subscribe.ReceivingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 200400600, region: 45)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  // MARK: - Handshake Reconnect Failure

  func test_HandshakeReconnectFailedForReconnectingState() {
    let reason = SubscribeError(
      underlying: PubNubError(.unknown)
    )
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        retryAttempt: 0,
        reason: reason
      ),
      event: .handshakeReconnectFailure(error: SubscribeError(underlying: PubNubError(.unknown)))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .managed(.handshakeReconnect(
        channels: input.allSubscribedChannels, groups: input.allSubscribedGroups,
        retryAttempt: 1, reason: SubscribeError(underlying: PubNubError(.unknown))
      ))
    ]
    let expectedState = Subscribe.HandshakeReconnectingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 0, region: 0),
      retryAttempt: 1,
      reason: reason
    )
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  // MARK: - Handshake Give Up

  func test_HandshakeGiveUpForReconnectingState() {
    let reason = SubscribeError(
      underlying: PubNubError(.unknown)
    )
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        retryAttempt: 3,
        reason: reason
      ),
      event: .handshakeReconnectGiveUp(error: SubscribeError(underlying: PubNubError(.unknown)))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .connectionError,
        error: SubscribeError(underlying: PubNubError(.unknown))
      )))
    ]
    let expectedState = Subscribe.HandshakeFailedState(
      input: input,
      cursor: SubscribeCursor(timetoken: 0, region: 0),
      error: SubscribeError(underlying: PubNubError(.unknown))
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  // MARK: - Receive Give Up

  func test_ReceiveGiveUpForReconnectingState() {
    let reason = SubscribeError(
      underlying: PubNubError(.unknown)
    )
    let results = transition.transition(
      from: Subscribe.ReceiveReconnectingState(
        input: input, cursor: SubscribeCursor(timetoken: 18001000, region: 123),
        retryAttempt: 3, reason: reason
      ),
      event: .receiveReconnectGiveUp(error: SubscribeError(underlying: PubNubError(.unknown)))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveReconnect),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connected,
        newStatus: .disconnectedUnexpectedly,
        error: SubscribeError(underlying: PubNubError(.unknown))
      )))
    ]
    let expectedState = Subscribe.ReceiveFailedState(
      input: input,
      cursor: SubscribeCursor(timetoken: 18001000, region: 123),
      error: SubscribeError(underlying: PubNubError(.unknown))
    )
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
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
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveMessages),
      .managed(.emitMessages(
        events: [firstMessage, secondMessage],
        forCursor: SubscribeCursor(timetoken: 18002000, region: 123)
      )),
      .managed(.receiveMessages(
        channels: input.allSubscribedChannels,
        groups: input.allSubscribedGroups,
        cursor: SubscribeCursor(timetoken: 18002000, region: 123)
      ))
    ]
    let expectedState = Subscribe.ReceivingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 18002000, region: 123)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  // MARK: - Receive Failed

  func test_ReceiveFailedForReceivingState() {
    let reason = SubscribeError(
      underlying: PubNubError(.unknown)
    )
    let results = transition.transition(
      from: Subscribe.ReceivingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 100500900, region: 11)
      ),
      event: .receiveFailure(error: SubscribeError(underlying: PubNubError(.unknown)))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveMessages),
      .managed(.receiveReconnect(
        channels: input.allSubscribedChannels,
        groups: input.allSubscribedGroups,
        cursor: SubscribeCursor(timetoken: 100500900, region: 11),
        retryAttempt: 0,
        reason: SubscribeError(underlying: PubNubError(.unknown))
      ))
    ]
    let expectedState = Subscribe.ReceiveReconnectingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 100500900, region: 11),
      retryAttempt: 0,
      reason: reason
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  func test_ReceiveReconnectFailedForReconnectingState() {
    let reason = SubscribeError(
      underlying: PubNubError(.unknown)
    )
    let results = transition.transition(
      from: Subscribe.ReceiveReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 100500900, region: 11),
        retryAttempt: 1,
        reason: reason
      ),
      event: .receiveReconnectFailure(error: SubscribeError(underlying: PubNubError(.unknown)))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveReconnect),
      .managed(.receiveReconnect(
        channels: input.allSubscribedChannels,
        groups: input.allSubscribedGroups,
        cursor: SubscribeCursor(timetoken: 100500900, region: 11),
        retryAttempt: 2,
        reason: SubscribeError(underlying: PubNubError(.unknown))
      ))
    ]
    let expectedState = Subscribe.ReceiveReconnectingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 100500900, region: 11),
      retryAttempt: 2,
      reason: reason
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  // MARK: - Reconnect
  
  func test_ReconnectForHandshakeStoppedState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeStoppedState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .reconnect
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: input.allSubscribedChannels,
        groups: input.allSubscribedGroups)
      )
    ]
    let expectedState = Subscribe.HandshakingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 0, region: 0)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_ReconnectForHandshakeFailedState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeFailedState(
        input: input, cursor: SubscribeCursor(timetoken: 0, region: 0),
        error: SubscribeError(underlying: PubNubError(.unknown))
      ),
      event: .reconnect
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: input.allSubscribedChannels,
        groups: input.allSubscribedGroups
      ))
    ]
    let expectedState = Subscribe.HandshakingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 0, region: 0)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_ReconnectForReceiveStoppedState() throws {
    let results = transition.transition(
      from: Subscribe.ReceiveStoppedState(
        input: input,
        cursor: SubscribeCursor(timetoken: 123, region: 456)
      ),
      event: .reconnect
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: input.allSubscribedChannels,
        groups: input.allSubscribedGroups
      ))
    ]
    let expectedState = Subscribe.HandshakingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 123, region: 456)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_ReconnectForReceiveFailedState() throws {
    let results = transition.transition(
      from: Subscribe.ReceiveFailedState(
        input: input,
        cursor: SubscribeCursor(timetoken: 123, region: 456),
        error: SubscribeError(underlying: PubNubError(.unknown))
      ),
      event: .reconnect
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: input.allSubscribedChannels,
        groups: input.allSubscribedGroups
      ))
    ]
    let expectedState = Subscribe.HandshakingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 123, region: 456)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  // MARK: - Disconnect
  
  func test_DisconnectForHandshakingState() {
    let results = transition.transition(
      from: Subscribe.HandshakingState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .disconnect
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeRequest),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let expectedState = Subscribe.HandshakeStoppedState(
      input: input,
      cursor: SubscribeCursor(timetoken: 0, region: 0)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_DisconnectForHandshakeReconnectingState() {
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(.unknown))
      ),
      event: .disconnect
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let expectedState = Subscribe.HandshakeStoppedState(
      input: input,
      cursor: SubscribeCursor(timetoken: 0, region: 0)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_DisconnectForReceivingState() {
    let results = transition.transition(
      from: Subscribe.ReceivingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 123, region: 456)
      ),
      event: .disconnect
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveMessages),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connected,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let expectedState = Subscribe.ReceiveStoppedState(
      input: input,
      cursor: SubscribeCursor(timetoken: 123, region: 456)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_DisconnectForReceiveReconnectingState() {
    let results = transition.transition(
      from: Subscribe.ReceiveReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 123, region: 456),
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(.unknown))
      ),
      event: .disconnect
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveReconnect),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connected,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let expectedState = Subscribe.ReceiveStoppedState(
      input: input,
      cursor: SubscribeCursor(timetoken: 123, region: 456)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  // MARK: - Unsubscribe All
  
  func testUnsubscribeAll_ForHandshakingState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakingState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeRequest),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let expectedState = Subscribe.UnsubscribedState()

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testUnsubscribeAll_ForHandshakeReconnectingState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(.badRequest))
      ),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let expectedState = Subscribe.UnsubscribedState()

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testUnsubscribeAll_ForHandshakeFailedState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeFailedState(
        input: input, cursor: SubscribeCursor(timetoken: 0, region: 0),
        error: SubscribeError(underlying: PubNubError(.badRequest))
      ),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let expectedState = Subscribe.UnsubscribedState()

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testUnsubscribeAll_ForHandshakeStoppedState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeStoppedState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let expectedState = Subscribe.UnsubscribedState()

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_UnsubscribeAllForReceivingState() throws {
    let results = transition.transition(
      from: Subscribe.ReceivingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 123, region: 456)
      ),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveMessages),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connected,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let expectedState = Subscribe.UnsubscribedState()

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_UnsubscribeAllForReceiveReconnectingState() throws {
    let results = transition.transition(
      from: Subscribe.ReceiveReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 123, region: 456),
        retryAttempt: 1,
        reason: SubscribeError(underlying: PubNubError(.badRequest))
      ),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveReconnect),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connected,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let expectedState = Subscribe.UnsubscribedState()

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_UnsubscribeAllForReceiveFailedState() throws {
    let results = transition.transition(
      from: Subscribe.ReceiveFailedState(
        input: input,
        cursor: SubscribeCursor(timetoken: 123, region: 456),
        error: SubscribeError(underlying: PubNubError(.badRequest))
      ),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let expectedState = Subscribe.UnsubscribedState()

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_UnsubscribeAllForReceiveStoppedState() throws {
    let results = transition.transition(
      from: Subscribe.ReceiveStoppedState(
        input: input,
        cursor: SubscribeCursor(timetoken: 123, region: 456)
      ),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let expectedState = Subscribe.UnsubscribedState()

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
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
