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
    let connectionStatus: ConnectionStatus
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
    case receiveSuccess(cursor: SubscribeCursor, messages: [SubscribeMessagePayload])
    case receiveFailure(error: PubNubError)
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
    let subscriptions: WeakSet<BaseSubscriptionListener>

    init(
      configuration: PubNubConfiguration,
      listeners: WeakSet<BaseSubscriptionListener> = WeakSet<BaseSubscriptionListener>([])
    ) {
      self.configuration = configuration
      self.subscriptions = listeners
    }
  }
}

// MARK: - Subscribe Effect Invocations

extension Subscribe {
  enum Invocation: AnyEffectInvocation {
    case handshakeRequest(channels: [String], groups: [String])
    case receiveMessages(channels: [String], groups: [String], cursor: SubscribeCursor)
    case emitStatus(change: Subscribe.ConnectionStatusChange)
    case emitMessages(events: [SubscribeMessagePayload], forCursor: SubscribeCursor)

    // swiftlint:disable:next nesting
    enum Cancellable: AnyCancellableInvocation {
      case handshakeRequest
      case receiveMessages

      var id: String {
        switch self {
        case .handshakeRequest:
          return "Subscribe.HandshakeRequest"
        case .receiveMessages:
          return "Subscribe.ReceiveMessages"
        }
      }
    }

    var id: String {
      switch self {
      case .handshakeRequest:
        return Cancellable.handshakeRequest.id
      case .receiveMessages:
        return Cancellable.receiveMessages.id
      case .emitMessages:
        return "Subscribe.EmitMessages"
      case .emitStatus:
        return "Subscribe.EmitStatus"
      }
    }
  }
}
