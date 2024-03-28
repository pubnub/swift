//
//  PresenceLeaveRequest.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class PresenceLeaveRequest {
  let channels: [String]
  let groups: [String]
  let configuration: PubNubConfiguration

  private let session: SessionReplaceable
  private let sessionResponseQueue: DispatchQueue
  private var request: RequestReplaceable?

  init(
    channels: [String],
    groups: [String],
    configuration: PubNubConfiguration,
    session: SessionReplaceable,
    sessionResponseQueue: DispatchQueue
  ) {
    self.channels = channels
    self.groups = groups
    self.configuration = configuration
    self.session = session
    self.sessionResponseQueue = sessionResponseQueue
  }

  func execute(completionBlock: @escaping (Result<Void, PubNubError>) -> Void) {
    let endpoint = PresenceRouter.Endpoint.leave(
      channels: channels,
      groups: groups
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
}
