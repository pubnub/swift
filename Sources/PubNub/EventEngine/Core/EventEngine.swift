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

protocol AnyEffectInvocation: Equatable {
  associatedtype Cancellable: RawRepresentable<String>
  
  var id: String { get }
}

class EventEngine<State, Event, Invocation: AnyEffectInvocation> {
  private let transition: any TransitionProtocol<State, Event, Invocation>
  private let dispatcher: any Dispatcher<Invocation, Event>
  private let queue: DispatchQueue
  
  private(set) var currentState: State
  
  init(
    queue: DispatchQueue,
    state: State,
    transition: some TransitionProtocol<State, Event, Invocation>,
    dispatcher: some Dispatcher<Invocation, Event>
  ) {
    self.queue = queue
    self.currentState = state
    self.transition = transition
    self.dispatcher = dispatcher
  }
  
  func send(event: Event, completionBlock: (() -> Void)? = nil) {
    queue.async { [weak self] in
      self?.process(event: event, completionBlock: completionBlock)
    }
  }
  
  private func process(event: Event, completionBlock: (() -> Void)?) {
    let transitionResult = transition.transition(from: currentState, event: event)
    let invocations = transitionResult.invocations
    
    currentState = transitionResult.state
    
    let listener = DispatcherListener<Event>(
      onAllInvocationsCompleted: completionBlock ?? {},
      onAnyInvocationCompleted: { [weak self] _, results in
        results.forEach {
          self?.send(event: $0, completionBlock: completionBlock)
        }
      }
    )
    
    dispatcher.dispatch(
      invocations: invocations,
      notify: listener
    )
  }
}
