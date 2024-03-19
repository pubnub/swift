//
//  PubNubEventEngineTestHelpers.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@testable import PubNub

protocol ContractTestIdentifiable {
  var contractTestIdentifier: String { get }
}

extension EffectInvocation: ContractTestIdentifiable where
  Invocation: ContractTestIdentifiable,
  Invocation.Cancellable: ContractTestIdentifiable
{
  var contractTestIdentifier: String {
    switch self {
    case .managed(let invocation):
      return invocation.contractTestIdentifier
    case .cancel(let cancellable):
      return cancellable.contractTestIdentifier
    case .regular(let invocation):
      return invocation.contractTestIdentifier
    }
  }
}

class DispatcherDecorator<Invocation: AnyEffectInvocation, Event, Input>: Dispatcher {
  private let wrappedInstance: any Dispatcher<Invocation, Event, Input>
  private(set) var recordedInvocations: [EffectInvocation<Invocation>]

  init(wrappedInstance: some Dispatcher<Invocation, Event, Input>) {
    self.wrappedInstance = wrappedInstance
    self.recordedInvocations = []
  }

  func dispatch(
    invocations: [EffectInvocation<Invocation>],
    with dependencies: EventEngineDependencies<Input>,
    notify listener: DispatcherListener<Event>
  ) {
    recordedInvocations += invocations
    wrappedInstance.dispatch(invocations: invocations, with: dependencies, notify: listener)
  }
}

class TransitionDecorator<State, Event, Invocation: AnyEffectInvocation>: TransitionProtocol {
  private let wrappedInstance: any TransitionProtocol<State, Event, Invocation>
  private(set) var recordedEvents: [Event]

  init(wrappedInstance: some TransitionProtocol<State, Event, Invocation>) {
    self.wrappedInstance = wrappedInstance
    self.recordedEvents = []
  }

  func canTransition(from state: State, dueTo event: Event) -> Bool {
    wrappedInstance.canTransition(from: state, dueTo: event)
  }

  func transition(from state: State, event: Event) -> TransitionResult<State, Invocation> {
    recordedEvents.append(event)
    return wrappedInstance.transition(from: state, event: event)
  }
}
