//
//  PubNubSubscribeEngineContractTestsSteps.swift
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
import Cucumberish

@testable import PubNub

extension Subscribe.Invocation: ContractTestIdentifiable {
  var contractTestIdentifier: String {
    switch self {
    case .handshakeRequest(_, _):
      return "HANDSHAKE"
    case .handshakeReconnect(_, _, _, _):
      return "HANDSHAKE_RECONNECT"
    case .receiveMessages(_, _, _):
      return "RECEIVE_MESSAGES"
    case .receiveReconnect(_, _, _, _, _):
      return "RECEIVE_RECONNECT"
    case .emitMessages(_,_):
      return "EMIT_MESSAGES"
    case .emitStatus(_):
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
    case .handshakeSuccess(_):
      return "HANDSHAKE_SUCCESS"
    case .handshakeFailure(_):
      return "HANDSHAKE_FAILURE"
    case .handshakeReconnectSuccess(_):
      return "HANDSHAKE_RECONNECT_SUCCESS"
    case .handshakeReconnectFailure(_):
      return "HANDSHAKE_RECONNECT_FAILURE"
    case .handshakeReconnectGiveUp(_):
      return "HANDSHAKE_RECONNECT_GIVEUP"
    case .receiveSuccess(_,_):
      return "RECEIVE_SUCCESS"
    case .receiveFailure(_):
      return "RECEIVE_FAILURE"
    case .receiveReconnectSuccess(_,_):
      return "RECEIVE_RECONNECT_SUCCESS"
    case .receiveReconnectFailure(_):
      return "RECEIVE_RECONNECT_FAILURE"
    case .receiveReconnectGiveUp(_):
      return "RECEIVE_RECONNECT_GIVEUP"
    case .subscriptionChanged(_, _):
      return "SUBSCRIPTION_CHANGED"
    case .subscriptionRestored(_, _, _):
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
  private var dispatcherDecorator: DispatcherDecorator<Subscribe.Invocation, Subscribe.Event, Subscribe.EngineInput>!
  // A decorator that records Events and forwards all calls to the original instance
  private var transitionDecorator: TransitionDecorator<any SubscribeState, Subscribe.Event, Subscribe.Invocation>!
  
  override func handleAfterHook() {
    dispatcherDecorator = nil
    transitionDecorator = nil
    super.handleAfterHook()
  }
  
  override func handleBeforeHook() {
    dispatcherDecorator = DispatcherDecorator(wrappedInstance: EffectDispatcher(
      factory: SubscribeEffectFactory(session: HTTPSession(
        configuration: URLSessionConfiguration.subscription,
        sessionQueue: DispatchQueue(label: "Subscribe Response Queue"),
        sessionStream: SessionListener()
      ))
    ))
    transitionDecorator = TransitionDecorator(
      wrappedInstance: SubscribeTransition()
    )
    super.handleBeforeHook()
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
    let factory = EventEngineFactory()
    let subscriptionSession = SubscriptionSession(
      strategy: EventEngineSubscriptionSessionStrategy(
        configuration: self.configuration,
        subscribeEngine: factory.subscribeEngine(
          with: self.configuration,
          dispatcher: self.dispatcherDecorator,
          transition: self.transitionDecorator
        ),
        presenceEngine: factory.presenceEngine(
          with: self.configuration,
          dispatcher: EmptyDispatcher(),
          transition: PresenceTransition()
        )
      )
    )
    return PubNub(
      configuration: self.configuration,
      subscriptionSession: subscriptionSession
    )
  }

  override public func setup() {
    startCucumberHookEventsListening()
    
    Given("a linear reconnection policy with 3 retries") { args, _ in
      self.replacePubNubConfiguration(with: PubNubConfiguration(
        publishKey: defaultPublishKey,
        subscribeKey: defaultSubscribeKey,
        userId: UUID().uuidString,
        useSecureConnections: false,
        origin: mockServerAddress,
        automaticRetry: AutomaticRetry(retryLimit: 3, policy: .linear(delay: 0.5)),
        supressLeaveEvents: true,
        enableEventEngine: true
      ))
    }
    Given("the demo keyset with event engine enabled") { _, _ in
      self.replacePubNubConfiguration(with: PubNubConfiguration(
        publishKey: defaultPublishKey,
        subscribeKey: defaultSubscribeKey,
        userId: UUID().uuidString,
        useSecureConnections: false,
        origin: mockServerAddress,
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
    Then("I receive the message in my subscribe response") { _, userInfo in
      let messages = self.waitForMessages(self.client, count: 1) ?? []
      XCTAssertNotNil(messages.first)
    }
    Match(["And"], "I observe the following:") { args, value in
      let recordedEvents = self.transitionDecorator.recordedEvents.map { $0.contractTestIdentifier }
      let recordedInvocations = self.dispatcherDecorator.recordedInvocations.map { $0.contractTestIdentifier }
      XCTAssertTrue(recordedEvents.elementsEqual(self.extractExpectedResults(from: value).events))
      XCTAssertTrue(recordedInvocations.elementsEqual(self.extractExpectedResults(from: value).invocations))
    }
  }
}
