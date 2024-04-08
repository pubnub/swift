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

class PresenceHeartbeatRequest {
  let channels: [String]
  let groups: [String]
  let configuration: PubNubConfiguration

  private let session: SessionReplaceable
  private let sessionResponseQueue: DispatchQueue
  private let channelStates: [String: JSONCodable]
  private var request: RequestReplaceable?

  init(
    channels: [String],
    groups: [String],
    channelStates: [String: JSONCodable],
    configuration: PubNubConfiguration,
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
      case .success:
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
    guard automaticRetry.retryOperator(for: .presence) != nil else {
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
