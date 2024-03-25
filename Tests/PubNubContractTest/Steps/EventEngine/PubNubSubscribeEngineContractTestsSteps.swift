//
//  PubNubSubscribeEngineContractTestsSteps.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Cucumberish
import Foundation

@testable import PubNub

extension Subscribe.Invocation: ContractTestIdentifiable {
  var contractTestIdentifier: String {
    switch self {
    case .handshakeRequest:
      return "HANDSHAKE"
    case .handshakeReconnect:
      return "HANDSHAKE_RECONNECT"
    case .receiveMessages:
      return "RECEIVE_MESSAGES"
    case .receiveReconnect:
      return "RECEIVE_RECONNECT"
    case .emitMessages:
      return "EMIT_MESSAGES"
    case .emitStatus:
      return "EMIT_STATUS"
    }
  }
}

extension Subscribe.Invocation.Cancellable: ContractTestIdentifiable {
  var contractTestIdentifier: String {
    switch self {
    case .handshakeRequest:
      return "CANCEL_HANDSHAKE"
    case .handshakeReconnect:
      return "CANCEL_HANDSHAKE_RECONNECT"
    case .receiveMessages:
      return "CANCEL_RECEIVE_MESSAGES"
    case .receiveReconnect:
      return "CANCEL_RECEIVE_RECONNECT"
    }
  }
}

extension Subscribe.Event: ContractTestIdentifiable {
  var contractTestIdentifier: String {
    switch self {
    case .handshakeSuccess:
      return "HANDSHAKE_SUCCESS"
    case .handshakeFailure:
      return "HANDSHAKE_FAILURE"
    case .handshakeReconnectSuccess:
      return "HANDSHAKE_RECONNECT_SUCCESS"
    case .handshakeReconnectFailure:
      return "HANDSHAKE_RECONNECT_FAILURE"
    case .handshakeReconnectGiveUp:
      return "HANDSHAKE_RECONNECT_GIVEUP"
    case .receiveSuccess:
      return "RECEIVE_SUCCESS"
    case .receiveFailure:
      return "RECEIVE_FAILURE"
    case .receiveReconnectSuccess:
      return "RECEIVE_RECONNECT_SUCCESS"
    case .receiveReconnectFailure:
      return "RECEIVE_RECONNECT_FAILURE"
    case .receiveReconnectGiveUp:
      return "RECEIVE_RECONNECT_GIVEUP"
    case .subscriptionChanged:
      return "SUBSCRIPTION_CHANGED"
    case .subscriptionRestored:
      return "SUBSCRIPTION_RESTORED"
    case .unsubscribeAll:
      return "UNSUBSCRIBE_ALL"
    case .disconnect:
      return "DISCONNECT"
    case .reconnect:
      return "RECONNECT"
    }
  }
}

class PubNubSubscribeEngineContractTestsSteps: PubNubEventEngineContractTestsSteps {
  // A decorator that records Invocations and forwards all calls to the original instance
  private var dispatcherDecorator: DispatcherDecorator<
    Subscribe.Invocation,
    Subscribe.Event,
    Subscribe.Dependencies
  >!
  // A decorator that records Events and forwards all calls to the original instance
  private var transitionDecorator: TransitionDecorator<
    any SubscribeState,
    Subscribe.Event,
    Subscribe.Invocation
  >!
  
  override func handleAfterHook() {
    dispatcherDecorator = nil
    transitionDecorator = nil
    super.handleAfterHook()
  }
  
  override var expectSubscribeFailure: Bool {
    [
      "Successfully restore subscribe with failures",
      "Complete handshake failure",
      "Handshake failure recovery",
      "Receiving failure recovery"
    ].contains(currentScenario?.name ?? "")
  }
  
  override func createPubNubClient() -> PubNub {
    let container = DependencyContainer(configuration: self.configuration)
    let key = SubscribeEventEngineDependencyKey.self
    
    self.dispatcherDecorator = DispatcherDecorator(wrappedInstance: EffectDispatcher(
      factory: SubscribeEffectFactory(
        session: container[HTTPSubscribeSessionDependencyKey.self],
        presenceStateContainer: container[PresenceStateContainerDependencyKey.self]
      )
    ))
    self.transitionDecorator = TransitionDecorator(
      wrappedInstance: SubscribeTransition()
    )
    
    container.register(
      value: SubscribeEngine(
        state: Subscribe.UnsubscribedState(),
        transition: self.transitionDecorator,
        dispatcher: self.dispatcherDecorator,
        dependencies: EventEngineDependencies(value: Subscribe.Dependencies(configuration: configuration))
      ),
      forKey: SubscribeEventEngineDependencyKey.self
    )
    
    return PubNub(container: container)
  }

  override public func setup() {
    startCucumberHookEventsListening()
    
    Given("a linear reconnection policy with 3 retries") { _, _ in
      self.replacePubNubConfiguration(with: PubNubConfiguration(
        publishKey: self.configuration.publishKey,
        subscribeKey: self.configuration.subscribeKey,
        userId: self.configuration.userId,
        useSecureConnections: self.configuration.useSecureConnections,
        origin: self.configuration.origin,
        automaticRetry: AutomaticRetry(retryLimit: 3, policy: .linear(delay: 0.5)),
        heartbeatInterval: 0,
        supressLeaveEvents: true,
        enableEventEngine: true
      ))
    }
    
    Given("the demo keyset with event engine enabled") { _, _ in
      self.replacePubNubConfiguration(with: PubNubConfiguration(
        publishKey: self.configuration.publishKey,
        subscribeKey: self.configuration.subscribeKey,
        userId: self.configuration.userId,
        useSecureConnections: self.configuration.useSecureConnections,
        origin: self.configuration.origin,
        heartbeatInterval: 0,
        supressLeaveEvents: true,
        enableEventEngine: true
      ))
    }
    
    When("I subscribe") { _, _ in
      self.subscribeSynchronously(self.client, to: ["test"])
    }
    
    When("I subscribe with timetoken 42") { _, _ in
      self.subscribeSynchronously(self.client, to: ["test"], timetoken: 42)
    }
    
    Then("I receive an error in my subscribe response") { _, _ in
      XCTAssertNotNil(self.receivedErrorStatuses.first)
    }
    
    Then("I receive the message in my subscribe response") { _, _ in
      let messages = self.waitForMessages(self.client, count: 1) ?? []
      XCTAssertNotNil(messages.first)
    }
    
    Match(["And"], "I observe the following:") { _, value in
      let recordedEvents = self.transitionDecorator.recordedEvents.map { $0.contractTestIdentifier }
      let recordedInvocations = self.dispatcherDecorator.recordedInvocations.map { $0.contractTestIdentifier }
      
      XCTAssertTrue(recordedEvents.elementsEqual(self.extractExpectedResults(from: value).events))
      XCTAssertTrue(recordedInvocations.elementsEqual(self.extractExpectedResults(from: value).invocations))
    }
  }
}
