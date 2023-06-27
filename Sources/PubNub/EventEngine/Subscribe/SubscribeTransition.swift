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
  
  private func onExit(from state: State) -> [EffectInvocation<Invocation>] {
    switch state {
    case is Subscribe.HandshakingState:
      return [.cancel(.handshakeRequest)]
    case is Subscribe.HandshakeReconnectingState:
      return [.cancel(.handshakeReconnect)]
    case is Subscribe.ReceivingState:
      return [.cancel(.receiveMessages)]
    case is Subscribe.ReceiveReconnectingState:
      return [.cancel(.receiveReconnect)]
    default:
      return []
    }
  }
  
  private func onEntry(to state: State) -> [EffectInvocation<Invocation>] {
    switch state {
    case let state as Subscribe.HandshakingState:
      return [
        .managed(
          .handshakeRequest(
            channels: state.input.allSubscribedChannels,
            groups: state.input.allSubscribedGroups
          )
        )
      ]
    case let state as Subscribe.HandshakeReconnectingState:
      return [
        .managed(
          .handshakeReconnect(
            channels: state.input.allSubscribedChannels,
            groups: state.input.allSubscribedGroups,
            currentAttempt: state.currentAttempt,
            reason: state.reason
          )
        )
      ]
    case let state as Subscribe.ReceivingState:
      return [
        .managed(
          .receiveMessages(
            channels: state.input.allSubscribedChannels,
            groups: state.input.allSubscribedGroups,
            cursor: state.cursor
          )
        )
      ]
    case let state as Subscribe.ReceiveReconnectingState:
      return [
        .managed(
          .receiveReconnect(
            channels: state.input.allSubscribedChannels,
            groups: state.input.allSubscribedGroups,
            cursor: state.cursor,
            currentAttempt: state.currentAttempt,
            reason: state.reason
          )
        )
      ]
    default:
      return []
    }
  }
  
  private func canTransition(from state: State, dueTo event: Event) -> Bool {
    switch event {
    case .handshakeSucceess(_):
      return state is Subscribe.HandshakingState
    case .handshakeFailure(_):
      return state is Subscribe.HandshakingState
    case .handshakeReconnectSuccess(_):
      return state is Subscribe.HandshakeReconnectingState
    case .handshakeReconnectFailure(_):
      return state is Subscribe.HandshakeReconnectingState
    case .handshakeReconnectGiveUp(_):
      return state is Subscribe.HandshakeReconnectingState
    case .receiveSuccess(_,_):
      return state is Subscribe.ReceivingState
    case .receiveFailure(_):
      return state is Subscribe.ReceivingState
    case .receiveReconnectSuccess(_,_):
      return state is Subscribe.ReceiveReconnectingState
    case .receiveReconnectFailure(_):
      return state is Subscribe.ReceiveReconnectingState
    case .receiveReconnectGiveUp(_):
      return state is Subscribe.ReceiveReconnectingState
    case .subscriptionChanged(_, _):
      return true
    case .subscriptionRestored(_, _, _):
      return true
    case .unsubscribeAll:
      return true
    case .disconnect:
      return !(
        state is Subscribe.HandshakeStoppedState || state is Subscribe.ReceiveStoppedState ||
        state is Subscribe.HandshakeFailedState || state is Subscribe.ReceiveFailedState
      )
    case .reconnect:
      return (
        state is Subscribe.HandshakeStoppedState || state is Subscribe.HandshakeFailedState ||
        state is Subscribe.ReceiveFailedState || state is Subscribe.ReceiveStoppedState
      )
    }
  }
  
  func transition(from state: State, event: Event) -> TransitionResult<State, Invocation> {
    guard canTransition(from: state, dueTo: event) else {
      return TransitionResult(state: state)
    }
    var results: TransitionResult<State, Invocation>
    
    switch event {
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
      results = onSubscriptionChanged(from: state, channels: channels, groups: groups)
    case .subscriptionRestored(let channels, let groups, let cursor):
      results = onSubscriptionRestored(from: state, channels: channels, groups: groups, cursor: cursor)
    case .disconnect:
      results = setStoppedState(from: state)
    case .unsubscribeAll:
      results = setUnsubscribedState(from: state)
    case .reconnect:
      results = state.hasTimetoken ? setReceivingState(from: state, cursor: state.cursor) : setHandshakingState(from: state)
    }
    
    return TransitionResult(
      state: results.state,
      invocations: onExit(from: state) + onEntry(to: results.state) + results.invocations
    )
  }
}

fileprivate extension SubscribeTransition {
  func onSubscriptionChanged(
    from state: State,
    channels: [String],
    groups: [String]
  ) -> TransitionResult<State, Invocation> {
    guard !channels.isEmpty || !groups.isEmpty else {
      return setUnsubscribedState(from: state)
    }
    let newInput = SubscribeInput(
      channels: channels.map { PubNubChannel(id: $0, withPresence: $0.isPresenceChannelName) },
      groups: groups.map { PubNubChannel(id: $0, withPresence: $0.isPresenceChannelName) },
      filterExpression: state.input.filterExpression
    )
    if state.hasTimetoken {
      return TransitionResult(state: Subscribe.ReceivingState(
        input: newInput, cursor: state.cursor
      ))
    } else {
      return TransitionResult(state: Subscribe.HandshakingState(input: newInput))
    }
  }
}

fileprivate extension SubscribeTransition {
  func onSubscriptionRestored(
    from state: State,
    channels: [String],
    groups: [String],
    cursor: SubscribeCursor
  ) -> TransitionResult<State, Invocation> {
    guard !channels.isEmpty || !groups.isEmpty else {
      return setUnsubscribedState(from: state)
    }
    let newInput = SubscribeInput(
      channels: channels.map { PubNubChannel(id: $0, withPresence: $0.isPresenceChannelName) },
      groups: groups.map { PubNubChannel(id: $0, withPresence: $0.isPresenceChannelName) },
      filterExpression: state.input.filterExpression
    )
    return TransitionResult(
      state: Subscribe.ReceivingState(
        input: newInput,
        cursor: cursor
      )
    )
  }
}

fileprivate extension SubscribeTransition {
  func setHandshakingState(from state: State) -> TransitionResult<State, Invocation> {
    TransitionResult(state: Subscribe.HandshakingState(input: state.input))
  }
}

fileprivate extension SubscribeTransition {
  func setHandshakeReconnectingState(
    from state: State,
    error: SubscribeError
  ) -> TransitionResult<State, Invocation> {
    return TransitionResult<State, Invocation>(
      state: Subscribe.HandshakeReconnectingState(
        input: state.input,
        currentAttempt: ((state as? Subscribe.HandshakeReconnectingState)?.currentAttempt ?? -1) + 1,
        reason: error
      )
    )
  }
}

fileprivate extension SubscribeTransition {
  func setHandshakeFailedState(
    from state: State,
    error: SubscribeError
  ) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Subscribe.HandshakeFailedState(
        input: state.input,
        error: error
      ), invocations: [
        .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
          oldStatus: state.connectionStatus,
          newStatus: .disconnected,
          error: error
        )))
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
        .managed(.emitMessages(events: messages, forCursor: cursor)),
        .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
          oldStatus: state.connectionStatus,
          newStatus: .connected,
          error: nil
        )))
      ]
    )
  }
}

fileprivate extension SubscribeTransition {
  func setReceiveReconnectingState(
    from state: State,
    error: SubscribeError
  ) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Subscribe.ReceiveReconnectingState(
        input: state.input,
        cursor: state.cursor,
        currentAttempt: ((state as? Subscribe.ReceiveReconnectingState)?.currentAttempt ?? -1) + 1,
        reason: error
      )
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
        .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
          oldStatus: state.connectionStatus,
          newStatus: .disconnected,
          error: nil
        )))
      ]
    )
  }
}

fileprivate extension SubscribeTransition {
  func setStoppedState(from state: State) -> TransitionResult<State, Invocation> {
    let invocations: [EffectInvocation<Invocation>] = [
      .cancel(.handshakeRequest),
      .cancel(.handshakeReconnect),
      .cancel(.receiveMessages),
      .cancel(.receiveReconnect),
      .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: state.connectionStatus,
        newStatus: .disconnected, error: nil
      )))
    ]
    if state.hasTimetoken {
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

fileprivate extension SubscribeTransition {
  func setUnsubscribedState(from state: State) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Subscribe.UnsubscribedState(),
      invocations: [
        .cancel(.handshakeRequest),
        .cancel(.handshakeReconnect),
        .cancel(.receiveMessages),
        .cancel(.receiveReconnect),
        .managed(.emitStatus(change: Subscribe.ConnectionStatusChange(
          oldStatus: state.connectionStatus,
          newStatus: .disconnected,
          error: nil
        )))
      ]
    )
  }
}
