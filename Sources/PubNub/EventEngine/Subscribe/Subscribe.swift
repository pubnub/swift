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
    let connectionStatus = ConnectionStatus.disconnected
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
    let reason: SubscribeError
    let connectionStatus = ConnectionStatus.disconnected
  }
  
  struct HandshakeFailedState: SubscribeState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
    let error: SubscribeError
    let connectionStatus = ConnectionStatus.disconnected
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
    let reason: SubscribeError
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
    let error: SubscribeError
    let connectionStatus = ConnectionStatus.disconnected
  }
  
  struct UnsubscribedState: SubscribeState {
    let cursor: SubscribeCursor = SubscribeCursor(timetoken: 0)!
    let input: SubscribeInput = SubscribeInput()
    let connectionStatus = ConnectionStatus.disconnected
  }
}

// MARK: - Subscribe Events

extension Subscribe {
  enum Event {
    case subscriptionChanged(channels: [String], groups: [String])
    case subscriptionRestored(channels: [String], groups: [String], cursor: SubscribeCursor)
    case handshakeSuccess(cursor: SubscribeCursor)
    case handshakeFailure(error: SubscribeError)
    case handshakeReconnectSuccess(cursor: SubscribeCursor)
    case handshakeReconnectFailure(error: SubscribeError)
    case handshakeReconnectGiveUp(error: SubscribeError)
    case receiveSuccess(cursor: SubscribeCursor, messages: [SubscribeMessagePayload])
    case receiveFailure(error: SubscribeError)
    case receiveReconnectSuccess(cursor: SubscribeCursor, messages: [SubscribeMessagePayload])
    case receiveReconnectFailure(error: SubscribeError)
    case receiveReconnectGiveUp(error: SubscribeError)
    case disconnect
    case reconnect
    case unsubscribeAll
  }
}

extension Subscribe {
  struct ConnectionStatusChange: Equatable {
    let oldStatus: ConnectionStatus
    let newStatus: ConnectionStatus
    let error: SubscribeError?
  }
}

extension Subscribe {
  struct Dependencies {
    let configuration: SubscriptionConfiguration
    let listeners: [BaseSubscriptionListener]
    
    init(configuration: SubscriptionConfiguration, listeners: [BaseSubscriptionListener] = []) {
      self.configuration = configuration
      self.listeners = listeners
    }
  }
}

// MARK: - Subscribe Effect Invocations

extension Subscribe {
  enum Invocation: AnyEffectInvocation {
    case handshakeRequest(channels: [String], groups: [String])
    case handshakeReconnect(channels: [String], groups: [String], retryAttempt: Int, reason: SubscribeError)
    case receiveMessages(channels: [String], groups: [String], cursor: SubscribeCursor)
    case receiveReconnect(channels: [String], groups: [String], cursor: SubscribeCursor, retryAttempt: Int, reason: SubscribeError)
    case emitStatus(change: Subscribe.ConnectionStatusChange)
    case emitMessages(events: [SubscribeMessagePayload], forCursor: SubscribeCursor)
    
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
      case .handshakeRequest(_, _):
        return Cancellable.handshakeRequest.id
      case .handshakeReconnect(_, _, _, _):
        return Cancellable.handshakeReconnect.id
      case .receiveMessages(_, _, _):
        return Cancellable.receiveMessages.id
      case .receiveReconnect(_, _, _, _, _):
        return Cancellable.receiveReconnect.id
      case .emitMessages(_,_):
        return "Subscribe.EmitMessages"
      case .emitStatus(_):
        return "Subscribe.EmitStatus"
      }
    }
  }
}
