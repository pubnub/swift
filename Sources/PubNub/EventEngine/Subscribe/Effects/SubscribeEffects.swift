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

// MARK: - HandshakeEffect

class HandshakeEffect: EffectHandler {
  private let subscribeEffect: SubscribeEffect

  init(request: SubscribeRequest, listeners: [BaseSubscriptionListener]) {
    self.subscribeEffect = SubscribeEffect(
      request: request,
      listeners: listeners,
      onResponseReceived: { .handshakeSuccess(cursor: $0.cursor) },
      onErrorReceived: { .handshakeFailure(error: $0) }
    )
  }

  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    subscribeEffect.listeners.forEach { $0.emit(subscribe: .connectionChanged(.connecting)) }
    subscribeEffect.performTask(completionBlock: completionBlock)
  }

  func cancelTask() {
    subscribeEffect.cancelTask()
  }

  deinit {
    cancelTask()
  }
}

// MARK: - ReceivingEffect

class ReceivingEffect: EffectHandler {
  private let subscribeEffect: SubscribeEffect

  init(request: SubscribeRequest, listeners: [BaseSubscriptionListener]) {
    self.subscribeEffect = SubscribeEffect(
      request: request,
      listeners: listeners,
      onResponseReceived: { .receiveSuccess(cursor: $0.cursor, messages: $0.messages) },
      onErrorReceived: { .receiveFailure(error: $0) }
    )
  }

  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    subscribeEffect.performTask(completionBlock: completionBlock)
  }

  func cancelTask() {
    subscribeEffect.cancelTask()
  }

  deinit {
    cancelTask()
  }
}

// MARK: - HandshakeReconnectEffect

class HandshakeReconnectEffect: EffectHandler {
  private let subscribeEffect: SubscribeEffect
  private let timerEffect: TimerEffect?
  private let error: PubNubError

  init(
    request: SubscribeRequest,
    listeners: [BaseSubscriptionListener],
    error: PubNubError,
    retryAttempt: Int
  ) {
    self.timerEffect = TimerEffect(interval: request.reconnectionDelay(
      dueTo: error,
      retryAttempt: retryAttempt
    ))
    self.subscribeEffect = SubscribeEffect(
      request: request,
      listeners: listeners,
      onResponseReceived: { .handshakeReconnectSuccess(cursor: $0.cursor) },
      onErrorReceived: { .handshakeReconnectFailure(error: $0) }
    )
    self.error = error
  }

  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    guard let timerEffect = timerEffect else {
      completionBlock([.handshakeReconnectGiveUp(error: error)]); return
    }
    timerEffect.performTask { [weak self] _ in
      self?.subscribeEffect.performTask(completionBlock: completionBlock)
    }
  }

  func cancelTask() {
    timerEffect?.cancelTask()
    subscribeEffect.cancelTask()
  }

  deinit {
    cancelTask()
  }
}

// MARK: - ReceiveReconnectEffect

class ReceiveReconnectEffect: EffectHandler {
  private let subscribeEffect: SubscribeEffect
  private let timerEffect: TimerEffect?
  private let error: PubNubError

  init(
    request: SubscribeRequest,
    listeners: [BaseSubscriptionListener],
    error: PubNubError,
    retryAttempt: Int
  ) {
    self.timerEffect = TimerEffect(interval: request.reconnectionDelay(
      dueTo: error,
      retryAttempt: retryAttempt
    ))
    self.subscribeEffect = SubscribeEffect(
      request: request,
      listeners: listeners,
      onResponseReceived: { .receiveReconnectSuccess(cursor: $0.cursor, messages: $0.messages) },
      onErrorReceived: { .receiveReconnectFailure(error: $0) }
    )
    self.error = error
  }

  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    subscribeEffect.listeners.forEach {
      $0.emit(subscribe: .connectionChanged(.reconnecting))
    }
    guard let timerEffect = timerEffect else {
      completionBlock([.receiveReconnectGiveUp(error: error)]); return
    }
    subscribeEffect.request.onAuthChallengeReceived = { [weak self] in
      // Delay time for server to process connection after TLS handshake
      DispatchQueue.global(qos: .default).asyncAfter(deadline: DispatchTime.now() + 0.05) {
        self?.subscribeEffect.listeners.forEach { $0.emit(subscribe: .connectionChanged(.connected)) }
      }
    }
    timerEffect.performTask { [weak self] _ in
      self?.subscribeEffect.performTask(completionBlock: completionBlock)
    }
  }

  func cancelTask() {
    timerEffect?.cancelTask()
    subscribeEffect.cancelTask()
  }

  deinit {
    cancelTask()
  }
}

// MARK: - SubscribeEffect

private class SubscribeEffect: EffectHandler {
  let request: SubscribeRequest
  let listeners: [BaseSubscriptionListener]
  let onResponseReceived: (SubscribeResponse) -> Subscribe.Event
  let onErrorReceived: (PubNubError) -> Subscribe.Event

  init(
    request: SubscribeRequest,
    listeners: [BaseSubscriptionListener],
    onResponseReceived: @escaping ((SubscribeResponse) -> Subscribe.Event),
    onErrorReceived: @escaping ((PubNubError) -> Subscribe.Event)
  ) {
    self.request = request
    self.listeners = listeners
    self.onResponseReceived = onResponseReceived
    self.onErrorReceived = onErrorReceived
  }

  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    request.execute(onCompletion: { [weak self] in
      guard let selfRef = self else { return }
      switch $0 {
      case .success(let response):
        selfRef.listeners.forEach {
          $0.emit(subscribe: .responseReceived(
            SubscribeResponseHeader(
              channels: selfRef.request.channels.map { PubNubChannel(channel: $0) },
              groups: selfRef.request.groups.map { PubNubChannel(channel: $0) },
              previous: SubscribeCursor(timetoken: selfRef.request.timetoken, region: selfRef.request.region),
              next: response.cursor
            ))
          )
        }
        completionBlock([selfRef.onResponseReceived(response)])
      case .failure(let error):
        completionBlock([selfRef.onErrorReceived(error)])
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
