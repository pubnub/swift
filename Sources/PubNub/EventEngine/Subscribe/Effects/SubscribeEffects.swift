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

protocol SubscribeEffect: EffectHandler, AnyObject {
  var request: SubscribeRequest { get }
  
  func onCompletion(with response: SubscribeResponse) -> Subscribe.Event
  func onFailure(dueTo error: SubscribeError) -> Subscribe.Event
}

extension SubscribeEffect {
  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    request.execute(onCompletion: { [weak self] in
      if let selfRef = self {
        switch $0 {
        case .success(let response):
          completionBlock([selfRef.onCompletion(with: response)])
        case .failure(let error):
          completionBlock([selfRef.onFailure(dueTo: error)])
        }
      }
    })
  }
  
  func cancelTask() {
    request.cancel()
  }
}

// MARK: - Subscribe Reconnect Effect (Common)

protocol SubscribeReconnectEffect: AnyObject, SubscribeEffect {
  var request: SubscribeRequest { get }
  var currentAttempt: Int { get }
  var error: SubscribeError { get }
  var workItem: DispatchWorkItem? { get set }
  var completionBlock: (([Subscribe.Event]) -> Void)? { get set }
  
  func onGivingUp(dueTo error: SubscribeError) -> Subscribe.Event
}

extension SubscribeReconnectEffect {
  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    if let reconnectionDelay = request.computeReconnectionDelay(dueTo: error, with: currentAttempt) {
      let workItem = DispatchWorkItem { [weak self] in
        if let selfRef = self {
          selfRef.request.execute(onCompletion: {
            switch $0 {
            case .success(let response):
              completionBlock([selfRef.onCompletion(with: response)])
            case .failure(let error):
              completionBlock([selfRef.onFailure(dueTo: error)])
            }
          })
        } else {
          completionBlock([])
        }
      }
      self.completionBlock = completionBlock
      self.workItem = workItem
      
      DispatchQueue.global(qos: .default).asyncAfter(
        deadline: .now() + reconnectionDelay,
        execute: workItem
      )
    } else {
      completionBlock([onGivingUp(dueTo: error)])
    }
  }
  
  func cancelTask() {
    request.cancel()
    workItem?.cancel()
    completionBlock?([])
    completionBlock = nil
  }
}

// MARK: - HandshakingEffect

class HandshakingEffect: SubscribeEffect {
  let request: SubscribeRequest

  init(request: SubscribeRequest) {
    self.request = request
  }
  
  func onCompletion(with response: SubscribeResponse) -> Subscribe.Event {
    .handshakeSucceess(cursor: response.cursor)
  }
  
  func onFailure(dueTo error: SubscribeError) -> Subscribe.Event {
    .handshakeFailure(error: error)
  }
  
  deinit {
    cancelTask()
  }
}

// MARK: - ReceivingEffect

class ReceivingEffect: SubscribeEffect {
  let request: SubscribeRequest
  
  init(request: SubscribeRequest) {
    self.request = request
  }
  
  func onCompletion(with response: SubscribeResponse) -> Subscribe.Event {
    .receiveSuccess(cursor: response.cursor, messages: response.messages)
  }
  
  func onFailure(dueTo error: SubscribeError) -> Subscribe.Event {
    .receiveFailure(error: error)
  }
  
  deinit {
    cancelTask()
  }
}

// MARK: - HandshakeReconnectEffect

class HandshakeReconnectEffect: SubscribeReconnectEffect {
  let request: SubscribeRequest
  let error: SubscribeError
  let currentAttempt: Int
  
  var workItem: DispatchWorkItem?
  var completionBlock: (([Subscribe.Event]) -> Void)?
  
  init(request: SubscribeRequest, error: SubscribeError, currentAttempt: Int) {
    self.request = request
    self.error = error
    self.currentAttempt = currentAttempt
  }
  
  func onCompletion(with response: SubscribeResponse) -> Subscribe.Event {
    .handshakeReconnectSuccess(cursor: response.cursor)
  }
  
  func onFailure(dueTo error: SubscribeError) -> Subscribe.Event {
    .handshakeReconnectFailure(error: error)
  }
  
  func onGivingUp(dueTo error: SubscribeError) -> Subscribe.Event {
    .handshakeReconnectGiveUp(error: error)
  }
  
  deinit {
    cancelTask()
  }
}

// MARK: - ReceiveReconnectEffect

class ReceiveReconnectEffect: SubscribeReconnectEffect {
  let request: SubscribeRequest
  let error: SubscribeError
  let currentAttempt: Int
  
  var workItem: DispatchWorkItem?
  var completionBlock: (([Subscribe.Event]) -> Void)?
  
  init(request: SubscribeRequest, error: SubscribeError, currentAttempt: Int) {
    self.request = request
    self.error = error
    self.currentAttempt = currentAttempt
  }

  func onCompletion(with response: SubscribeResponse) -> Subscribe.Event {
    .receiveReconnectSuccess(cursor: response.cursor, messages: response.messages)
  }
  
  func onFailure(dueTo error: SubscribeError) -> Subscribe.Event {
    .receiveReconnectFailure(error: error)
  }
  
  func onGivingUp(dueTo error: SubscribeError) -> Subscribe.Event {
    .receiveReconnectGiveUp(error: error)
  }
  
  deinit {
    cancelTask()
  }
}
