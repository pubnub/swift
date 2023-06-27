//
//  EventEngineFactory.swift
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

typealias AnySubscribeState = (any SubscribeState)
typealias SubscribeEngine = EventEngine<AnySubscribeState, Subscribe.Event, Subscribe.Invocation, SubscribeEngineInput>

class EventEngineFactory {
  static func subscribe(
    with configuration: SubscriptionConfiguration,
    session: SessionReplaceable? = nil,
    sessionQueue: DispatchQueue? = nil
  ) -> SubscribeEngine {
    return EventEngine(
      queue: DispatchQueue(label: "com.pubnub.ee"),
      state: Subscribe.UnsubscribedState(),
      transition: SubscribeTransition(),
      dispatcher: EffectDispatcher(
        factory: SubscribeEffectFactory(
          session: session ?? HTTPSession(
            configuration: URLSessionConfiguration.subscription,
            sessionQueue: sessionQueue ?? defaultSessionQueue,
            sessionStream: SessionListener()
          )
        )
      ),
      customInput: EventEngineCustomInput(
        value: SubscribeEngineInput(
          configuration: configuration,
          listeners: []
        )
      )
    )
  }
  
  private static var defaultSessionQueue: DispatchQueue {
    DispatchQueue(label: "Subscribe Response Queue")
  }
}
