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

  init(request: SubscribeRequest, listeners: WeakSet<BaseSubscriptionListener>) {
    self.subscribeEffect = SubscribeEffect(
      request: request,
      listeners: listeners,
      onResponseReceived: { .handshakeSuccess(cursor: $0.cursor) },
      onErrorReceived: { .handshakeFailure(error: $0) }
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

// MARK: - ReceivingEffect

class ReceivingEffect: EffectHandler {
  private let subscribeEffect: SubscribeEffect

  init(request: SubscribeRequest, listeners: WeakSet<BaseSubscriptionListener>) {
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

// MARK: - SubscribeEffect

private class SubscribeEffect: EffectHandler {
  let request: SubscribeRequest
  let subscriptions: WeakSet<BaseSubscriptionListener>
  let onResponseReceived: (SubscribeResponse) -> Subscribe.Event
  let onErrorReceived: (PubNubError) -> Subscribe.Event

  init(
    request: SubscribeRequest,
    listeners: WeakSet<BaseSubscriptionListener>,
    onResponseReceived: @escaping ((SubscribeResponse) -> Subscribe.Event),
    onErrorReceived: @escaping ((PubNubError) -> Subscribe.Event)
  ) {
    self.request = request
    self.subscriptions = listeners
    self.onResponseReceived = onResponseReceived
    self.onErrorReceived = onErrorReceived
  }

  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    request.execute(onCompletion: { [weak self] in
      guard let selfRef = self else { return }
      switch $0 {
      case .success(let response):
        selfRef.subscriptions.forEach {
          $0?.emit(subscribe: .responseReceived(
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
