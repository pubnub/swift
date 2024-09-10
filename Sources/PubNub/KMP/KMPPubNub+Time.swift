//
//  KMPPubNub+Time.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
//
// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
// While these symbols are public, they are intended strictly for internal usage.
//
// External developers should refrain from directly using these symbols in their code, as their implementation details
// may change in future versions of the framework, potentially leading to breaking changes.

import Foundation

@objc
public extension KMPPubNub {
  func time(
    onSuccess: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.time {
      switch $0 {
      case .success(let timetoken):
        onSuccess(timetoken)
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }
}
