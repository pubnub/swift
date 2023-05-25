//
//  SubscribeTransition.swift
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

class SubscribeTransition: TransitionProtocol {
  typealias State = (any SubscribeState)
  typealias Event = Subscribe.Event
  typealias Invocation = Subscribe.Invocation
  
  private func willExit(from state: State) -> [EffectInvocation<Invocation>] {
    switch state {
    case is Subscribe.HandshakingState:
      return [.cancel(id: Invocation.ID.HandshakeRequest)]
    case is Subscribe.HandshakeReconnectingState:
      return [.cancel(id: Invocation.ID.HandshakeReconnect)]
    case is Subscribe.ReceivingState:
      return [.cancel(id: Invocation.ID.ReceiveMessages)]
    case is Subscribe.ReceiveReconnectingState:
      return [.cancel(id: Invocation.ID.ReceiveReconnect)]
    default:
      return []
    }
  }
  
  func transition(
    from state: State,
    event: Event
  ) -> TransitionResult<State, Invocation> {
    var results: TransitionResult<State, Invocation>
    
    switch event {
    case .reconnect:
      switch state {
      case let state as any CursorState:
        results = setReceivingState(from: state, cursor: state.cursor)
      default:
        results = setHandshakingState(from: state)
      }
    case .handshakeSucceess(let cursor):
      results = setReceivingState(from: state, cursor: cursor)
    case .handshakeFailure(let error):
      results = setHandshakeReconnectingState(from: state, error: error)
    case .handshakeReconnectSuccess(let cursor):
      results = setReceivingState(from: state, cursor: cursor)
    case .handshakeReconnectFailure(let error):
      results = setHandshakeReconnectingState(from: state, error: error)
    case .handshakeReconnectGiveUp(let error):
      results = setHandshakeFailedState(from: state, error: error)
    case .receiveSuccess(let cursor, let messages):
      results = setReceivingState(from: state, cursor: cursor, messages: messages)
    case .receiveFailure(let error):
      results = setReceiveReconnectingState(from: state, error: error)
    case .receiveReconnectSuccess(let cursor, let messages):
      results = setReceivingState(from: state, cursor: cursor, messages: messages)
    case .receiveReconnectFailure(let error):
      results = setReceiveReconnectingState(from: state, error: error)
    case .receiveReconnectGiveUp(let error):
      results = setReceiveFailedState(from: state, error: error)
    case .subscriptionChanged(let channels, let groups):
      results = onSubscriptionChanged(from: state, newChannels: channels, newGroups: groups)
    case .subscriptionRestored(let channels, let groups, let cursor):
      results = onSubscriptionRestored(from: state, newChannels: channels, newGroups: groups, cursor: cursor)
    case .disconnect:
      results = setStoppedState(from: state)
    }
    
    return TransitionResult(
      state: results.state,
      invocations: willExit(from: state) + results.invocations
    )
  }
}

fileprivate extension SubscribeTransition {
  func onSubscriptionChanged(
    from state: State,
    newChannels: [String],
    newGroups: [String]
  ) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Subscribe.HandshakingState(
        input: SubscribeInput(
          channels: newChannels,
          groups: newGroups
        )
      ),
      invocations: [
        .managed(
          invocation: .handshakeRequest(
            channels: newChannels,
            groups: newGroups
          )
        )
      ]
    )
  }
}

fileprivate extension SubscribeTransition {
  func onSubscriptionRestored(
    from state: State,
    newChannels: [String],
    newGroups: [String],
    cursor: SubscribeCursor
  ) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Subscribe.ReceivingState(
        input: SubscribeInput(channels: newChannels, groups: newGroups),
        cursor: cursor
      ),
      invocations: [
        .managed(invocation: .receiveMessages(
          channels: newChannels,
          groups: newGroups,
          cursor: cursor
        ))
      ]
    )
  }
}

fileprivate extension SubscribeTransition {
  func setHandshakingState(from state: State) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Subscribe.HandshakingState(input: state.input),
      invocations: [
        .managed(
          invocation: .handshakeRequest(
            channels: state.input.channels,
            groups: state.input.groups
          )
        )
      ]
    )
  }
}

fileprivate extension SubscribeTransition {
  func setHandshakeReconnectingState(
    from state: State,
    error: SubscribeError?
  ) -> TransitionResult<State, Invocation> {
    guard
      state is Subscribe.HandshakingState ||
      state is Subscribe.HandshakeReconnectingState ||
      state is Subscribe.HandshakeStoppedState
    else {
      return TransitionResult(state: state)
    }
    
    let nextAttempt: Int
    
    if let state = state as? Subscribe.HandshakeReconnectingState {
      nextAttempt = state.currentAttempt + 1
    } else {
      nextAttempt = 0
    }
    
    return TransitionResult<State, Invocation>(
      state: Subscribe.HandshakeReconnectingState(
        input: state.input,
        currentAttempt: nextAttempt
      ),
      invocations: [
        .managed(
          invocation: .handshakeReconnect(
            channels: state.input.channels,
            groups: state.input.groups,
            currentAttempt: nextAttempt,
            reason: error
          )
        )
      ]
    )
  }
}

fileprivate extension SubscribeTransition {
  func setHandshakeFailedState(
    from state: State,
    error: SubscribeError
  ) -> TransitionResult<State, Invocation> {
    guard let state = state as? Subscribe.HandshakeReconnectingState else {
      return TransitionResult(state: state)
    }
    return TransitionResult(
      state: Subscribe.HandshakeFailedState(
        input: state.input,
        error: error
      ), invocations: [
        .managed(invocation: .emitStatus(status: .disconnected))
      ]
    )
  }
}

fileprivate extension SubscribeTransition {
  func setReceivingState(
    from state: State,
    cursor: SubscribeCursor,
    messages: [SubscribeMessagePayload] = []
  ) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Subscribe.ReceivingState(
        input: state.input,
        cursor: cursor
      ),
      invocations: [
        .managed(invocation: .emitStatus(status: .connected)),
        .managed(invocation: .emitMessages(events: messages, forCursor: cursor)),
        .managed(invocation: .receiveMessages(
          channels: state.input.channels,
          groups: state.input.groups,
          cursor: cursor
        ))
      ]
    )
  }
}

fileprivate extension SubscribeTransition {
  func setReceiveReconnectingState(
    from state: State,
    error: SubscribeError?
  ) -> TransitionResult<State, Invocation> {
    guard let state = state as? (any CursorState) else {
      return TransitionResult(state: state)
    }
    
    let nextAttempt: Int
    
    if let state = state as? Subscribe.ReceiveReconnectingState {
      nextAttempt = state.currentAttempt + 1
    } else {
      nextAttempt = 0
    }
        
    return TransitionResult(
      state: Subscribe.ReceiveReconnectingState(
        input: state.input,
        cursor: state.cursor,
        currentAttempt: nextAttempt
      ),
      invocations: [
        .managed(
          invocation: .receiveReconnect(
            channels: state.input.channels,
            group: state.input.groups,
            cursor: state.cursor,
            currentAttempt: nextAttempt,
            reason: error
          )
        )
      ]
    )
  }
}

fileprivate extension SubscribeTransition {
  func setReceiveFailedState(
    from state: State,
    error: SubscribeError
  ) -> TransitionResult<State, Invocation> {
    guard let state = state as? Subscribe.ReceiveReconnectingState else {
      return TransitionResult(state: state)
    }
    return TransitionResult(
      state: Subscribe.ReceiveFailedState(
        input: state.input,
        cursor: state.cursor,
        error: error
      ), invocations: [
        .managed(invocation: .emitStatus(status: .disconnected))
      ]
    )
  }
}

fileprivate extension SubscribeTransition {
  func setStoppedState(from state: State) -> TransitionResult<State, Invocation> {
    let invocations: [EffectInvocation<Invocation>] = [
      .cancel(id: Invocation.ID.HandshakeRequest),
      .cancel(id: Invocation.ID.HandshakeReconnect),
      .cancel(id: Invocation.ID.ReceiveMessages),
      .cancel(id: Invocation.ID.ReceiveReconnect),
      .managed(invocation: .emitStatus(status: .disconnected))
    ]
    if let state = state as? (any CursorState) {
      return TransitionResult(
        state: Subscribe.ReceiveStoppedState(input: state.input, cursor: state.cursor),
        invocations: invocations
      )
    } else {
      return TransitionResult(
        state: Subscribe.HandshakeStoppedState(input: state.input),
        invocations: invocations
      )
    }
  }
}
