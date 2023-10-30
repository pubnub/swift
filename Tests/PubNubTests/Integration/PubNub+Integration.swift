//
//  PubNub+Integration.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

import PubNub

extension PubNub {
  func publishWithMessageAction(
    channel: String,
    message: JSONCodable,
    actionType: String,
    actionValue: String,
    shouldStore: Bool? = nil,
    storeTTL: Int? = nil,
    meta: JSONCodable? = nil,
    shouldCompress: Bool = false,
    completion: ((Result<PubNubMessageAction, Error>) -> Void)?
  ) {
    publish(
      channel: channel,
      message: message,
      shouldStore: shouldStore,
      storeTTL: storeTTL,
      meta: meta,
      shouldCompress: shouldCompress
    ) { result in
      switch result {
      case let .success(messageTimetoken):
        self.addMessageAction(
          channel: channel,
          type: actionType, value: actionValue,
          messageTimetoken: messageTimetoken,
          completion: completion
        )
      case let .failure(error):
        completion?(.failure(error))
      }
    }
  }
}
