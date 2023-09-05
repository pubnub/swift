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

// MARK: - Handshake Effect

class HandshakeEffect: EffectHandler {
  let request: SubscribeRequest
  
  init(request: SubscribeRequest) {
    self.request = request
  }
  
  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    request.execute(onCompletion: { [weak self] in
      guard let _ = self else { return }
      switch $0 {
      case .success(let response):
        completionBlock([.handshakeSuccess(cursor: response.cursor)])
      case .failure(let error):
        completionBlock([.handshakeFailure(error: error)])
      }
    })
  }
  
  func cancelTask() {
    request.cancel()
  }
  
  deinit {
    cancelTask()
  }
}

// MARK: - Receiving Effect

class ReceivingEffect: EffectHandler {
  let request: SubscribeRequest
  
  init(request: SubscribeRequest) {
    self.request = request
  }
  
  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    request.execute(onCompletion: { [weak self] in
      guard let _ = self else { return }
      switch $0 {
      case .success(let response):
        completionBlock([.receiveSuccess(cursor: response.cursor, messages: response.messages)])
      case .failure(let error):
        completionBlock([.receiveFailure(error: error)])
      }
    })
  }
  
  func cancelTask() {
    request.cancel()
  }
  
  deinit {
    cancelTask()
  }
}

// MARK: - Handshake Reconnect Effect

class HandshakeReconnectEffect: DelayedEffectHandler {
  typealias Event = Subscribe.Event
  
  let request: SubscribeRequest
  let retryAttempt: Int
  let error: SubscribeError
  var workItem: DispatchWorkItem?
  
  init(request: SubscribeRequest, error: SubscribeError, retryAttempt: Int) {
    self.request = request
    self.error = error
    self.retryAttempt = retryAttempt
  }
  
  func delayInterval() -> TimeInterval? {
    request.reconnectionDelay(dueTo: error, with: retryAttempt)
  }
  
  func onEarlyExit(notify completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    completionBlock([.handshakeReconnectGiveUp(error: error)])
  }
  
  func onDelayExpired(notify completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    request.execute(onCompletion: { [weak self] in
      guard let _ = self else { return }
      switch $0 {
      case .success(let response):
        completionBlock([.handshakeReconnectSuccess(cursor: response.cursor)])
      case .failure(let error):
        completionBlock([.handshakeReconnectFailure(error: error)])
      }
    })
  }
  
  func cancelTask() {
    request.cancel()
    workItem?.cancel()
  }
  
  deinit {
    cancelTask()
  }
}

// MARK: - Receiving Reconnect Effect

class ReceiveReconnectEffect: DelayedEffectHandler {
  typealias Event = Subscribe.Event
  
  let request: SubscribeRequest
  let retryAttempt: Int
  let error: SubscribeError
  var workItem: DispatchWorkItem?
  
  init(request: SubscribeRequest, error: SubscribeError, retryAttempt: Int) {
    self.request = request
    self.error = error
    self.retryAttempt = retryAttempt
  }
  
  func delayInterval() -> TimeInterval? {
    request.reconnectionDelay(dueTo: error, with: retryAttempt)
  }
  
  func onEarlyExit(notify completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    completionBlock([.receiveReconnectGiveUp(error: error)])
  }
  
  func onDelayExpired(notify completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    request.execute(onCompletion: { [weak self] in
      guard let _ = self else { return }
      switch $0 {
      case .success(let response):
        completionBlock([.receiveReconnectSuccess(cursor: response.cursor, messages: response.messages)])
      case .failure(let error):
        completionBlock([.receiveReconnectFailure(error: error)])
      }
    })
  }
  
  func cancelTask() {
    request.cancel()
    workItem?.cancel()
  }
  
  deinit {
    cancelTask()
  }
}
