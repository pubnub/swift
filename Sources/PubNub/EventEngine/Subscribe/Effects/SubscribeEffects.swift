//
//  SubscribeEffect.swift
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

// MARK: - SubscribeEffect (Common)

protocol SubscribeEffect: EffectHandler {
  var request: SubscribeRequest { get }
  
  func onCompletion(with response: SubscribeResponse) -> Subscribe.Event
  func onFailure(dueTo error: SubscribeError) -> Subscribe.Event
}

extension SubscribeEffect {
  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    request.execute(onCompletion: {
      switch $0 {
      case .success(let response):
        completionBlock([onCompletion(with: response)])
      case .failure(let error):
        completionBlock([onFailure(dueTo: error)])
      }
    })
  }
  
  func cancelTask() {
    request.cancel()
  }
}

// MARK: - Subscribe Reconnect Effect (Common)

protocol SubscribeReconnectEffect: SubscribeEffect {
  var currentAttempt: Int { get }
  var error: SubscribeError? { get }
  
  func onGivingUp(dueTo error: SubscribeError) -> Subscribe.Event
}

extension SubscribeReconnectEffect {
  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    if let reconnectionDelay = request.computeReconnectionDelay(dueTo: error, with: currentAttempt) {
      DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + reconnectionDelay) {
        if !request.isCancelled {
          request.execute(onCompletion: {
            switch $0 {
            case .success(let response):
              completionBlock([onCompletion(with: response)])
            case .failure(let e):
              if currentAttempt + 1 >= request.retryLimit {
                completionBlock([onGivingUp(dueTo: e)])
              } else {
                completionBlock([onFailure(dueTo: e)])
              }
            }
          })
        }
      }
    } else {
      completionBlock([onGivingUp(dueTo: error!)])
    }
  }
}

// MARK: - HandshakingEffect

struct HandshakingEffect: SubscribeEffect {
  let request: SubscribeRequest

  func onCompletion(with response: SubscribeResponse) -> Subscribe.Event {
    .handshakeSucceess(cursor: response.cursor)
  }
  
  func onFailure(dueTo error: SubscribeError) -> Subscribe.Event {
    .handshakeFailure(error: error)
  }
}

// MARK: - ReceivingEffect

struct ReceivingEffect: SubscribeEffect {
  let request: SubscribeRequest
  
  func onCompletion(with response: SubscribeResponse) -> Subscribe.Event {
    .receiveSuccess(cursor: response.cursor, messages: response.messages)
  }
  
  func onFailure(dueTo error: SubscribeError) -> Subscribe.Event {
    .receiveFailure(error: error)
  }  
}

// MARK: - HandshakeReconnectEffect

struct HandshakeReconnectEffect: SubscribeReconnectEffect {
  let request: SubscribeRequest
  let error: SubscribeError?
  let currentAttempt: Int
  
  func onCompletion(with response: SubscribeResponse) -> Subscribe.Event {
    .handshakeReconnectSuccess(cursor: response.cursor)
  }
  
  func onFailure(dueTo error: SubscribeError) -> Subscribe.Event {
    .handshakeReconnectFailure(error: error)
  }
  
  func onGivingUp(dueTo error: SubscribeError) -> Subscribe.Event {
    .handshakeReconnectGiveUp(error: error)
  }
}

// MARK: - ReceiveReconnectEffect

struct ReceiveReconnectEffect: SubscribeReconnectEffect {
  let request: SubscribeRequest
  let error: SubscribeError?
  let currentAttempt: Int
  
  func onCompletion(with response: SubscribeResponse) -> Subscribe.Event {
    .receiveReconnectSuccess(cursor: response.cursor, messages: response.messages)
  }
  
  func onFailure(dueTo error: SubscribeError) -> Subscribe.Event {
    .receiveReconnectFailure(error: error)
  }
  
  func onGivingUp(dueTo error: SubscribeError) -> Subscribe.Event {
    .receiveReconnectGiveUp(error: error)
  }
}
