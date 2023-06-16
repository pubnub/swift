//
//  Subscribe.swift
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

enum Subscribe {
  enum Event {
    case subscriptionChanged(channels: [String], groups: [String])
    case subscriptionRestored(channels: [String], gropus: [String], cursor: SubscribeCursor)
    case handshakeSucceess(cursor: SubscribeCursor)
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
  }
  
  enum Invocation: AnyEffectInvocation {
    case handshakeRequest(channels: [String], groups: [String])
    case handshakeReconnect(channels: [String], groups: [String], currentAttempt: Int, reason: SubscribeError?)
    case receiveMessages(channels: [String], groups: [String], cursor: SubscribeCursor)
    case receiveReconnect(channels: [String], group: [String], cursor: SubscribeCursor, currentAttempt: Int, reason: SubscribeError?)
    case emitStatus(status: ConnectionStatus)
    case emitMessages(events: [SubscribeMessagePayload], forCursor: SubscribeCursor)
    
    enum Cancellable: String {
      case handshakeRequest = "Subscribe.HandshakeRequest"
      case handshakeReconnect = "Subscribe.HandshakeReconnect"
      case receiveMessages = "Subscribe.ReceiveMessages"
      case receiveReconnect = "Subscribe.ReceiveReconnect"
    }
    
    var id: String {
      switch self {
      case .handshakeRequest(_, _):
        return Cancellable.handshakeRequest.rawValue
      case .handshakeReconnect(_, _, _, _):
        return Cancellable.handshakeReconnect.rawValue
      case .receiveMessages(_, _, _):
        return Cancellable.receiveMessages.rawValue
      case .receiveReconnect(_, _, _, _, _):
        return Cancellable.receiveReconnect.rawValue
      default:
        return String()
      }
    }
  }
}
