//
//  KMPPubNubError.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
///
/// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
/// While these symbols are public, they are intended strictly for internal usage.
///
/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

@objc
public class KMPError: NSError {
  let underlying: Error

  init(underlying: Error) {
    self.underlying = underlying
    super.init(domain: "pubnub", code: (underlying as? PubNubError)?.reason.rawValue ?? 0)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc
  public override var localizedDescription: String {
    underlying.localizedDescription
  }

  @objc
  public var statusCode: Int {
    if let response = (underlying as? PubNubError)?.affected.findFirst(by: PubNubError.AffectedValue.response) {
      return response.statusCode
    } else {
      return 0
    }
  }
}
