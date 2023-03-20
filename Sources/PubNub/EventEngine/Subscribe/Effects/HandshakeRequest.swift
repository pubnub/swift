//
//  HandshakeRequest.swift
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

class HandshakeRequest: BaseEffectHandler<Subscribe.EffectInvocation, Subscribe.Events> {
  let session: SessionReplaceable
  let configuration: SubscriptionConfiguration
  let channels: [String]
  let groups: [String]
  
  private var router: HTTPRouter?
  private var request: RequestReplaceable?
  
  init(
    invocation: EffectInvocation<EffectKind, Event>,
    receiver: some EventReceiver<Event>,
    session: SessionReplaceable,
    configuration: SubscriptionConfiguration,
    channels: [String],
    groups: [String]
  ) {
    self.session = session
    self.configuration = configuration
    self.channels = channels
    self.groups = groups
    
    super.init(
      invocation: invocation,
      receiver: receiver
    )
  }
  
  override func performEffectTask() {
    let router = SubscribeRouter(
      .subscribe(
        channels: channels,
        groups: groups,
        timetoken: nil,
        region: nil,
        heartbeat: configuration.durationUntilTimeout,
        filter: configuration.filterExpression
      ), configuration: configuration
    )
    
    request = session.request(
      with: router,
      requestOperator: configuration.automaticRetry
    )
    request?.validate().response(
      on: .main,
      decoder: SubscribeDecoder(),
      completion: { result in
        switch result {
        case .success(let response):
          debugPrint("TODO: \(response)")
        case .failure(let error):
          debugPrint("TODO: \(error)")
        }
      }
    )
  }
  
  override func cancelEffectTask() {
    request?.cancel(PubNubError(.clientCancelled, router: router))
  }
}
