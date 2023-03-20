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

///
/// Protocol for any type that can take and dispatch an `Event`
///
protocol EventDispatcher<Event> {
  associatedtype Event
  
  func send(event: Event)
}

///
/// The class that represents the Event Engine.
/// This class provides a template that allows a caller to specify the concrete types for Event Engine like its State, possible Actions to take, or Effects kind that this Engine produces.
/// See the `Showcase.swift` file in order to see the example usage.
///
class EventEngine<State: AnyState, Event, EffectKind>: EventDispatcher {
  var transition: any TransitionProtocol<State, Event, EffectKind>
  var dispatcher: any Dispatcher<EffectKind, Event>
  var currentState: State
  
  init(
    state: State,
    transition: some TransitionProtocol<State, Event, EffectKind>,
    dispatcher: some Dispatcher<EffectKind, Event>
  ) {
    self.transition = transition
    self.currentState = state
    self.dispatcher = dispatcher
  }
  
  func send(event: Event) {
    let result = transition.transition(
      from: currentState,
      event: event
    )
    
    currentState = result.state
    
    dispatcher.dispatch(
      invocations: result.invocations,
      eventDispatcher: self
    )
  }
}
