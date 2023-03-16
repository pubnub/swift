//
//  Subscribe.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

/// This enum acts like a namespace in order to keep State, Actions and EffectInvocations for Subscribe in one place
enum Subscribe {
  
  struct State {
    var x: Int
    var y: Int
    var z: Int
  }
  
  enum Actions {
    case a1
    case a2
    case a3
    case a4
    case a5
  }
  
  enum EffectInvocation {
    case e1
    case e2
    case e3
  }
}

class SubscribeTransition: TransitionProtocol {
  typealias State = Subscribe.State
  typealias Action = Subscribe.Actions
  typealias Kind = Subscribe.EffectInvocation
  
  func defaultState() -> Subscribe.State {
    Subscribe.State(x: 0, y: 0, z: 0)
  }
  
  func transition(
    from state: State,
    action: Action
  ) -> TransitionResult<State,Action,Kind> {
    switch action {
    case .a1, .a2, .a3, .a4, .a5:
      fatalError("Not implemented yet")
    }
  }
}

class SubscribeEffectFactory: EffectHandlerFactory {
  typealias Action = Subscribe.Actions
  typealias Kind = Subscribe.EffectInvocation
  
  func effect(
    for invocation: EffectInvocation<Subscribe.EffectInvocation, Subscribe.Actions>
  ) -> any EffectHandler<Kind,Action> {
    switch invocation.kind {
    case .e1, .e2, .e3:
      return CustomEH(invocation: invocation)
      fatalError("Not implemented yet")
    }
  }
}

class CustomEH: EffectHandler {
  var invocation: EffectInvocation<Subscribe.EffectInvocation, Subscribe.Actions>
  
  typealias Action = Subscribe.Actions
  typealias Kind = Subscribe.EffectInvocation
    
  init(invocation: EffectInvocation<Subscribe.EffectInvocation, Subscribe.Actions>) {
    self.invocation = invocation
  }
  
  func start() {
    invocation.onCompletion?(.success(.a4))
  }
  
  func cancel() {
    
  }
}

///
/// This is how you can use an EventEngine instance that's configured to handle a Subscribe loop:
///
let subscribeEventEngine = EventEngine(
  transition: SubscribeTransition(),
  dispatcher: EffectDispatcher(factory: SubscribeEffectFactory())
)
