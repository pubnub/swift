//
//  SubscribeTransition.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class SubscribeTransition: TransitionProtocol {
  typealias State = (any SubscribeState)
  typealias Event = Subscribe.Event
  typealias Invocation = Subscribe.Invocation

  // swiftlint:disable:next cyclomatic_complexity
  func canTransition(from state: State, dueTo event: Event) -> Bool {
    switch event {
    case .handshakeSuccess:
      return state is Subscribe.HandshakingState
    case .handshakeFailure:
      return state is Subscribe.HandshakingState
    case .handshakeReconnectSuccess:
      return state is Subscribe.HandshakeReconnectingState
    case .handshakeReconnectFailure:
      return state is Subscribe.HandshakeReconnectingState
    case .handshakeReconnectGiveUp:
      return state is Subscribe.HandshakeReconnectingState
    case .receiveSuccess:
      return state is Subscribe.ReceivingState
    case .receiveFailure:
      return state is Subscribe.ReceivingState
    case .receiveReconnectSuccess:
      return state is Subscribe.ReceiveReconnectingState
    case .receiveReconnectFailure:
      return state is Subscribe.ReceiveReconnectingState
    case .receiveReconnectGiveUp:
      return state is Subscribe.ReceiveReconnectingState
    case .subscriptionChanged:
      return true
    case .subscriptionRestored:
      return true
    case .unsubscribeAll:
      return true
    case .disconnect:
      return !(
        state is Subscribe.HandshakeStoppedState || state is Subscribe.ReceiveStoppedState ||
        state is Subscribe.HandshakeFailedState || state is Subscribe.ReceiveFailedState ||
        state is Subscribe.UnsubscribedState
      )
    case .reconnect:
      return (
        state is Subscribe.HandshakeStoppedState || state is Subscribe.HandshakeFailedState ||
        state is Subscribe.ReceiveFailedState || state is Subscribe.ReceiveStoppedState
      )
    }
  }

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
            channels: state.input.allSubscribedChannelNames,
            groups: state.input.allSubscribedGroupNames
          )
        )
      ]
    case let state as Subscribe.HandshakeReconnectingState:
      return [
        .managed(
          .handshakeReconnect(
            channels: state.input.allSubscribedChannelNames,
            groups: state.input.allSubscribedGroupNames,
            retryAttempt: state.retryAttempt,
            reason: state.reason
          )
        )
      ]
    case let state as Subscribe.ReceivingState:
      return [
        .managed(
          .receiveMessages(
            channels: state.input.allSubscribedChannelNames,
            groups: state.input.allSubscribedGroupNames,
            cursor: state.cursor
          )
        )
      ]
    case let state as Subscribe.ReceiveReconnectingState:
      return [
        .managed(
          .receiveReconnect(
            channels: state.input.allSubscribedChannelNames,
            groups: state.input.allSubscribedGroupNames,
            cursor: state.cursor,
            retryAttempt: state.retryAttempt,
            reason: state.reason
          )
        )
      ]
    default:
      return []
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  func transition(from state: State, event: Event) -> TransitionResult<State, Invocation> {
    var results: TransitionResult<State, Invocation>

    switch event {
    case let .handshakeSuccess(cursor):
      results = setReceivingState(from: state, cursor: resolveCursor(for: state, new: cursor))
    case let .handshakeFailure(error):
      results = setHandshakeReconnectingState(from: state, error: error)
    case let .handshakeReconnectSuccess(cursor):
      results = setReceivingState(from: state, cursor: resolveCursor(for: state, new: cursor))
    case let .handshakeReconnectFailure(error):
      results = setHandshakeReconnectingState(from: state, error: error)
    case let .handshakeReconnectGiveUp(error):
      results = setHandshakeFailedState(from: state, error: error)
    case let .receiveSuccess(cursor, messages):
      results = setReceivingState(from: state, cursor: cursor, messages: messages)
    case .receiveFailure(let error):
      results = setReceiveReconnectingState(from: state, error: error)
    case let .receiveReconnectSuccess(cursor, messages):
      results = setReceivingState(from: state, cursor: cursor, messages: messages)
    case let .receiveReconnectFailure(error):
      results = setReceiveReconnectingState(from: state, error: error)
    case let .receiveReconnectGiveUp(error):
      results = setReceiveFailedState(from: state, error: error)
    case let .subscriptionChanged(channels, groups):
      results = onSubscriptionAltered(from: state, channels: channels, groups: groups, cursor: state.cursor)
    case let .subscriptionRestored(channels, groups, cursor):
      results = onSubscriptionAltered(from: state, channels: channels, groups: groups, cursor: cursor)
    case .disconnect:
      results = setStoppedState(from: state)
    case .unsubscribeAll:
      results = setUnsubscribedState(from: state)
    case let .reconnect(cursor):
      results = setHandshakingState(from: state, cursor: cursor)
    }

    return TransitionResult(
      state: results.state,
      invocations: onExit(from: state) + results.invocations + onEntry(to: results.state)
    )
  }

  private func resolveCursor(
    for currentState: State,
    new cursor: SubscribeCursor
  ) -> SubscribeCursor {
    if currentState.hasTimetoken {
      return SubscribeCursor(
        timetoken: currentState.cursor.timetoken,
        region: cursor.region
      )
    }
    return cursor
  }
}

fileprivate extension SubscribeTransition {
  // swiftlint:disable:next cyclomatic_complexity
  func onSubscriptionAltered(
    from state: State,
    channels: [String],
    groups: [String],
    cursor: SubscribeCursor
  ) -> TransitionResult<State, Invocation> {
    let newInput = SubscribeInput(
      channels: channels.map { PubNubChannel(channel: $0) },
      groups: groups.map { PubNubChannel(channel: $0) }
    )

    if newInput.isEmpty {
      return setUnsubscribedState(from: state)
    } else {
      switch state {
      case is Subscribe.HandshakingState:
        return TransitionResult(state: Subscribe.HandshakingState(input: newInput, cursor: cursor))
      case is Subscribe.HandshakeReconnectingState:
        return TransitionResult(state: Subscribe.HandshakingState(input: newInput, cursor: cursor))
      case is Subscribe.HandshakeStoppedState:
        return TransitionResult(state: Subscribe.HandshakeStoppedState(input: newInput, cursor: cursor))
      case is Subscribe.HandshakeFailedState:
        return TransitionResult(state: Subscribe.HandshakingState(input: newInput, cursor: cursor))
      case is Subscribe.ReceivingState:
        return TransitionResult(state: Subscribe.ReceivingState(input: newInput, cursor: cursor))
      case is Subscribe.ReceiveReconnectingState:
        return TransitionResult(state: Subscribe.ReceivingState(input: newInput, cursor: cursor))
      case is Subscribe.ReceiveStoppedState:
        return TransitionResult(state: Subscribe.ReceiveStoppedState(input: newInput, cursor: cursor))
      case is Subscribe.ReceiveFailedState:
        return TransitionResult(state: Subscribe.HandshakingState(input: newInput, cursor: cursor))
      case is Subscribe.UnsubscribedState:
        return TransitionResult(state: Subscribe.HandshakingState(input: newInput, cursor: cursor))
      default:
        return TransitionResult(state: state)
      }
    }
  }
}

fileprivate extension SubscribeTransition {
  func setHandshakingState(from state: State, cursor: SubscribeCursor?) -> TransitionResult<State, Invocation> {
    TransitionResult(
      state: Subscribe.HandshakingState(
        input: state.input,
        cursor: cursor ?? state.cursor
      )
    )
  }
}

fileprivate extension SubscribeTransition {
  func setHandshakeReconnectingState(
    from state: State,
    error: PubNubError
  ) -> TransitionResult<State, Invocation> {
    return TransitionResult<State, Invocation>(
      state: Subscribe.HandshakeReconnectingState(
        input: state.input,
        cursor: state.cursor,
        retryAttempt: ((state as? Subscribe.HandshakeReconnectingState)?.retryAttempt ?? -1) + 1,
        reason: error
      )
    )
  }
}

fileprivate extension SubscribeTransition {
  func setHandshakeFailedState(
    from state: State,
    error: PubNubError
  ) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Subscribe.HandshakeFailedState(
        input: state.input,
        cursor: state.cursor,
        error: error
      ), invocations: [
        .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
          oldStatus: state.connectionStatus,
          newStatus: .connectionError(error),
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
    let emitMessagesInvocation = EffectInvocation.managed(
      Subscribe.Invocation.emitMessages(events: messages, forCursor: cursor)
    )
    let emitStatusInvocation = EffectInvocation.regular(
      Subscribe.Invocation.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: state.connectionStatus,
        newStatus: .connected,
        error: nil
      ))
    )

    if state is Subscribe.HandshakingState || state is Subscribe.HandshakeReconnectingState {
      return TransitionResult(
        state: Subscribe.ReceivingState(input: state.input, cursor: cursor),
        invocations: [messages.isEmpty ? nil : emitMessagesInvocation, emitStatusInvocation].compactMap { $0 }
      )
    } else {
      return TransitionResult(
        state: Subscribe.ReceivingState(input: state.input, cursor: cursor),
        invocations: [messages.isEmpty ? nil : emitMessagesInvocation].compactMap { $0 }
      )
    }
  }
}

fileprivate extension SubscribeTransition {
  func setReceiveReconnectingState(
    from state: State,
    error: PubNubError
  ) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Subscribe.ReceiveReconnectingState(
        input: state.input,
        cursor: state.cursor,
        retryAttempt: ((state as? Subscribe.ReceiveReconnectingState)?.retryAttempt ?? -1) + 1,
        reason: error
      )
    )
  }
}

fileprivate extension SubscribeTransition {
  func setReceiveFailedState(
    from state: State,
    error: PubNubError
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
        .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
          oldStatus: state.connectionStatus,
          newStatus: .disconnectedUnexpectedly(error),
          error: error
        )))
      ]
    )
  }
}

fileprivate extension SubscribeTransition {
  func setStoppedState(from state: State) -> TransitionResult<State, Invocation> {
    let invocations: [EffectInvocation<Invocation>] = [
      .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
        oldStatus: state.connectionStatus,
        newStatus: .disconnected,
        error: nil
      )))
    ]
    let handshakeStoppedTransition: TransitionResult<State, Invocation> = TransitionResult(
      state: Subscribe.HandshakeStoppedState(input: state.input, cursor: state.cursor),
      invocations: invocations
    )
    let receiveStoppedTransition: TransitionResult<State, Invocation> = TransitionResult(
      state: Subscribe.ReceiveStoppedState(input: state.input, cursor: state.cursor),
      invocations: invocations
    )

    switch state {
    case is Subscribe.HandshakingState:
      return handshakeStoppedTransition
    case is Subscribe.HandshakeReconnectingState:
      return handshakeStoppedTransition
    case is Subscribe.ReceivingState:
      return receiveStoppedTransition
    case is Subscribe.ReceiveReconnectingState:
      return receiveStoppedTransition
    default:
      return TransitionResult(state: state)
    }
  }
}

fileprivate extension SubscribeTransition {
  func setUnsubscribedState(from state: State) -> TransitionResult<State, Invocation> {
    return TransitionResult(
      state: Subscribe.UnsubscribedState(),
      invocations: [
        .regular(.emitStatus(change: Subscribe.ConnectionStatusChange(
          oldStatus: state.connectionStatus,
          newStatus: .disconnected,
          error: nil
        )))
      ]
    )
  }
}
