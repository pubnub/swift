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

typealias SubscribeEngine = EventEngine<(any SubscribeState), Subscribe.Event, Subscribe.Invocation, Subscribe.EngineInput>
typealias PresenceEngine = EventEngine<(any PresenceState), Presence.Event, Presence.Invocation, Presence.EngineInput>

class EventEngineFactory {
  func subscribeEngine(
    with configuration: SubscriptionConfiguration,
    dispatcher: some Dispatcher<Subscribe.Invocation, Subscribe.Event, Subscribe.EngineInput>,
    transition: some TransitionProtocol<any SubscribeState, Subscribe.Event, Subscribe.Invocation>
  ) -> SubscribeEngine {
    EventEngine(
      state: Subscribe.UnsubscribedState(),
      transition: transition,
      dispatcher: dispatcher,
      customInput: EventEngineCustomInput(value: Subscribe.EngineInput(configuration: configuration))
    )
  }
  
  func presenceEngine(
    with configuration: SubscriptionConfiguration,
    dispatcher: some Dispatcher<Presence.Invocation, Presence.Event, Presence.EngineInput>,
    transition: some TransitionProtocol<any PresenceState, Presence.Event, Presence.Invocation>
  ) -> PresenceEngine {
    EventEngine(
      state: Presence.HeartbeatInactive(),
      transition: transition,
      dispatcher: dispatcher,
      customInput: EventEngineCustomInput(value: Presence.EngineInput(configuration: configuration))
    )
  }
}
