//
//  Subscribe.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - SubscribeState

protocol SubscribeState: Equatable {
  var input: SubscribeInput { get }
  var cursor: SubscribeCursor { get }
  var connectionStatus: ConnectionStatus { get }
}

extension SubscribeState {
  var hasTimetoken: Bool {
    cursor.timetoken != 0
  }
}

//
// A namespace for Events, concrete State types and Invocations used in Subscribe EE
//
enum Subscribe {}

// MARK: - Subscribe States

extension Subscribe {
  struct HandshakingState: SubscribeState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
    let connectionStatus = ConnectionStatus.connecting
  }

  struct HandshakeStoppedState: SubscribeState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
    let connectionStatus = ConnectionStatus.disconnected
  }

  struct HandshakeReconnectingState: SubscribeState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
    let retryAttempt: Int
    let reason: PubNubError
    let connectionStatus = ConnectionStatus.connecting
  }

  struct HandshakeFailedState: SubscribeState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
    let error: PubNubError
    let connectionStatus: ConnectionStatus

    init(input: SubscribeInput, cursor: SubscribeCursor, error: PubNubError) {
      self.input = input
      self.cursor = cursor
      self.error = error
      self.connectionStatus = .connectionError(error)
    }
  }

  struct ReceivingState: SubscribeState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
    let connectionStatus = ConnectionStatus.connected
  }

  struct ReceiveReconnectingState: SubscribeState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
    let retryAttempt: Int
    let reason: PubNubError
    let connectionStatus = ConnectionStatus.connected
  }

  struct ReceiveStoppedState: SubscribeState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
    let connectionStatus = ConnectionStatus.disconnected
  }

  struct ReceiveFailedState: SubscribeState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
    let error: PubNubError
    let connectionStatus: ConnectionStatus

    init(input: SubscribeInput, cursor: SubscribeCursor, error: PubNubError) {
      self.input = input
      self.cursor = cursor
      self.error = error
      self.connectionStatus = .disconnectedUnexpectedly(error)
    }
  }

  struct UnsubscribedState: SubscribeState {
    // swiftlint:disable:next force_unwrapping
    let cursor: SubscribeCursor = .init(timetoken: 0)!
    let input: SubscribeInput = .init()
    let connectionStatus = ConnectionStatus.disconnected
  }
}

// MARK: - Subscribe Events

extension Subscribe {
  enum Event {
    case subscriptionChanged(channels: [String], groups: [String])
    case subscriptionRestored(channels: [String], groups: [String], cursor: SubscribeCursor)
    case handshakeSuccess(cursor: SubscribeCursor)
    case handshakeFailure(error: PubNubError)
    case handshakeReconnectSuccess(cursor: SubscribeCursor)
    case handshakeReconnectFailure(error: PubNubError)
    case handshakeReconnectGiveUp(error: PubNubError)
    case receiveSuccess(cursor: SubscribeCursor, messages: [SubscribeMessagePayload])
    case receiveFailure(error: PubNubError)
    case receiveReconnectSuccess(cursor: SubscribeCursor, messages: [SubscribeMessagePayload])
    case receiveReconnectFailure(error: PubNubError)
    case receiveReconnectGiveUp(error: PubNubError)
    case disconnect
    case reconnect(cursor: SubscribeCursor?)
    case unsubscribeAll
  }
}

extension Subscribe {
  struct ConnectionStatusChange: Equatable {
    let oldStatus: ConnectionStatus
    let newStatus: ConnectionStatus
    let error: PubNubError?
  }
}

extension Subscribe {
  struct Dependencies {
    let configuration: PubNubConfiguration
    let listeners: [BaseSubscriptionListener]

    init(configuration: PubNubConfiguration, listeners: [BaseSubscriptionListener] = []) {
      self.configuration = configuration
      self.listeners = listeners
    }
  }
}

// MARK: - Subscribe Effect Invocations

extension Subscribe {
  enum Invocation: AnyEffectInvocation {
    case handshakeRequest(channels: [String], groups: [String])
    case handshakeReconnect(channels: [String], groups: [String], retryAttempt: Int, reason: PubNubError)
    case receiveMessages(channels: [String], groups: [String], cursor: SubscribeCursor)
    case receiveReconnect(channels: [String], groups: [String], cursor: SubscribeCursor, retryAttempt: Int, reason: PubNubError)
    case emitStatus(change: Subscribe.ConnectionStatusChange)
    case emitMessages(events: [SubscribeMessagePayload], forCursor: SubscribeCursor)

    // swiftlint:disable:next nesting
    enum Cancellable: AnyCancellableInvocation {
      case handshakeRequest
      case handshakeReconnect
      case receiveMessages
      case receiveReconnect

      var id: String {
        switch self {
        case .handshakeRequest:
          return "Subscribe.HandshakeRequest"
        case .handshakeReconnect:
          return "Subscribe.HandshakeReconnect"
        case .receiveMessages:
          return "Subscribe.ReceiveMessages"
        case .receiveReconnect:
          return "Subscribe.ReceiveReconnect"
        }
      }
    }

    var id: String {
      switch self {
      case .handshakeRequest:
        return Cancellable.handshakeRequest.id
      case .handshakeReconnect:
        return Cancellable.handshakeReconnect.id
      case .receiveMessages:
        return Cancellable.receiveMessages.id
      case .receiveReconnect:
        return Cancellable.receiveReconnect.id
      case .emitMessages:
        return "Subscribe.EmitMessages"
      case .emitStatus:
        return "Subscribe.EmitStatus"
      }
    }
  }
}
