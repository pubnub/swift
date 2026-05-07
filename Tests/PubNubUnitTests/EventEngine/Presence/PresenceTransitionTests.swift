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

extension Presence.Invocation: @retroactive Equatable {
  public static func == (lhs: Presence.Invocation, rhs: Presence.Invocation) -> Bool {
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

extension Presence.Event: @retroactive Equatable {
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
      userId: "userId",
      heartbeatInterval: 30
    )
  )

  // MARK: - Joined

  func test_Joined_FromHeartbeatInactiveState_IsValidTransition() {
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

    XCTAssertTrue(PresenceTransition(configuration: configWithEmptyInterval).canTransition(from: state, dueTo: event))
    XCTAssertTrue(PresenceTransition(configuration: configWithInterval).canTransition(from: state, dueTo: event))
  }

  func test_Joined_FromHeartbeatInactiveState_TransitionsToHeartbeating() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_Joined_FromHeartbeatInactiveStateWithEmptyInterval_TransitionsToHeartbeating() {
    let configWithEmptyInterval = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      heartbeatInterval: 0
    )

    let presenceTransition = PresenceTransition(
      configuration: configWithEmptyInterval
    )
    let results = presenceTransition.transition(
      from: Presence.HeartbeatInactive(),
      event: .joined(channels: ["c3"], groups: ["g3"])
    )
    let expectedInvocations: [EffectInvocation<Presence.Invocation>] = [
      .regular(.heartbeat(channels: ["c3"], groups: ["g3"]))
    ]
    let expectedState = Presence.Heartbeating(
      input: PresenceInput(channels: ["c3"], groups: ["g3"])
    )

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_Joined_FromHeartbeatingState_TransitionsToHeartbeating() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_Joined_FromHeartbeatStoppedState_TransitionsToHeartbeatStopped() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.isEmpty)
  }

  func test_Joined_FromHeartbeatCooldownState_TransitionsToHeartbeating() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  // MARK: - Left

  func test_Left_FromHeartbeatingState_TransitionsToHeartbeating() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_Left_FromHeartbeatStoppedState_TransitionsToHeartbeatStopped() {
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
      .regular(.leave(channels: ["c3"], groups: ["g3"]))
    ]

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_Left_FromHeartbeatCooldownState_TransitionsToHeartbeating() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_Left_FromHeartbeatCooldownStateWithAllChannels_TransitionsToHeartbeatInactive() {
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
      .regular(.leave(channels: ["c1", "c2", "c3"], groups: ["g1", "g2", "g3"]))
    ]
    let expectedState = Presence.HeartbeatInactive()

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_Left_FromHeartbeatCooldownStateWithSuppressLeaveEvents_TransitionsToHeartbeating() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  // MARK: - Left All

  func test_LeftAll_FromHeartbeatingState_TransitionsToHeartbeatInactive() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_LeftAll_FromHeartbeatStoppedState_TransitionsToHeartbeatInactive() {
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
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_LeftAll_FromHeartbeatCooldownState_TransitionsToHeartbeatInactive() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_LeftAll_FromHeartbeatCooldownStateWithSuppressLeaveEvents_TransitionsToHeartbeatInactive() {
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
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  // MARK: - Reconnect

  func test_Reconnect_FromHeartbeatStoppedState_TransitionsToHeartbeating() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_Reconnect_FromHeartbeatFailedState_TransitionsToHeartbeating() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  // MARK: - Disconnect

  func test_Disconnect_FromHeartbeatingState_TransitionsToHeartbeatStopped() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_Disconnect_FromHeartbeatCooldownState_TransitionsToHeartbeatStopped() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  // MARK: - Heartbeat Success

  func test_HeartbeatSuccess_FromHeartbeatingState_TransitionsToHeartbeatCooldown() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }

  func test_HeartbeatSuccess_FromHeartbeatingStateWithEmptyInterval_TransitionsToHeartbeatStopped() {
    let configWithEmptyInterval = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      heartbeatInterval: 0
    )

    let presenceTransition = PresenceTransition(configuration: configWithEmptyInterval)
    let input = PresenceInput(channels: ["c1", "c2"], groups: ["g1", "g2"])

    let results = presenceTransition.transition(
      from: Presence.Heartbeating(input: input),
      event: .heartbeatSuccess
    )

    XCTAssertTrue(results.state.isEqual(to: Presence.HeartbeatStopped(input: input)))
    XCTAssertTrue(results.invocations.isEmpty)
  }

  // MARK: - Heartbeat Failed

  func test_HeartbeatFailed_FromHeartbeatingState_TransitionsToHeartbeatFailed() {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.isEmpty)
  }

  // MARK: - Times Up

  func test_TimesUp_FromHeartbeatCooldownState_TransitionsToHeartbeating() throws {
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

    XCTAssertTrue(results.state.isEqual(to: expectedState), "State mismatch: expected \(type(of: expectedState))")
    XCTAssertTrue(results.invocations.elementsEqual(expectedInvocations), "Invocations mismatch")
  }
}
