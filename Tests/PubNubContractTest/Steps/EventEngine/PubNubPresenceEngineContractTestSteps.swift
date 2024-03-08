//
//  PubNubPresenceEngineContractTestsSteps.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import Cucumberish

@testable import PubNub

extension Presence.Invocation: ContractTestIdentifiable {
  var contractTestIdentifier: String {
    switch self {
    case .heartbeat(_, _):
      return "HEARTBEAT"
    case .leave(_, _):
      return "LEAVE"
    case .delayedHeartbeat(_, _, _, _):
      return "DELAYED_HEARTBEAT"
    case .wait:
      return "WAIT"
    }
  }
}

extension Presence.Invocation.Cancellable: ContractTestIdentifiable {
  var contractTestIdentifier: String {
    switch self {
    case .wait:
      return "CANCEL_WAIT"
    case .delayedHeartbeat:
      return "CANCEL_DELAYED_HEARTBEAT"
    }
  }
}

extension Presence.Event: ContractTestIdentifiable {
  var contractTestIdentifier: String {
    switch self {
    case .joined(_, _):
      return "JOINED"
    case .left(_, _):
      return "LEFT"
    case .leftAll:
      return "LEFT_ALL"
    case .reconnect:
      return "RECONNECT"
    case .disconnect:
      return "DISCONNECT"
    case .timesUp:
      return "TIMES_UP"
    case .heartbeatSuccess:
      return "HEARTBEAT_SUCCESS"
    case .heartbeatFailed(_):
      return "HEARTBEAT_FAILURE"
    case .heartbeatGiveUp(_):
      return "HEARTBEAT_GIVEUP"
    }
  }
}

class PubNubPresenceEngineContractTestsSteps: PubNubEventEngineContractTestsSteps {
  // A decorator that records Invocations and forwards all calls to the original instance
  private var dispatcherDecorator: DispatcherDecorator<
    Presence.Invocation,
    Presence.Event,
    Presence.Dependencies
  >!
  // A decorator that records Events and forwards all calls to the original instance
  private var transitionDecorator: TransitionDecorator<
    any PresenceState,
    Presence.Event,
    Presence.Invocation
  >!
  
  override func handleAfterHook() {
    dispatcherDecorator = nil
    transitionDecorator = nil
    super.handleAfterHook()
  }
    
  override func createPubNubClient() -> PubNub {
    let container = DependencyContainer(configuration: self.configuration)
    let key = PresenceEventEngineDependencyKey.self
    
    container[key] = PresenceEngine(
      state: Presence.HeartbeatInactive(),
      transition: TransitionDecorator(wrappedInstance: container[PresenceTransitionDependencyKey.self]),
      dispatcher: DispatcherDecorator(wrappedInstance: container[PresenceEffectDispatcherDependencyKey.self]),
      dependencies: EventEngineDependencies(value: Presence.Dependencies(configuration: configuration))
    )
    
    return PubNub(container: container)
  }
  
  override public func setup() {
    startCucumberHookEventsListening()
    
    Given("^the demo keyset with Presence Event Engine enabled$") { args, _ in
      self.replacePubNubConfiguration(with: PubNubConfiguration(
        publishKey: self.configuration.publishKey,
        subscribeKey: self.configuration.subscribeKey,
        userId: self.configuration.userId,
        useSecureConnections: self.configuration.useSecureConnections,
        origin: self.configuration.origin,
        enableEventEngine: true
      ))
    }
    
    Given("a linear reconnection policy with 3 retries") { args, _ in
      self.replacePubNubConfiguration(with: PubNubConfiguration(
        publishKey: self.configuration.publishKey,
        subscribeKey: self.configuration.subscribeKey,
        userId: self.configuration.userId,
        useSecureConnections: self.configuration.useSecureConnections,
        origin: self.configuration.origin,
        automaticRetry: AutomaticRetry(retryLimit: 3, policy: .linear(delay: 0.5)),
        heartbeatInterval: 30,
        supressLeaveEvents: true,
        enableEventEngine: true
      ))
    }
    
    Given("^heartbeatInterval set to '([0-9]+)', timeout set to '([0-9]+)' and suppressLeaveEvents set to '(.*)'$") { args, _ in
      self.replacePubNubConfiguration(with: PubNubConfiguration(
        publishKey: self.configuration.publishKey,
        subscribeKey: self.configuration.subscribeKey,
        userId: self.configuration.userId,
        useSecureConnections: self.configuration.useSecureConnections,
        origin: self.configuration.origin,
        durationUntilTimeout: UInt(args![1])!,
        heartbeatInterval: UInt(args![0])!,
        supressLeaveEvents: args![2] == "true",
        enableEventEngine: self.configuration.enableEventEngine
      ))
    }
    
    When("^I join '(.*)', '(.*)', '(.*)' channels$") { args, _ in
      let firstChannel = args?[0] ?? ""
      let secondChannel = args?[1] ?? ""
      let thirdChannel = args?[2] ?? ""
      
      self.subscribeSynchronously(self.client, to: [firstChannel, secondChannel, thirdChannel], with: false)
    }
    
    When("^I join '(.*)', '(.*)', '(.*)' channels with presence$") { args, _ in
      let firstChannel = args?[0] ?? ""
      let secondChannel = args?[1] ?? ""
      let thirdChannel = args?[2] ?? ""
      
      self.subscribeSynchronously(self.client, to: [firstChannel, secondChannel, thirdChannel], with: true)
    }
    
    Then("^I wait for getting Presence joined events$") { args, _ in
      XCTAssertNotNil(self.waitForPresenceChanges(self.client, count: 3))
    }
    
    Then("^I wait '([0-9]+)' seconds$") { args, _ in
      self.waitFor(delay: TimeInterval(args!.first!)!)
    }
    
    Then("^I wait for getting Presence left events$") { args, _ in
      XCTAssertNotNil(self.waitForPresenceChanges(self.client, count: 2))
    }
    
    Then("^I leave '(.*)' and '(.*)' channels with presence$") { args, _ in
      let firstChannel = args?[0] ?? ""
      let secondChannel = args?[1] ?? ""
      
      self.client.unsubscribe(from: [firstChannel, secondChannel])
    }
    
    Then("^I receive an error in my heartbeat response$") { _, _ in
      self.waitFor(delay: 9.5)
    }
    
    Match(["And", "Then"], "^I observe the following Events and Invocations of the Presence EE:$") { args, value in
      let recordedEvents = self.transitionDecorator.recordedEvents.map { $0.contractTestIdentifier }
      let recordedInvocations = self.dispatcherDecorator.recordedInvocations.map { $0.contractTestIdentifier }
      
      XCTAssertTrue(recordedEvents.elementsEqual(self.extractExpectedResults(from: value).events))
      XCTAssertTrue(recordedInvocations.elementsEqual(self.extractExpectedResults(from: value).invocations))
    }
    
    Then("^I don't observe any Events and Invocations of the Presence EE") { args, value in
      XCTAssertTrue(self.transitionDecorator.recordedEvents.isEmpty)
      XCTAssertTrue(self.dispatcherDecorator.recordedInvocations.isEmpty)
    }
  }
}
