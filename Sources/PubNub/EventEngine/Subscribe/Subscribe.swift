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
  
  enum Invocation: AnyEffectInvocation, Equatable {
    case handshakeRequest(channels: [String], groups: [String])
    case handshakeReconnect(channels: [String], groups: [String], currentAttempt: Int, reason: SubscribeError?)
    case receiveMessages(channels: [String], groups: [String], cursor: SubscribeCursor)
    case receiveReconnect(channels: [String], group: [String], cursor: SubscribeCursor, currentAttempt: Int, reason: SubscribeError?)
    case emitStatus(status: ConnectionStatus)
    case emitMessages(events: [SubscribeMessagePayload], forCursor: SubscribeCursor)
    
    static func == (lhs: Subscribe.Invocation, rhs: Subscribe.Invocation) -> Bool {
      switch (lhs, rhs) {
      case (let .handshakeRequest(lhsChannels, lhsGroups), let .handshakeRequest(rhsChannels, rhsGroups)):
        return lhsChannels == rhsChannels && lhsGroups == rhsGroups
      case (let .handshakeReconnect(lhsC, lhsG, lhsAtt, lhsErr), let .handshakeReconnect(rhsC, rhsG, rhsAtt, rhsErr)):
        return lhsC == rhsC && lhsG == rhsG && lhsAtt == rhsAtt && lhsErr == rhsErr
      case (let .receiveMessages(lhsC, lhsG, lhsCursor), let .receiveMessages(rhsC, rhsG, rhsCursor)):
        return lhsC == rhsC && lhsG == rhsG && lhsCursor == rhsCursor
      case (let .receiveReconnect(lhsC, lhsG, lhsCursor, lhsAtt, lhsErr), let .receiveReconnect(rhsC, rhsG, rhsCursor, rhsAtt, rhsErr)):
        return lhsC == rhsC && lhsG == rhsG && lhsCursor == rhsCursor && lhsAtt == rhsAtt && lhsErr == rhsErr
      case (let .emitStatus(lhsStatus), let .emitStatus(rhsStatus)):
        return lhsStatus == rhsStatus
      case (let .emitMessages(lhsMessages, lhsCursor), let .emitMessages(rhsMessages, rhsCursor)):
        return lhsMessages == rhsMessages && lhsCursor == rhsCursor
      default:
        return false
      }
    }
    
    struct ID {
      static let HandshakeRequest = "Subscribe.HandshakeRequest"
      static let HandshakeReconnect = "Subscribe.HandshakeReconnect"
      static let ReceiveMessages = "Subscribe.ReceiveMessages"
      static let ReceiveReconnect = "Subsribe.ReceiveReconnect"
      static let EmitStatus = "Subscribe.EmitStatus"
      static let EmitMessages = "Subscribe.EmitMessages"
    }
    
    var id: String {
      switch self {
      case .handshakeRequest(_, _):
        return ID.HandshakeRequest
      case .handshakeReconnect(_, _, _, _):
        return ID.HandshakeReconnect
      case .receiveMessages(_, _, _):
        return ID.ReceiveMessages
      case .receiveReconnect(_, _, _, _, _):
        return ID.ReceiveReconnect
      case .emitStatus(_):
        return ID.EmitStatus
      case .emitMessages(_, _):
        return ID.EmitMessages
      }
    }
  }
}
