//
//  SubscribeRequest.swift
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

class SubscribeRequest {
  let channels: [String]
  let groups: [String]
  let timetoken: Timetoken?
  let region: Int?
  
  private let configuration: SubscriptionConfiguration
  private let session: SessionReplaceable
  private let sessionResponseQueue: DispatchQueue
  private var request: RequestReplaceable?
    
  var retryLimit: UInt {
    configuration.automaticRetry?.retryLimit ?? 0
  }
  
  init(
    configuration: SubscriptionConfiguration,
    channels: [String],
    groups: [String],
    timetoken: Timetoken? = nil,
    region: Int? = nil,
    session: SessionReplaceable,
    sessionResponseQueue: DispatchQueue
  ) {
    self.configuration = configuration
    self.channels = channels
    self.groups = groups
    self.timetoken = timetoken
    self.region = region
    self.session = session
    self.sessionResponseQueue = sessionResponseQueue
  }
  
  func computeReconnectionDelay(
    dueTo error: SubscribeError,
    with currentAttempt: Int
  ) -> TimeInterval? {
    guard let automaticRetry = configuration.automaticRetry else {
      return nil
    }
    guard automaticRetry.retryLimit > currentAttempt else {
      return nil
    }
    
    if let underlyingError = error.underlying.underlying {
      if automaticRetry.shouldRetry(response: error.urlResponse, error: underlyingError) {
        return automaticRetry.policy.delay(for: currentAttempt)
      } else {
        return nil
      }
    } else {
      return automaticRetry.policy.delay(for: currentAttempt)
    }
  }
        
  func execute(onCompletion: @escaping (Result<SubscribeResponse, SubscribeError>) -> Void) {
    request = session.request(
      with: SubscribeRouter(
        .subscribe(
          channels: channels,
          groups: groups,
          timetoken: timetoken,
          region: region?.description ?? nil,
          heartbeat: configuration.durationUntilTimeout,
          filter: configuration.filterExpression
        ), configuration: configuration
      ), requestOperator: nil
    )
    request?.validate().response(
      on: sessionResponseQueue,
      decoder: SubscribeDecoder(),
      completion: { [weak self] result in
        switch result {
        case .success(let response):
          onCompletion(.success(response.payload))
        case .failure(let error):
          onCompletion(.failure(SubscribeError(
            underlying: error as? PubNubError ?? PubNubError(.unknown, underlying: error),
            urlResponse: self?.request?.urlResponse
          )))
        }
      }
    )
  }
  
  func cancel() {
    request?.cancel(PubNubError(.clientCancelled))
  }
  
  deinit {
    cancel()
  }
}
