//
//  EmitMessagesEffect.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class MessageCache {
  private(set) var messagesArray = [SubscribeMessagePayload?].init(repeating: nil, count: 100)

  init(messagesArray: [SubscribeMessagePayload?] = .init(repeating: nil, count: 100)) {
    self.messagesArray = messagesArray
  }

  var isOverflowed: Bool {
    return messagesArray.count >= 100
  }

  func contains(_ message: SubscribeMessagePayload) -> Bool {
    messagesArray.contains(message)
  }

  func append(_ message: SubscribeMessagePayload) {
    messagesArray.append(message)
  }

  func dropTheOldest() {
    messagesArray.remove(at: 0)
  }
}

struct EmitMessagesEffect: EffectHandler {
  let messages: [SubscribeMessagePayload]
  let cursor: SubscribeCursor
  let listeners: [BaseSubscriptionListener]
  let messageCache: MessageCache

  func performTask(completionBlock: @escaping ([Subscribe.Event]) -> Void) {
    // Attempt to detect missed messages due to queue overflow
    if messages.count >= 100 {
      listeners.forEach {
        $0.emit(subscribe: .errorReceived(
          PubNubError(
            .messageCountExceededMaximum,
            router: nil,
            affected: [.subscribe(cursor)]
          ))
        )
      }
    }

    let filteredMessages = messages.filter { message in // Dedupe the message
      // Update cache and notify if not a duplicate message
      if !messageCache.contains(message) {
        messageCache.append(message)
        // Remove the oldest value if we're at max capacity
        if messageCache.isOverflowed {
          messageCache.dropTheOldest()
        }
        return true
      }
      return false
    }

    listeners.forEach {
      $0.emit(batch: filteredMessages)
    }

    completionBlock([])
  }
}
