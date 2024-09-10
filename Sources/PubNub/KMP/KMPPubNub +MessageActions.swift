//
//  KMPPubNub+MessageActions.swift
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

// MARK: - Message Actions

@objc
public extension KMPPubNub {
  func addMessageAction(
    channel: String,
    actionType: String,
    actionValue: String,
    messageTimetoken: Timetoken,
    onSuccess: @escaping ((KMPMessageAction) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.addMessageAction(
      channel: channel,
      type: actionType,
      value: actionValue,
      messageTimetoken: messageTimetoken
    ) {
      switch $0 {
      case .success(let action):
        onSuccess(KMPMessageAction(action: action))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func removeMessageAction(
    channel: String,
    messageTimetoken: Timetoken,
    actionTimetoken: Timetoken,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.removeMessageActions(
      channel: channel,
      message: messageTimetoken,
      action: actionTimetoken
    ) {
      switch $0 {
      case .success:
        onSuccess()
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func getMessageActions(
    from channel: String,
    page: KMPBoundedPage,
    onSuccess: @escaping (([KMPMessageAction], KMPBoundedPage?) -> Void),
    onFailure: @escaping ((Error)) -> Void
  ) {
    pubnub.fetchMessageActions(
      channel: channel,
      page: PubNubBoundedPageBase(
        start: page.start?.uint64Value,
        end: page.end?.uint64Value,
        limit: page.limit?.intValue
      )
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(res.actions.map { KMPMessageAction(action: $0) }, KMPBoundedPage(page: res.next))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }
}
