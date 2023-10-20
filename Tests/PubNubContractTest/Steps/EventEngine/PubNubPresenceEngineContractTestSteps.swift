//
//  PubNubPresenceEngineContractTestSteps.swift
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
      return "HEARTBEAT_FAILED"
    case .heartbeatGiveUp(_):
      return "HEARTBEAT_GIVE_UP"
    }
  }
}

class PubNubPresenceEngineContractTestsSteps: PubNubEventEngineContractTestsSteps {
  // A decorator that records Invocations and forwards all calls to the original instance
  private var dispatcherDecorator: DispatcherDecorator<Presence.Invocation, Presence.Event, Presence.EngineInput>!
  // A decorator that records Events and forwards all calls to the original instance
  private var transitionDecorator: TransitionDecorator<any PresenceState, Presence.Event, Presence.Invocation>!
  
  override func handleAfterHook() {
    dispatcherDecorator = nil
    transitionDecorator = nil
    super.handleAfterHook()
  }
  
  override func handleBeforeHook() {
    dispatcherDecorator = DispatcherDecorator(wrappedInstance: EffectDispatcher(
      factory: PresenceEffectFactory(
        session: HTTPSession(
          configuration: .pubnub,
          sessionQueue: DispatchQueue(label: "Subscribe Response Queue"),
          sessionStream: SessionListener()
        )
      )
    ))
    transitionDecorator = TransitionDecorator(
      wrappedInstance: PresenceTransition()
    )
    super.handleBeforeHook()
  }
  
  override func createPubNubClient() -> PubNub {
    let subscriptionSession = SubscriptionSession(
      configuration: self.configuration,
      subscribeEngine: EventEngineFactory().subscribeEngine(
        with: self.configuration,
        dispatcher: EmptyDispatcher(),
        transition: SubscribeTransition()
      ),
      presenceEngine: EventEngineFactory().presenceEngine(
        with: configuration,
        dispatcher: self.dispatcherDecorator,
        transition: self.transitionDecorator
      )
    )
    return PubNub(
      configuration: self.configuration,
      subscriptionSession: subscriptionSession
    )
  }
  
  override public func setup() {
    startCucumberHookEventsListening()
    
    Given("the demo keyset with Presence Event Engine enabled") { _, _ in
      self.replacePubNubConfiguration(with: PubNubConfiguration(
        publishKey: defaultPublishKey,
        subscribeKey: defaultSubscribeKey,
        userId: UUID().uuidString,
        useSecureConnections: false,
        origin: mockServerAddress,
        durationUntilTimeout: 20,
        supressLeaveEvents: true
      ))
    }
    When("I join '(.*)', '(.*)', '(.*)' channels") { args, _ in
      let firstChannel = args?[0] ?? ""
      let secondChannel = args?[1] ?? ""
      let thirdChannel = args?[2] ?? ""
      
      self.subscribeWithPresence(to: [firstChannel, secondChannel, thirdChannel])
    }
    Match(["And"], "I leave '(.*)' and '(.*)' channels") { args, _ in
      let firstChannel = args?[0] ?? ""
      let secondChannel = args?[1] ?? ""
      self.unsubscribe(from: [firstChannel, secondChannel])
    }
    Then("I observe the following:") { args, value in
      let recordedEvents = self.transitionDecorator.recordedEvents.map { $0.contractTestIdentifier }
      let recordedInvocations = self.dispatcherDecorator.recordedInvocations.map { $0.contractTestIdentifier }
            
      XCTAssertTrue(recordedEvents.elementsEqual(self.extractExpectedResults(from: value).events))
      XCTAssertTrue(recordedInvocations.elementsEqual(self.extractExpectedResults(from: value).invocations))
    }
  }
  
  private func subscribeWithPresence(to channels: [String] = [], and groups: [String] = []) {
    let expectation = XCTestExpectation()
    // Gives some time to proceed asynchronous requests
    DispatchQueue.main.asyncAfter(deadline: .now() + 30) { expectation.fulfill() }
    self.client.subscribe(to: channels, and: groups, withPresence: true)
    self.wait(for: [expectation], timeout: 32.0)
  }
  
  private func unsubscribe(from channels: [String] = [], and groups: [String] = []) {
    let expectation = XCTestExpectation()
    // Gives some time to proceed asynchronous requests
    DispatchQueue.main.asyncAfter(deadline: .now() + 30) { expectation.fulfill() }
    self.client.unsubscribe(from: channels, and: groups)
    self.wait(for: [expectation], timeout: 32.0)
  }
  
  private func withAsyncDelay() {
    // TODO:
  }
}
