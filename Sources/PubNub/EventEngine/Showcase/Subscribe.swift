//
//  Subscribe.swift
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

/// This acts like a namespace in order to keep State, Actions and Effect invocations for Subscribe in a one place:
enum Subscribe {
  
  class State: AnyState {}
  class Unsubscribed: State {}
  class Preparing: State {}
  class Handshaking: State {}
  class HandshakingFailed: State {}
  class Receiving: State {}
  class Delivering: State {}
  class Reconnecting: State {}
  class ReconnectingFailed: State {}
  class Stopped: State {}
  class CancelPendingRequest: State {}

  // TODO: Provide real actions
  enum Events {
    case connect
    case disconnect
    case reconnect
  }
  
  // TODO: Provide real invocations to describe Effects
  enum EffectInvocation: String {
    case effectInv1
    case effectInv2
    case effectInv3
  }
}

class SubscribeTransition: TransitionProtocol {
  typealias State = Subscribe.State
  typealias Event = Subscribe.Events
  typealias EffectKind = Subscribe.EffectInvocation
    
  func transition(from state: State, event: Event) -> TransitionResult<State, Event, EffectKind> {
    switch event {
    case .connect, .disconnect, .reconnect:
      fatalError("Not implemented yet")
    }
  }
}

class SubscribeEffectFactory: EffectHandlerFactory {
  typealias Event = Subscribe.Events
  typealias EffectKind = Subscribe.EffectInvocation
  
  func effect(
    for invocation: EffectInvocation<EffectKind, Event>,
    with eventDispatcher: some EventDispatcher<Event>
  ) -> any EffectHandler<EffectKind, Event> {
    switch invocation.kind {
    case .effectInv1, .effectInv2, .effectInv3:
      fatalError("Not implemented yet")
    }
  }
}

///
/// This is how you can use an EventEngine instance that's configured to handle a Subscribe loop:
///
let subscribeEventEngine = EventEngine(
  state: Subscribe.State(),
  transition: SubscribeTransition(),
  dispatcher: EffectDispatcher(factory: SubscribeEffectFactory())
)
