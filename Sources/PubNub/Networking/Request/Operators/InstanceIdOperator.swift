//
//  InstanceIdOperator.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// Attaches a PubNub object instance ID query parameters to requests
public struct InstanceIdOperator: RequestOperator {
  static let instanceIDKey = "instanceid"
  /// The instanceID that will be attached to the request
  public let instanceID: String

  init(instanceID: String) {
    self.instanceID = instanceID
  }

  public func mutate(
    _ urlRequest: URLRequest,
    for _: SessionReplaceable,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    var mutatedRequest = urlRequest
    mutatedRequest.url = mutatedRequest.url?
      .appending(queryItems: [URLQueryItem(name: InstanceIdOperator.instanceIDKey,
                                           value: instanceID)])

    completion(.success(mutatedRequest))
  }
}
