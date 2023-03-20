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
  typealias Event = Subscribe.Events
  typealias EffectKind = Subscribe.EffectInvocation
  
  // TODO: This value should be injected through DI
  private var session: SessionReplaceable!
  
  func effect(
    for invocation: EffectInvocation<EffectKind, Event>,
    with receiver: some EventReceiver<Event>
  ) -> any EffectHandler<EffectKind, Event> {
    switch invocation.kind {
    case .handshakeRequest(let channels, let groups, let configuration):
      return HandshakeRequest(
        invocation: invocation,
        receiver: receiver,
        session: session,
        configuration: configuration,
        channels: channels,
        groups: groups
      )
    default:
      fatalError("TODO")
    }
  }
}
