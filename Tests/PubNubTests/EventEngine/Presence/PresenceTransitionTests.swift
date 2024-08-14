//
//  PresenceTransitionTests.swift
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

extension Presence.Invocation: Equatable {
  public static func ==(lhs: Presence.Invocation, rhs: Presence.Invocation) -> Bool {
    switch (lhs, rhs) {
    case let (.heartbeat(lC, lG), .heartbeat(rC, rG)):
      return lC.sorted(by: <) == rC.sorted(by: <) && lG.sorted(by: <) == rG.sorted(by: <)
    case let (.leave(lC, lG), .leave(rC, rG)):
      return lC.sorted(by: <) == rC.sorted(by: <) && lG.sorted(by: <) == rG.sorted(by: <)
    case (.wait, .wait):
      return true
    default:
      return false
    }
  }
}

extension Presence.Event: Equatable {
  public static func == (lhs: Presence.Event, rhs: Presence.Event) -> Bool {
    switch (lhs, rhs) {
    case let (.joined(lC, lG), .joined(rC, rG)):
      return lC.sorted(by: <) == rC.sorted(by: <) && lG.sorted(by: <) == rG.sorted(by: <)
    case let (.left(lC, lG), .left(rC, rG)):
      return lC.sorted(by: <) == rC.sorted(by: <) && lG.sorted(by: <) == rG.sorted(by: <)
    case let (.heartbeatFailed(lError), .heartbeatFailed(rError)):
      return lError == rError
    case (.leftAll, .leftAll):
      return true
    case (.reconnect, .reconnect):
      return true
    case (.disconnect, .disconnect):
      return true
    case (.timesUp, .timesUp):
      return true
    case (.heartbeatSuccess, .heartbeatSuccess):
      return true
    default:
      return false
    }
  }
}

extension PresenceState {
  func isEqual(to otherState: some PresenceState) -> Bool {
    (otherState as? Self) == self
  }
}

class PresenceTransitionTests: XCTestCase {
  private let transition = PresenceTransition(
    configuration: PubNubConfiguration(
      publishKey: "publishKey",
      subscribeKey: "subscribeKey",
      userId: "userId"
    )
  )
  
  // MARK: - Joined
  
  func testPresence_JoinedValidTransitions() {
    let configWithEmptyInterval = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      heartbeatInterval: 0
    )
    let configWithInterval = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      heartbeatInterval: 30
    )
    
    let state = Presence.HeartbeatInactive()
    let event = Presence.Event.joined(channels: ["c1", "c2"], groups: ["g1", "g2"])
    
    XCTAssertFalse(PresenceTransition(configuration: configWithEmptyInterval).canTransition(from: state, dueTo: event))
    XCTAssertTrue(PresenceTransition(configuration: configWithInterval).canTransition(from: state, dueTo: event))
  }
  
  func testPresence_JoinedEventForHeartbeatInactiveState() {
    let results = transition.transition(
      from: Presence.HeartbeatInactive(),
      event: .joined(channels: ["c3"], groups: ["g3"])
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .regular(.heartbeat(channels: ["c3"], groups: ["g3"]))
    ]
    let expectedState = Presence.Heartbeating(
      input: PresenceInput(channels: ["c3"], groups: ["g3"])
    )
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }

  func testPresence_JoinedEventForHeartbeatingState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.Heartbeating(input: input),
      event: .joined(channels: ["c3"], groups: ["g3"])
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .regular(.heartbeat(channels: ["c1", "c2", "c3"], groups: ["g1", "g2", "g3"]))
    ]
    let expectedState = Presence.Heartbeating(
      input: PresenceInput(channels: ["c1", "c2", "c3"], groups: ["g1", "g2", "g3"])
    )
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testPresence_JoinedEventForStoppedState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.HeartbeatStopped(input: input),
      event: .joined(channels: ["c3"], groups: ["g3"])
    )
    let expectedState = Presence.HeartbeatStopped(
      input: PresenceInput(channels: ["c1", "c2", "c3"], groups: ["g1", "g2", "g3"])
    )
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.isEmpty)
  }
  
  func testPresence_JoinedEventForCooldownState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.HeartbeatCooldown(input: input),
      event: .joined(channels: ["c3"], groups: ["g3"])
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .cancel(.wait),
      .regular(.heartbeat(channels: ["c1", "c2", "c3"], groups: ["g1", "g2", "g3"]))
    ]
    let expectedState = Presence.Heartbeating(
      input: PresenceInput(channels: ["c1", "c2", "c3"], groups: ["g1", "g2", "g3"])
    )
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  // MARK: - Left

  func testPresence_LeftEventForHeartbeatingState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.Heartbeating(input: input),
      event: .left(channels: ["c3"], groups: ["g3"])
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .regular(.leave(channels: ["c3"], groups: ["g3"])),
      .regular(.heartbeat(channels: ["c1", "c2"], groups: ["g1", "g2"]))
    ]
    let expectedState = Presence.Heartbeating(
      input: PresenceInput(channels: ["c1", "c2"], groups: ["g1", "g2"])
    )
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testPresence_LeftEventForStoppedState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.HeartbeatStopped(input: input),
      event: .left(channels: ["c3"], groups: ["g3"])
    )
    let expectedState = Presence.HeartbeatStopped(
      input: PresenceInput(channels: ["c1", "c2"], groups: ["g1", "g2"])
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .regular(.leave(channels: ["c3"], groups: ["g3"])),
    ]
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testPresence_LeftEventForCooldownState() {
    let input = PresenceInput(
      channels: ["c1", "c2", "c3"],
      groups: ["g1", "g2", "g3"]
    )
    let results = transition.transition(
      from: Presence.HeartbeatCooldown(input: input),
      event: .left(channels: ["c3"], groups: ["g3"])
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .cancel(.wait),
      .regular(.leave(channels: ["c3"], groups: ["g3"])),
      .regular(.heartbeat(channels: ["c1", "c2"], groups: ["g1", "g2"]))
    ]
    let expectedState = Presence.Heartbeating(
      input: PresenceInput(channels: ["c1", "c2"], groups: ["g1", "g2"])
    )
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testPresence_LeftEventWithAllChannelsForCooldownState() {
    let input = PresenceInput(
      channels: ["c1", "c2", "c3"],
      groups: ["g1", "g2", "g3"]
    )
    let results = transition.transition(
      from: Presence.HeartbeatCooldown(input: input),
      event: .left(channels: ["c1", "c2", "c3"], groups: ["g1", "g2", "g3"])
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .cancel(.wait),
      .regular(.leave(channels: ["c1", "c2", "c3"], groups: ["g1", "g2", "g3"])),
    ]
    let expectedState = Presence.HeartbeatInactive()
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testPresence_LeftEventWithSuppressLeaveEventsSetInConfig() {
    let input = PresenceInput(
      channels: ["c1", "c2", "c3"],
      groups: ["g1", "g2", "g3"]
    )
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      supressLeaveEvents: true
    )
    let results = PresenceTransition(configuration: config).transition(
      from: Presence.HeartbeatCooldown(input: input),
      event: .left(channels: ["c1", "c2"], groups: ["g1", "g2"])
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .cancel(.wait),
      .regular(.heartbeat(channels: ["c3"], groups: ["g3"]))
    ]
    let expectedState = Presence.Heartbeating(input: PresenceInput(
      channels: ["c3"],
      groups: ["g3"]
    ))
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  // MARK: - Left All

  func testPresence_LeftAllForHeartbeatingState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.Heartbeating(input: input),
      event: .leftAll
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .regular(.leave(channels: ["c1", "c2"], groups: ["g1", "g2"]))
    ]
    let expectedState = Presence.HeartbeatInactive()
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testPresence_LeftAllForHeartbeatStoppedState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.HeartbeatStopped(input: input),
      event: .leftAll
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .regular(.leave(channels: ["c1", "c2"], groups: ["g1", "g2"]))
    ]
    
    XCTAssertTrue(results.state.isEqual(to: Presence.HeartbeatInactive()))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testPresence_LeftAllForCooldownState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.HeartbeatCooldown(input: input),
      event: .leftAll
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .cancel(.wait),
      .regular(.leave(channels: ["c1", "c2"], groups: ["g1", "g2"]))
    ]
    let expectedState = Presence.HeartbeatInactive()
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testPresence_LeftAllWithSuppressLeaveEventsSetInConfig() {
    let input = PresenceInput(
      channels: ["c1", "c2", "c3"],
      groups: ["g1", "g2", "g3"]
    )
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      supressLeaveEvents: true
    )
    let results = PresenceTransition(configuration: config).transition(
      from: Presence.HeartbeatCooldown(input: input),
      event: .leftAll
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .cancel(.wait)
    ]
    
    XCTAssertTrue(results.state.isEqual(to: Presence.HeartbeatInactive()))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  // MARK: - Reconnect
  
  func testPresence_ReconnectForStoppedState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.HeartbeatStopped(input: input),
      event: .reconnect
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .regular(.heartbeat(channels: ["c1", "c2"], groups: ["g1", "g2"]))
    ]
    let expectedState = Presence.Heartbeating(input: input)
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testPresence_ReconnectForFailedState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.HeartbeatFailed(input: input, error: PubNubError(.unknown)),
      event: .reconnect
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .regular(.heartbeat(channels: ["c1", "c2"], groups: ["g1", "g2"]))
    ]
    let expectedState = Presence.Heartbeating(input: input)
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  // MARK: - Disconnect

  func testPresence_DisconnectForHeartbeatingState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.Heartbeating(input: input),
      event: .disconnect
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .regular(.leave(channels: ["c1", "c2"], groups: ["g1", "g2"]))
    ]
    let expectedState = Presence.HeartbeatStopped(input: input)
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  func testPresence_DisconnectForCooldownState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.HeartbeatCooldown(input: input),
      event: .disconnect
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .cancel(.wait),
      .regular(.leave(channels: ["c1", "c2"], groups: ["g1", "g2"]))
    ]
    let expectedState = Presence.HeartbeatStopped(input: input)
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  // MARK: - Heartbeat Success

  func testPresence_HeartbeatSuccessForHeartbeatingState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.Heartbeating(input: input),
      event: .heartbeatSuccess
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .managed(.wait)
    ]
    let expectedState = Presence.HeartbeatCooldown(input: input)
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
  
  // MARK: - Heartbeat Failed
  
  func testPresence_HeartbeatFailedForHeartbeatingState() {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.Heartbeating(input: input),
      event: .heartbeatFailed(error: PubNubError(.unknown))
    )
    let expectedState = Presence.HeartbeatFailed(
      input: input,
      error: PubNubError(.unknown)
    )
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.isEmpty)
  }
  
  // MARK: - Times Up
  
  func testPresence_TimesUpForCooldownState() throws {
    let input = PresenceInput(
      channels: ["c1", "c2"],
      groups: ["g1", "g2"]
    )
    let results = transition.transition(
      from: Presence.HeartbeatCooldown(input: input),
      event: .timesUp
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .cancel(.wait),
      .regular(.heartbeat(channels: ["c1", "c2"], groups: ["g1", "g2"]))
    ]
    let expectedState = Presence.Heartbeating(input: input)
    
    XCTAssertTrue(results.state.isEqual(to: expectedState))
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations))
  }
}
