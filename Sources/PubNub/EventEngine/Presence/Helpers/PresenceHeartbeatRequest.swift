//
//  PresenceHeartbeatRequest.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - PresenceStateContainer

class PresenceStateContainer {
  private var channelStates: Atomic<[String: [String: JSONCodableScalar]]> = Atomic([:])
  
  static var shared: PresenceStateContainer = PresenceStateContainer()
  private init() {}
  
  func registerState(_ state: [String: JSONCodableScalar], forChannels channels: [String]) {
    channelStates.lockedWrite { channelStates in
      channels.forEach {
        channelStates[$0] = state
      }
    }
  }
  
  func removeState(forChannels channels: [String]) {
    channelStates.lockedWrite { channelStates in
      channels.map {
        channelStates[$0] = nil
      }
    }
  }
  
  func getStates(forChannels channels: [String]) -> [String: [String: JSONCodableScalar]] {
    channelStates.lockedRead {
      $0.filter {
        channels.contains($0.key)
      }
    }
  }
}

// MARK: - PresenceHeartbeatRequest

class PresenceHeartbeatRequest {
  let channels: [String]
  let groups: [String]
  let configuration: SubscriptionConfiguration
  
  private let session: SessionReplaceable
  private let sessionResponseQueue: DispatchQueue
  private let channelStates: [String: [String: JSONCodableScalar]]
  private var request: RequestReplaceable?
  
  init(
    channels: [String],
    groups: [String],
    channelStates: [String: [String: JSONCodableScalar]],
    configuration: SubscriptionConfiguration,
    session: SessionReplaceable,
    sessionResponseQueue: DispatchQueue
  ) {
    self.channels = channels
    self.groups = groups
    self.channelStates = channelStates
    self.configuration = configuration
    self.session = session
    self.sessionResponseQueue = sessionResponseQueue
  }
  
  func execute(completionBlock: @escaping (Result<Void, PubNubError>) -> Void) {
    let endpoint = PresenceRouter.Endpoint.heartbeat(
      channels: channels,
      groups: groups,
      channelStates: channelStates,
      presenceTimeout: configuration.durationUntilTimeout
    )
    request = session.request(
      with: PresenceRouter(endpoint, configuration: configuration),
      requestOperator: nil
    )
    request?.validate().response(on: sessionResponseQueue, decoder: GenericServiceResponseDecoder()) { result in
      switch result {
      case .success(_):
        completionBlock(.success(()))
      case .failure(let error):
        completionBlock(.failure(error as? PubNubError ?? PubNubError(.unknown, underlying: error)))
      }
    }
  }
  
  func cancel() {
    request?.cancel(PubNubError(.clientCancelled))
  }
  
  func reconnectionDelay(dueTo error: PubNubError, retryAttempt: Int) -> TimeInterval? {
    guard let automaticRetry = configuration.automaticRetry else {
      return nil
    }
    guard automaticRetry[.presence] != nil else {
      return nil
    }
    guard automaticRetry.retryLimit > retryAttempt else {
      return nil
    }
    guard let underlyingError = error.underlying else {
      return automaticRetry.policy.delay(for: retryAttempt)
    }
    guard let urlResponse = error.affected.findFirst(by: PubNubError.AffectedValue.response) else {
      return nil
    }

    let shouldRetry = automaticRetry.shouldRetry(
      response: urlResponse,
      error: underlyingError
    )
    
    return shouldRetry ? automaticRetry.policy.delay(for: retryAttempt) : nil
  }
}
