//
//  PubNubObjC+MessageActions.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Message Actions

@objc
public extension PubNubObjC {
  func addMessageAction(
    channel: String,
    actionType: String,
    actionValue: String,
    messageTimetoken: Timetoken,
    onSuccess: @escaping ((PubNubMessageActionObjC) -> Void),
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
        onSuccess(PubNubMessageActionObjC(action: action))
      case .failure(let error):
        onFailure(error)
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
        onFailure(error)
      }
    }
  }

  func getMessageActions(
    from channel: String,
    page: PubNubBoundedPageObjC,
    onSuccess: @escaping (([PubNubMessageActionObjC], PubNubBoundedPageObjC?) -> Void),
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
        onSuccess(res.actions.map { PubNubMessageActionObjC(action: $0) }, PubNubBoundedPageObjC(page: res.next))
      case .failure(let error):
        onFailure(error)
      }
    }
  }
}
