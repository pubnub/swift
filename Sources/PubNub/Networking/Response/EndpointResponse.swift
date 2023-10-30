//
//  EndpointResponse.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// Generic Response value
public struct EndpointResponse<Value> {
  /// Router used to generate the `URLRequest`
  public let router: HTTPRouter
  /// `URLRequest` that was performed
  public let request: URLRequest
  /// The server response from the `URLRequest`
  public let response: HTTPURLResponse
  /// The raw data associated with the response
  public let data: Data?
  /// The decoded response data
  public let payload: Value
}

public extension EndpointResponse where Value == Data {
  init(router: HTTPRouter, request: URLRequest, response: HTTPURLResponse, payload: Data) {
    self.router = router
    self.request = request
    self.response = response
    data = payload
    self.payload = payload
  }
}
