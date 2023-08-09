//
//  PubNubEventEngineTestsHelpers.swift
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

@testable import PubNub

protocol ContractTestIdentifiable {
  var contractTestIdentifier: String { get }
}

extension EffectInvocation: ContractTestIdentifiable where Invocation: ContractTestIdentifiable, Invocation.Cancellable: ContractTestIdentifiable {
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
    with customInput: EventEngineCustomInput<Input>,
    notify listener: DispatcherListener<Event>
  ) {
    recordedInvocations += invocations
    wrappedInstance.dispatch(invocations: invocations, with: customInput, notify: listener)
  }
}

class TransitionDecorator<State, Event, Invocation: AnyEffectInvocation>: TransitionProtocol {
  private let wrappedInstance: any TransitionProtocol<State, Event, Invocation>
  private(set) var recordedEvents: [Event]
   
  init(wrappedInstance: some TransitionProtocol<State, Event, Invocation>) {
    self.wrappedInstance = wrappedInstance
    self.recordedEvents = []
  }
  
  func transition(from state: State, event: Event) -> TransitionResult<State, Invocation> {
    recordedEvents.append(event)
    return wrappedInstance.transition(from: state, event: event)
  }
}
