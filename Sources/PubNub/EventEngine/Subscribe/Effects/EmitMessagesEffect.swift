//
//  EmitMessagesEffect.swift
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
