//
//  PubNubObjC+Publish.swift
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
/// All public symbols in this file that are annotated with @objc are intended to allow interoperation
/// with Kotlin Multiplatform for other PubNub frameworks.
///
/// While these symbols are public, they are intended strictly for internal usage.

/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

// MARK: - Publish

extension PubNubObjC {
  private func asOptionalCodable(_ object: Any?) -> JSONCodable? {
    if let object {
      return asCodable(object)
    } else {
      return nil
    }
  }

  private func asCodable(_ object: Any) -> JSONCodable {
    if let codableValue = object as? JSONCodable {
      return codableValue
    } else {
      return AnyJSON(object)
    }
  }
}

@objc
public extension PubNubObjC {
  func publish(
    channel: String,
    message: Any,
    meta: Any?,
    shouldStore: NSNumber?,
    ttl: NSNumber?,
    onSuccess: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.publish(
      channel: channel,
      message: asCodable(message),
      shouldStore: shouldStore?.boolValue,
      storeTTL: shouldStore?.intValue,
      meta: asOptionalCodable(meta)
    ) {
      switch $0 {
      case .success(let timetoken):
        onSuccess(timetoken)
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }
}

// MARK: - Signal

@objc
public extension PubNubObjC {
  func signal(
    channel: String,
    message: Any,
    onSuccess: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.signal(channel: channel, message: asCodable(message)) {
      switch $0 {
      case .success(let timetoken):
        onSuccess(timetoken)
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }
}
