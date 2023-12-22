//
//  SubscribeError.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

struct SubscribeError: Error, Equatable {
  let underlying: PubNubError
  let urlResponse: HTTPURLResponse?
  
  init(underlying: PubNubError, urlResponse: HTTPURLResponse? = nil) {
    self.underlying = underlying
    self.urlResponse = urlResponse
  }
  
  static func == (lhs: SubscribeError, rhs: SubscribeError) -> Bool {
    lhs.underlying == rhs.underlying
  }
}
