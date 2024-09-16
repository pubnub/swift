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

@testable import PubNubSDK

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
    case let (.receiveMessages(lC, lG, lCrsr),.receiveMessages(rC, rG, rCrsr)):
      return lC.sorted(by: <) == rC.sorted(by: <) && lG.sorted(by: <) == rG.sorted(by: <) && lCrsr == rCrsr
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
    case let (.handshakeFailure(lError), .handshakeFailure(rError)):
      return lError == rError
    case let (.receiveSuccess(lCursor, lMssgs), .receiveSuccess(rCursor, rMssgs)):
      return lCursor == rCursor && lMssgs == rMssgs
    case let (.receiveFailure(lError), .receiveFailure(rError)):
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
    let expChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(channels: expChannels, groups: expGroups),
      cursor: SubscribeCursor(timetoken: 0)!
    )
    
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
    let expChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3"]
      ))
    ]

    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(channels: expChannels, groups: expGroups),
      cursor: SubscribeCursor(timetoken: 0, region: 0)
    )
    
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

    let expectedState = Subscribe.HandshakeStoppedState(
      input: SubscribeInput(channels: expectedChannels,groups: expectedGroups),
      cursor: SubscribeCursor(timetoken: 0, region: 0)
    )
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.isEmpty)
  }
  
  func test_SubscriptionChangedForHandshakingState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakingState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
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
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeRequest),
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3"]
      ))
    ]

    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(channels: expectedChannels, groups: expectedGroups),
      cursor: SubscribeCursor(timetoken: 0, region: 0)
    )
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func test_SubscriptionChangedForReceivingState() throws {
    let status: ConnectionStatus = .subscriptionChanged(
      channels: input.subscribedChannelNames,
      groups: input.subscribedGroupNames
    )
    let results = transition.transition(
      from: Subscribe.ReceivingState(
        input: input, cursor: SubscribeCursor(timetoken: 5001000, region: 22),
        connectionStatus: status
      ),
      event: .subscriptionChanged(
        channels: ["c1", "c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2", "g2-pnpres", "g3"]
      )
    )
    let expChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    
    let expectedNewStatus: ConnectionStatus = .subscriptionChanged(
      channels: expChannels.map { $0.id },
      groups: expGroups.map { $0.id }
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveMessages),
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: status,
        newStatus: expectedNewStatus,
        error: nil
      ))),
      .managed(.receiveMessages(
        channels: ["c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3"],
        cursor: SubscribeCursor(timetoken: 5001000, region: 22)
      ))
    ]
    
    let expectedState = Subscribe.ReceivingState(
      input: SubscribeInput(channels: expChannels, groups: expGroups),
      cursor: SubscribeCursor(timetoken: 5001000, region: 22),
      connectionStatus: .subscriptionChanged(channels: expChannels.map { $0.id }, groups: expGroups.map { $0.id })
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
    let expChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(channels: expChannels, groups: expGroups),
      cursor: SubscribeCursor(timetoken: 500100900, region: 11)
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
    let expChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: false)
    ]
    let expGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: false)
    ]
    let expectedState = Subscribe.ReceiveStoppedState(
      input: SubscribeInput(channels: expChannels, groups: expGroups),
      cursor: SubscribeCursor(timetoken: 500100900, region: 11)
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.isEmpty)
  }

  // MARK: - Subscription Restored

  func test_SubscriptionRestoredForReceivingState() throws {
    let status: ConnectionStatus = .subscriptionChanged(
      channels: input.subscribedChannelNames,
      groups: input.subscribedGroupNames
    )
    let results = transition.transition(
      from: Subscribe.ReceivingState(
        input: input, cursor: SubscribeCursor(timetoken: 1500100900, region: 41),
        connectionStatus: status
      ),
      event: .subscriptionRestored(
        channels: ["c1", "c1-pnpres", "c2", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4", "g4"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      )
    )
    let expChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedNewStatus: ConnectionStatus = .subscriptionChanged(
      channels: expChannels.map { $0.id },
      groups: expGroups.map { $0.id }
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveMessages),
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: status,
        newStatus: expectedNewStatus,
        error: nil
      ))),
      .managed(.receiveMessages(
        channels: ["c1", "c1-pnpres", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4"],
        cursor: SubscribeCursor(timetoken: 100, region: 55)
      ))
    ]

    let expectedState = Subscribe.ReceivingState(
      input: SubscribeInput(channels: expChannels, groups: expGroups),
      cursor: SubscribeCursor(timetoken: 100, region: 55),
      connectionStatus: .subscriptionChanged(
        channels: expChannels.map { $0.id },
        groups: expGroups.map {  $0.id }
      )
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
    let expChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(channels: expChannels, groups: expGroups),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
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
    let expChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedState = Subscribe.ReceiveStoppedState(
      input: SubscribeInput(channels: expChannels, groups: expGroups),
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
    let expChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeRequest),
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4"]
      ))
    ]
    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(channels: expChannels, groups: expGroups),
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
    let expChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .managed(.handshakeRequest(
        channels: ["c1", "c1-pnpres", "c2", "c2-pnpres", "c3", "c3-pnpres", "c4"],
        groups: ["g1", "g1-pnpres", "g2", "g2-pnpres", "g3", "g3-pnpres", "g4"]
      ))
    ]

    let expectedState = Subscribe.HandshakingState(
      input: SubscribeInput(channels: expChannels, groups: expGroups),
      cursor: SubscribeCursor(timetoken: 100, region: 55)
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
    let expChannels = [
      PubNubChannel(id: "c1", withPresence: true),
      PubNubChannel(id: "c2", withPresence: true),
      PubNubChannel(id: "c3", withPresence: true),
      PubNubChannel(id: "c4", withPresence: false)
    ]
    let expGroups = [
      PubNubChannel(id: "g1", withPresence: true),
      PubNubChannel(id: "g2", withPresence: true),
      PubNubChannel(id: "g3", withPresence: true),
      PubNubChannel(id: "g4", withPresence: false)
    ]
    let expectedState = Subscribe.HandshakeStoppedState(
      input: SubscribeInput(channels: expChannels, groups: expGroups),
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
        oldStatus: .disconnected,
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
      cursor: SubscribeCursor(timetoken: 1500100900, region: 41),
      connectionStatus: .connected
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
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .connectionError(PubNubError(.unknown)),
        error: PubNubError(.unknown))
      ))
    ]
    let expectedState = Subscribe.HandshakeFailedState(
      input: input,
      cursor: SubscribeCursor(timetoken: 0, region: 0),
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
        cursor: SubscribeCursor(timetoken: 18001000, region: 123),
        connectionStatus: .connected
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
      cursor: SubscribeCursor(timetoken: 18002000, region: 123),
      connectionStatus: .connected
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  // MARK: - Receive Failed

  func test_ReceiveFailedForReceivingState() {
    let results = transition.transition(
      from: Subscribe.ReceivingState(
        input: input,
        cursor: SubscribeCursor(timetoken: 100500900, region: 11),
        connectionStatus: .connected
      ),
      event: .receiveFailure(error: PubNubError(.unknown))
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.receiveMessages),
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .connected,
        newStatus: .disconnectedUnexpectedly(PubNubError(.unknown)),
        error: PubNubError(.unknown))
      ))
    ]
    let expectedState = Subscribe.ReceiveFailedState(
      input: input,
      cursor: SubscribeCursor(timetoken: 100500900, region: 11),
      error: PubNubError(.unknown)
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
        cursor: SubscribeCursor(timetoken: 123, region: 456),
        connectionStatus: .connected
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
  
  // MARK: - Unsubscribe All
  
  func testUnsubscribeAll_ForHandshakingState() throws {
    let results = transition.transition(
      from: Subscribe.HandshakingState(input: input, cursor: SubscribeCursor(timetoken: 0, region: 0)),
      event: .unsubscribeAll
    )
    let expectedInvocations: [EffectInvocation<Subscribe.Invocation>] = [
      .cancel(.handshakeRequest),
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: .disconnected,
        newStatus: .disconnected,
        error: nil
      )))
    ]

    XCTAssertTrue(results.state.isEqual(to: Subscribe.UnsubscribedState()))
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
        cursor: SubscribeCursor(timetoken: 123, region: 456),
        connectionStatus: .connected
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

    XCTAssertTrue(results.state.isEqual(to: Subscribe.UnsubscribedState()))
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

    XCTAssertTrue(results.state.isEqual(to: Subscribe.UnsubscribedState()))
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

    XCTAssertTrue(results.state.isEqual(to: Subscribe.UnsubscribedState()))
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
