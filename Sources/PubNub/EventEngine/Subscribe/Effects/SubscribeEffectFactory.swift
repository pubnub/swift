//
//  SubscribeEffectFactory.swift
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

class SubscribeEffectFactory: EffectHandlerFactory {
  private let session: SessionReplaceable
  private let sessionResponseQueue: DispatchQueue
  private let messageCache: MessageCache
      
  init(
    session: SessionReplaceable,
    sessionResponseQueue: DispatchQueue = .global(qos: .default),
    messageCache: MessageCache = MessageCache()
  ) {
    self.session = session
    self.sessionResponseQueue = sessionResponseQueue
    self.messageCache = messageCache
  }
  
  func effect(
    for invocation: Subscribe.Invocation,
    with customInput: EventEngineCustomInput<Subscribe.EngineInput>
  ) -> any EffectHandler<Subscribe.Event> {
    switch invocation {
    case .handshakeRequest(let channels, let groups):
      return HandshakeEffect(
        request: SubscribeRequest(
          configuration: customInput.value.configuration,
          channels: channels,
          groups: groups,
          timetoken: 0,
          session: session,
          sessionResponseQueue: sessionResponseQueue
        )
      )
    case .handshakeReconnect(let channels, let groups, let currentAttempt, let reason):
      return HandshakeReconnectEffect(
        request: SubscribeRequest(
          configuration: customInput.value.configuration,
          channels: channels,
          groups: groups,
          timetoken: 0,
          session: session,
          sessionResponseQueue: sessionResponseQueue
        ),
        error: reason,
        currentAttempt: currentAttempt
      )
    case .receiveMessages(let channels, let groups, let cursor):
      return ReceivingEffect(
        request: SubscribeRequest(
          configuration: customInput.value.configuration,
          channels: channels,
          groups: groups,
          timetoken: cursor.timetoken,
          region: cursor.region,
          session: session,
          sessionResponseQueue: sessionResponseQueue
        )
      )
    case .receiveReconnect(let channels, let groups, let cursor, let currentAttempt, let reason):
      return ReceiveReconnectEffect(
        request: SubscribeRequest(
          configuration: customInput.value.configuration,
          channels: channels,
          groups: groups,
          timetoken: cursor.timetoken,
          region: cursor.region,
          session: session,
          sessionResponseQueue: sessionResponseQueue
        ),
        error: reason,
        currentAttempt: currentAttempt
      )
    case .emitMessages(let messages, let cursor):
      return EmitMessagesEffect(
        messages: messages,
        cursor: cursor,
        listeners: customInput.value.listeners,
        messageCache: messageCache
      )
    case .emitStatus(let statusChange):
      return EmitStatusEffect(
        statusChange: statusChange,
        listeners: customInput.value.listeners
      )
    }
  }
  
  deinit {
    session.invalidateAndCancel()
  }
}
