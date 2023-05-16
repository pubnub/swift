//
//  SubscribeState.swift
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

protocol SubscribeState: Equatable {
  var input: SubscribeInput { get }
}

protocol CursorState: SubscribeState {
  var cursor: SubscribeCursor { get }
}

struct SubscribeInput: Equatable {
  let channels: [String]
  let groups: [String]
  
  init(channels: [String] = [], groups: [String] = []) {
    self.channels = channels
    self.groups = groups
  }
  
  static func == (lhs: SubscribeInput, rhs: SubscribeInput) -> Bool {
    return lhs.channels == rhs.channels && lhs.groups == rhs.groups
  }
}

struct SubscribeError: Error, Equatable {
  let underlying: PubNubError
  let urlResponse: HTTPURLResponse?
  
  init(underlying: PubNubError, urlResponse: HTTPURLResponse? = nil) {
    self.underlying = underlying
    self.urlResponse = urlResponse
  }
  
  static func == (lhs: SubscribeError, rhs: SubscribeError) -> Bool {
    lhs.underlying == rhs.underlying
  }
}

extension Subscribe {
  struct HandshakingState: SubscribeState {
    let input: SubscribeInput
  }
  
  struct HandshakeStoppedState: SubscribeState {
    let input: SubscribeInput
  }
  
  struct HandshakeReconnectingState: SubscribeState {
    let input: SubscribeInput
    let currentAttempt: Int
  }
  
  struct HandshakeFailedState: SubscribeState {
    let input: SubscribeInput
    let error: SubscribeError
  }
  
  struct ReceivingState: SubscribeState, CursorState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
  }
  
  struct ReceiveReconnectingState: SubscribeState, CursorState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
    let currentAttempt: Int
  }
  
  struct ReceiveStoppedState: SubscribeState, CursorState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
  }
  
  struct ReceiveFailedState: SubscribeState, CursorState {
    let input: SubscribeInput
    let cursor: SubscribeCursor
    let error: SubscribeError
  }
  
  struct UnsubscribedState: SubscribeState {
    let input: SubscribeInput
  }
}
