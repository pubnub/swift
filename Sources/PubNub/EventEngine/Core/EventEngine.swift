//
//  EventEngine.swift
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

///
/// The class that represents the Event Engine.
/// This class provides a template that allows a caller to specify the concrete types for Event Engine like its State, possible Actions to take, or Effects kind that this Engine produces.
/// See the `Showcase.swift` file in order to see the example usage.
///
class EventEngine<State: AnyState, Action, EffectKind> {
  var transition: any TransitionProtocol<State, Action, EffectKind>
  var dispatcher: any Dispatcher<EffectKind, Action>
  var currentState: State
  
  init(
    transition: some TransitionProtocol<State, Action, EffectKind>,
    dispatcher: some Dispatcher<EffectKind, Action>
  ) {
    self.transition = transition
    self.currentState = transition.defaultState()
    self.dispatcher = dispatcher
  }
  
  func send(action: Action) {
    let result = transition.transition(
      from: currentState,
      action: action
    )
    
    currentState = result.state
    
    for var invocation in result.invocations {
      invocation.onCompletion = { [weak self] result in
        switch result {
        case .success(let action):
          if let action = action {
            self?.send(action: action)
          }
        case .failure(let error):
          debugPrint("Error: \(error)")
        }
      }
      invocation.onCancel = {
        debugPrint("On cancel")
      }
    }
    
    dispatcher.dispatch(invocations: result.invocations)
  }
}
