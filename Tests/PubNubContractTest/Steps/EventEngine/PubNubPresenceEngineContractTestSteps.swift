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

// TODO: Align on names in contract tests for Invocation and Events

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
    let factory = EventEngineFactory()
    let subscriptionSession = SubscriptionSession(
      configuration: self.configuration,
      subscribeEngine: factory.subscribeEngine(
        with: self.configuration,
        dispatcher: EmptyDispatcher(),
        transition: SubscribeTransition()
      ),
      presenceEngine: factory.presenceEngine(
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
  }
}
