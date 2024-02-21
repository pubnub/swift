//
//  SubscribeTransitionTests.swift
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
      event: .subscriptionChanged(
        channels: ["c1", "c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2", "g2-pnpres", "g3"]
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3"]
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: expectedChannels,
      groups: expectedGroups
    ), cursor: SubscribeCursor(timetoken: 0)!)
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_SubscriptionChangedForHandshakeFailedState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeFailedState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        error: PubNubError(.unknown)
      ),
      event: .subscriptionChanged(
        channels: ["c1", "c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2", "g2-pnpres", "g3"]
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3"]
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: expectedChannels,
      groups: expectedGroups
    ), cursor: SubscribeCursor(timetoken: 0, region: 0))
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_SubscriptionChangedForHandshakeStoppedState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeStoppedState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .subscriptionChanged(
        channels: ["c1", "c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2", "g2-pnpres", "g3"]
      )
    )
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedState = Subscribe.HandshakeStoppedState(input: SubscribeInput(
      channels: expectedChannels,
      groups: expectedGroups
    ), cursor: SubscribeCursor(timetoken: 0, region: 0))
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.isEmpty)
  }
  
  func test_SubscriptionChangedForHandshakeReconnectingState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        retryAttempt: 1,
        reason: PubNubError(.unknown)
      ),
      event: .subscriptionChanged(
        channels: ["c1", "c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2", "g2-pnpres", "g3"]
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3"]
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: expectedChannels,
      groups: expectedGroups
    ), cursor: SubscribeCursor(timetoken: 0, region: 0))
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_SubscriptionChangedForHandshakingState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakingState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .subscriptionChanged(
        channels: ["c1", "c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2", "g2-pnpres", "g3"]
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeRequest),
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3"]
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedState = Subscribe.HandshakingState(input: SubscribeInput(
      channels: expectedChannels,
      groups: expectedGroups
    ), cursor: SubscribeCursor(timetoken: 0, region: 0))
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_SubscriptionChangedForReceivingState() throws {
    let results = transition.transition(
      from: Subscribe.ReceivingState(input: input, cursor: SubscribeCursor(timetoken: 5001000, region: 22)),
      event: .subscriptionChanged(
        channels: ["c1", "c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2", "g2-pnpres", "g3"]
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveMessages),
      .managed(.receiveMessages(
        channels: ["c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3"],
        cursor: SubscribeCursor(timetoken: 5001000, region: 22)
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedState = Subscribe.ReceivingState(
      input: SubscribeInput(
        channels: expectedChannels,
        groups: expectedGroups
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
        error: PubNubError(.unknown)
      ),
      event: .subscriptionChanged(
        channels: ["c1", "c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2", "g2-pnpres", "g3"]
      )
    )
    
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3"]
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(
        channels: expectedChannels,
        groups: expectedGroups
      ), cursor: SubscribeCursor(timetoken: 500100900, region: 11)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  func test_SubscriptionChangedForReceiveStoppedState() throws {
    let results = transition.transition(
      from: Subscribe.ReceiveStoppedState(input: input, cursor: SubscribeCursor(timetoken: 500100900, region: 11)),
      event: .subscriptionChanged(
        channels: ["c1", "c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2", "g2-pnpres", "g3"]
      )
    )
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedState = Subscribe.ReceiveStoppedState(
      input: SubscribeInput(
        channels: expectedChannels,
        groups: expectedGroups
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
        reason: PubNubError(.unknown)
      ),
      event: .subscriptionChanged(
        channels: ["c1", "c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2", "g2-pnpres", "g3"]
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveReconnect),
      .managed(.receiveMessages(
        channels: ["c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3"],
        cursor: SubscribeCursor(timetoken: 500100900, region: 11)
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedState = Subscribe.ReceivingState(
      input: SubscribeInput(
        channels: expectedChannels,
        groups: expectedGroups
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
        channels: ["c1", "c1-pnpres", "c2", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4", "g4"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveMessages),
      .managed(.receiveMessages(
        channels: ["c1", "c1-pnpres", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedState = Subscribe.ReceivingState(
      input: SubscribeInput(
        channels: expectedChannels,
        groups: expectedGroups
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
        reason: PubNubError(.unknown)
      ),
      event: .subscriptionRestored(
        channels: ["c1", "c1-pnpres", "c2", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4", "g4"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveReconnect),
      .managed(.receiveMessages(
        channels: ["c1", "c1-pnpres", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedState = Subscribe.ReceivingState(
      input: SubscribeInput(
        channels: expectedChannels,
        groups: expectedGroups
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
        error: PubNubError(.unknown)
      ),
      event: .subscriptionRestored(
        channels: ["c1", "c1-pnpres", "c2", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4", "g4"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4"]
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(
        channels: expectedChannels,
        groups: expectedGroups
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
        channels: ["c1", "c1-pnpres", "c2", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4", "g4"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedState = Subscribe.ReceiveStoppedState(
      input: SubscribeInput(
        channels: expectedChannels,
        groups: expectedGroups
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
        channels: ["c1", "c1-pnpres", "c2", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4", "g4"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeRequest),
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4"]
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(
        channels: expectedChannels,
        groups: expectedGroups
      ),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  func test_SubscriptionRestoredForHandshakeReconnectingState() {
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        retryAttempt: 1,
        reason: PubNubError(.unknown)
      ),
      event: .subscriptionRestored(
        channels: ["c1", "c1-pnpres", "c2", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4", "g4"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4"]
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(
        channels: expectedChannels,
        groups: expectedGroups
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
        error: PubNubError(.unknown)
      ),
      event: .subscriptionRestored(
        channels: ["c1", "c1-pnpres", "c2", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4", "g4"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4"]
      ))
    ]
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(
        channels: expectedChannels,
        groups: expectedGroups
      ), cursor: SubscribeCursor(timetoken: 100, region: 55)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_SubscriptionRestoredForHandshakeStoppedState() {
    let results = transition.transition(
      from: Subscribe.HandshakeStoppedState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .subscriptionRestored(
        channels: ["c1", "c1-pnpres", "c2", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4", "g4"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expectedChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expectedGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedState = Subscribe.HandshakeStoppedState(
      input: SubscribeInput(
        channels: expectedChannels,
        groups: expectedGroups
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
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connecting,
        newStatus: .connected,
        error: nil
      ))),
      .managed(.receiveMessages(channels: input.allSubscribedChannelNames,
        groups: input.allSubscribedGroupNames,
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
      event: .handshakeFailure(error: PubNubError(.unknown))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeRequest),
      .managed(.handshakeReconnect(
        channels: input.allSubscribedChannelNames,
        groups: input.allSubscribedGroupNames,
        retryAttempt: 0,
        reason: PubNubError(.unknown)
      ))
    ]
    let expectedState = Subscribe.HandshakeReconnectingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 0, region: 0),
      retryAttempt: 0,
      reason: PubNubError(.unknown)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  // MARK: - Handshake Reconnect Success

  func test_HandshakeReconnectSuccessForReconnectingState() {
    let cursor = SubscribeCursor(
      timetoken: 200400600,
      region: 45
    )
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        retryAttempt: 1,
        reason: PubNubError(.unknown)
      ),
      event: .handshakeReconnectSuccess(cursor: cursor)
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connecting,
        newStatus: .connected,
        error: nil
      ))),
      .managed(.receiveMessages(
        channels: input.allSubscribedChannelNames,
        groups: input.allSubscribedGroupNames,
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
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        retryAttempt: 0,
        reason: PubNubError(.unknown)
      ),
      event: .handshakeReconnectFailure(error: PubNubError(.unknown))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .managed(.handshakeReconnect(
        channels: input.allSubscribedChannelNames, groups: input.allSubscribedGroupNames,
        retryAttempt: 1, reason: PubNubError(.unknown)
      ))
    ]
    let expectedState = Subscribe.HandshakeReconnectingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 0, region: 0),
      retryAttempt: 1,
      reason: PubNubError(.unknown)
    )
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  // MARK: - Handshake Give Up

  func test_HandshakeGiveUpForReconnectingState() {
    let results = transition.transition(
      from: Subscribe.HandshakeReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 0, region: 0),
        retryAttempt: 3,
        reason: PubNubError(.unknown)
      ),
      event: .handshakeReconnectGiveUp(error: PubNubError(.unknown))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connecting,
        newStatus: .connectionError(PubNubError(.unknown)),
        error: PubNubError(.unknown)
      )))
    ]
    let expectedState = Subscribe.HandshakeFailedState(
      input: input,
      cursor: SubscribeCursor(timetoken: 0, region: 0),
      error: PubNubError(.unknown)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  // MARK: - Receive Give Up

  func test_ReceiveGiveUpForReconnectingState() {
    let results = transition.transition(
      from: Subscribe.ReceiveReconnectingState(
        input: input, cursor: SubscribeCursor(timetoken: 18001000, region: 123),
        retryAttempt: 3,
        reason: PubNubError(.unknown)
      ),
      event: .receiveReconnectGiveUp(error: PubNubError(.unknown))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveReconnect),
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connected,
        newStatus: .disconnectedUnexpectedly(PubNubError(.unknown)),
        error: PubNubError(.unknown)
      )))
    ]
    let expectedState = Subscribe.ReceiveFailedState(
      input: input,
      cursor: SubscribeCursor(timetoken: 18001000, region: 123),
      error: PubNubError(.unknown)
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
        channels: input.allSubscribedChannelNames,
        groups: input.allSubscribedGroupNames,
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
    let results = transition.transition(
      from: Subscribe.ReceivingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 100500900, region: 11)
      ),
      event: .receiveFailure(error: PubNubError(.unknown))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveMessages),
      .managed(.receiveReconnect(
        channels: input.allSubscribedChannelNames,
        groups: input.allSubscribedGroupNames,
        cursor: SubscribeCursor(timetoken: 100500900, region: 11),
        retryAttempt: 0,
        reason: PubNubError(.unknown)
      ))
    ]
    let expectedState = Subscribe.ReceiveReconnectingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 100500900, region: 11),
      retryAttempt: 0,
      reason: PubNubError(.unknown)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  func test_ReceiveReconnectFailedForReconnectingState() {
    let results = transition.transition(
      from: Subscribe.ReceiveReconnectingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 100500900, region: 11),
        retryAttempt: 1,
        reason: PubNubError(.unknown)
      ),
      event: .receiveReconnectFailure(error: PubNubError(.unknown))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveReconnect),
      .managed(.receiveReconnect(
        channels: input.allSubscribedChannelNames,
        groups: input.allSubscribedGroupNames,
        cursor: SubscribeCursor(timetoken: 100500900, region: 11),
        retryAttempt: 2,
        reason: PubNubError(.unknown)
      ))
    ]
    let expectedState = Subscribe.ReceiveReconnectingState(
      input: input,
      cursor: SubscribeCursor(timetoken: 100500900, region: 11),
      retryAttempt: 2,
      reason: PubNubError(.unknown)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  // MARK: - Reconnect
  
  func test_ReconnectForHandshakeStoppedState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakeStoppedState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .reconnect(cursor: nil)
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: input.allSubscribedChannelNames,
        groups: input.allSubscribedGroupNames)
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
        error: PubNubError(.unknown)
      ),
      event: .reconnect(cursor: nil)
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: input.allSubscribedChannelNames,
        groups: input.allSubscribedGroupNames
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
      event: .reconnect(cursor: nil)
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: input.allSubscribedChannelNames,
        groups: input.allSubscribedGroupNames
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
        error: PubNubError(.unknown)
      ),
      event: .reconnect(cursor: nil)
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: input.allSubscribedChannelNames,
        groups: input.allSubscribedGroupNames
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
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connecting,
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
        reason: PubNubError(.unknown)
      ),
      event: .disconnect
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connecting,
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
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
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
        reason: PubNubError(.unknown)
      ),
      event: .disconnect
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveReconnect),
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
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
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connecting,
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
        reason: PubNubError(.badRequest)
      ),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeReconnect),
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connecting,
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
        error: PubNubError(.badRequest)
      ),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connectionError(PubNubError(.badRequest)),
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
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
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
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
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
        reason: PubNubError(.badRequest)
      ),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveReconnect),
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
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
        error: PubNubError(.badRequest)
      ),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnectedUnexpectedly(PubNubError(.badRequest)),
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
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
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
  meta: nil,
  error: nil
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
  meta: nil,
  error: nil
)
