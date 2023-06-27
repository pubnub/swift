//
//  EventEngine.swift
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

protocol AnyEffectInvocation: Equatable, RawRepresentable<String> {
  associatedtype Cancellable: RawRepresentable<String>
}

protocol EventEngineDelegate<State>: AnyObject {
  associatedtype State
  
  func onStateUpdated(state: State)
}

struct EventEngineCustomInput<Value> {
  let value: Value
}

class EventEngine<State, Event, Invocation: AnyEffectInvocation, Input> {
  private let transition: any TransitionProtocol<State, Event, Invocation>
  private let dispatcher: any Dispatcher<Invocation, Event, Input>
  private let queue: DispatchQueue
  private let currentState: Atomic<State>
  
  var customInput: EventEngineCustomInput<Input>
  // A delegate that's notified when the State object is replaced
  weak var delegate: (any EventEngineDelegate)?
  
  init(
    queue: DispatchQueue,
    state: State,
    transition: some TransitionProtocol<State, Event, Invocation>,
    dispatcher: some Dispatcher<Invocation, Event, Input>,
    customInput: EventEngineCustomInput<Input>
  ) {
    self.queue = queue
    self.currentState = Atomic(state)
    self.transition = transition
    self.dispatcher = dispatcher
    self.customInput = customInput
  }
  
  var state: State {
    currentState.lockedRead { $0 }
  }
  
  func send(event: Event) {
    defer { objc_sync_exit(self) }
    objc_sync_enter(self)
    process(event: event)
  }
  
  private func process(event: Event) {
    let state = currentState.lockedRead { $0 }
    let transitionResult = transition.transition(from: state, event: event)
    let invocations = transitionResult.invocations
    
    currentState.lockedWrite { $0 = transitionResult.state }
    
    let listener = DispatcherListener<Event>(
      onAnyInvocationCompleted: { [weak self] results in
        results.forEach {
          self?.send(event: $0)
        }
      }
    )
    
    dispatcher.dispatch(
      invocations: invocations,
      with: customInput,
      notify: listener
    )
  }
}
