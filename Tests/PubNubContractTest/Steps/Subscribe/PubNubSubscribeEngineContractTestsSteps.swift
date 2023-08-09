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
    case .handshakeSucceess(_):
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

class PubNubSubscribeEngineContractTestsSteps: PubNubContractTestCase {
  // A subscription session with wrapped Disptacher and Transition in order to record Invocations and Events
  private var subscriptionSession: SubscriptionSession!
  // A decorator that records Invocations and forwards all calls to the original instance
  private var dispatcher: DispatcherDecorator<Subscribe.Invocation, Subscribe.Event, Subscribe.EngineInput>!
  // A decorator that records Events and forwards all calls to the original instance
  private var transition: TransitionDecorator<AnySubscribeState, Subscribe.Event, Subscribe.Invocation>!
  // SubscribeEngine with observed Dispatcher and Transition
  private var subscribeEngine: SubscribeEngine!
  
  override func handleAfterHook() {
    dispatcher = nil
    transition = nil
    subscribeEngine = nil
    subscriptionSession = nil
    super.handleAfterHook()
  }
  
  override func handleBeforeHook() {
    dispatcher = DispatcherDecorator(wrappedInstance: EffectDispatcher(
      factory: SubscribeEffectFactory(session: HTTPSession(
        configuration: URLSessionConfiguration.subscription,
        sessionQueue: DispatchQueue(label: "Subscribe Response Queue"),
        sessionStream: SessionListener()
      ))
    ))
    transition = TransitionDecorator(
      wrappedInstance: SubscribeTransition()
    )
    super.handleBeforeHook()
  }

  override var expectSubscribeFailure: Bool {
    hasStep(with: "I receive an error in my subscribe response")
  }
  
  override func createPubNubClient() -> PubNub {
    PubNub(configuration: self.configuration, subscriptionSession: subscriptionSession)
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
        supressLeaveEvents: true
      ))
      self.subscribeEngine = EventEngineFactory().subscribeEngine(
        with: self.configuration,
        dispatcher: self.dispatcher,
        transition: self.transition
      )
      self.subscriptionSession = SubscriptionSession(
        configuration: self.configuration,
        subscribeEngine: self.subscribeEngine
      )
    }
    Given("the demo keyset with event engine enabled") { _, _ in
      self.subscribeEngine = EventEngineFactory().subscribeEngine(
        with: self.configuration,
        dispatcher: self.dispatcher,
        transition: self.transition
      )
      self.subscriptionSession = SubscriptionSession(
        configuration: self.configuration,
        subscribeEngine: self.subscribeEngine
      )
    }
    When("I subscribe") { _, _ in
      self.subscribeSynchronously(self.client, to: ["test"])
    }
    Then("I receive an error in my subscribe response") { _, _ in
      XCTAssertNotNil(self.receivedErrorStatuses.first)
    }
    Then("I receive the message in my subscribe response") { _, userInfo in
      let messages = self.waitForMessages(self.client, count: 1) ?? []
      XCTAssertNotNil(messages.first)
    }
    Match(["And"], "I observe the following:") { args, value in
      let recordedEvents = self.transition.recordedEvents.map { $0.contractTestIdentifier }
      let recordedInvocations = self.dispatcher.recordedInvocations.map { $0.contractTestIdentifier }
      XCTAssertTrue(recordedEvents.elementsEqual(self.extractExpectedResults(from: value).events))
      XCTAssertTrue(recordedInvocations.elementsEqual(self.extractExpectedResults(from: value).invocations))
    }
  }
  
  private func extractExpectedResults(from: [AnyHashable: Any]?) -> (events: [String], invocations: [String]) {
    let dataTable = from?["DataTable"] as? Array<Array<String>> ?? []
    let events = dataTable.compactMap { $0.first == "event" ? $0.last : nil }
    let invocations = dataTable.compactMap { $0.first == "invocation" ? $0.last : nil }
    
    return (events: events, invocations: invocations)
  }
}
