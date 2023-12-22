//
//  SubscribeRequest.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class SubscribeRequest {
  let channels: [String]
  let groups: [String]
  let timetoken: Timetoken?
  let region: Int?
  
  private let configuration: PubNubConfiguration
  private let session: SessionReplaceable
  private let sessionResponseQueue: DispatchQueue
  private let channelStates: [String: [String: JSONCodableScalar]]
  
  private var request: RequestReplaceable?
    
  var retryLimit: UInt {
    configuration.automaticRetry?.retryLimit ?? 0
  }
  
  init(
    configuration: PubNubConfiguration,
    channels: [String],
    groups: [String],
    channelStates: [String: [String: JSONCodableScalar]],
    timetoken: Timetoken? = nil,
    region: Int? = nil,
    session: SessionReplaceable,
    sessionResponseQueue: DispatchQueue
  ) {
    self.configuration = configuration
    self.channels = channels
    self.groups = groups
    self.channelStates = channelStates
    self.timetoken = timetoken
    self.region = region
    self.session = session
    self.sessionResponseQueue = sessionResponseQueue
  }
  
  func reconnectionDelay(dueTo error: SubscribeError, with retryAttempt: Int) -> TimeInterval? {
    guard let automaticRetry = configuration.automaticRetry else {
      return nil
    }
    guard automaticRetry[.subscribe] != nil else {
      return nil
    }
    guard automaticRetry.retryLimit > retryAttempt else {
      return nil
    }
    guard let underlyingError = error.underlying.underlying else {
      return automaticRetry.policy.delay(for: retryAttempt)
    }
    let shouldRetry = automaticRetry.shouldRetry(
      response: error.urlResponse,
      error: underlyingError
    )
    return shouldRetry ? automaticRetry.policy.delay(for: retryAttempt) : nil
  }
        
  func execute(onCompletion: @escaping (Result<SubscribeResponse, SubscribeError>) -> Void) {
    let router = SubscribeRouter(
      .subscribe(
        channels: channels,
        groups: groups,
        channelStates: channelStates,
        timetoken: timetoken,
        region: region?.description ?? nil,
        heartbeat: configuration.durationUntilTimeout,
        filter: configuration.filterExpression
      ),
      configuration: configuration
    )
    request = session.request(
      with: router,
      requestOperator: nil
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
