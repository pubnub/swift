//
//  Transition.swift
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

///
/// Protocol for any type that can describe the Event Engine's state.
///
protocol AnyState {
  func didEnter()
  func didLeave()
}

extension AnyState {
  func didEnter() {}
  func didLeave() {}
}

/// Typealias for transition result.
/// It assumes that transition result returns a new State and Effect invocations that describes system's intent to perform some operations
typealias TransitionResult<State: AnyState, Event, EffectKind> = (state: State, invocations: [EffectInvocation<EffectKind, Event>])

///
/// Protocol for any type that can perform the transition between states given the action.
/// Concrete types are responsible to implement `transition(from state: State, action: Action)` and return a list of `EffectInvocation` that needs to be executed.
///
protocol TransitionProtocol<State, Event, EffectKind> {
  associatedtype State: AnyState
  associatedtype Event
  associatedtype EffectKind
  
  func transition(from state: State, event: Event) -> TransitionResult<State, Event, EffectKind>
}

///
/// The goal of this type is to specify the system's intent to perform an Effect without having to specify its concrete implementation.
///
struct EffectInvocation<EffectKind, Event> {
  var kind: EffectKind
  var identifier: String
  var onCompletion: ((Result<[Event], Error>) -> Void)?
  var onCancel: (() -> Void)?
}
