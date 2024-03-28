//
//  TransitionProtocol.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

protocol AnyIdentifiableInvocation {
  var id: String { get }
}

protocol AnyCancellableInvocation: AnyIdentifiableInvocation {

}

protocol AnyEffectInvocation: AnyIdentifiableInvocation {
  associatedtype Cancellable: AnyCancellableInvocation
}

struct TransitionResult<State, Invocation: AnyEffectInvocation> {
  let state: State
  let invocations: [EffectInvocation<Invocation>]

  init(state: State, invocations: [EffectInvocation<Invocation>] = []) {
    self.state = state
    self.invocations = invocations
  }
}

enum EffectInvocation<Invocation: AnyEffectInvocation> {
  case managed(_ invocation: Invocation)
  case regular(_ invocation: Invocation)
  case cancel(_ invocation: Invocation.Cancellable)
}

protocol TransitionProtocol<State, Event, Invocation> {
  associatedtype State
  associatedtype Event
  associatedtype Invocation: AnyEffectInvocation

  func canTransition(from state: State, dueTo event: Event) -> Bool
  func transition(from state: State, event: Event) -> TransitionResult<State, Invocation>
}
