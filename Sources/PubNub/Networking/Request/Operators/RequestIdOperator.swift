//
//  RequestIdOperator.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// Attaches a request instance ID query parameters to requests
public struct RequestIdOperator: RequestOperator {
  static let requestIDKey = "requestid"
  /// The requestID that will be attached to the request
  public let requestID: String

  init(requestID: String) {
    self.requestID = requestID
  }

  public func mutate(
    _ urlRequest: URLRequest,
    for _: SessionReplaceable,
    completion: @escaping (Result<URLRequest, Error>) -> Void
  ) {
    var mutatedRequest = urlRequest
    mutatedRequest.url = mutatedRequest.url?
      .appending(queryItems: [URLQueryItem(name: RequestIdOperator.requestIDKey,
                                           value: requestID)])

    completion(.success(mutatedRequest))
  }
}
