//
//  SubscribeEffects.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
