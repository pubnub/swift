//
//  PubNubObjC+History.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// All public symbols in this file that are annotated with @objc are intended to allow interoperation
/// with Kotlin Multiplatform for other PubNub frameworks.
///
/// While these symbols are public, they are intended strictly for internal usage.
  
/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

@objc
public extension PubNubObjC {
  func fetchMessages(
    from channels: [String],
    includeUUID: Bool,
    includeMeta: Bool,
    includeMessageActions: Bool,
    includeMessageType: Bool,
    page: PubNubBoundedPageObjC?,
    onSuccess: @escaping ((PubNubFetchMessagesResultObjC)) -> Void,
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetchMessageHistory(
      for: channels,
      includeActions: includeMessageActions,
      includeMeta: includeMeta,
      includeUUID: includeUUID,
      includeMessageType: includeMessageType,
      page: PubNubBoundedPageBase(
        start: page?.start?.uint64Value,
        end: page?.end?.uint64Value,
        limit: page?.limit?.intValue
      )
    ) {
      switch $0 {
      case .success(let response):
        onSuccess(PubNubFetchMessagesResultObjC(
          messages: response.messagesByChannel.mapValues { $0.map { PubNubMessageObjC(message: $0) } },
          page: PubNubBoundedPageObjC(page: response.next)
        ))
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  // TODO: Deleting history from more than one channel isn't supported in Swift SDK

  func deleteMessages(
    from channels: [String],
    start: NSNumber?,
    end: NSNumber?,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let channel = channels.first else {
      onFailure(PubNubError(
        .invalidArguments,
        additional: ["Empty channel list for deleteMessages"]
      ))
      return
    }
    pubnub.deleteMessageHistory(
      from: channel,
      start: start?.uint64Value,
      end: end?.uint64Value
    ) {
      switch $0 {
      case .success:
        onSuccess()
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func messageCounts(
    for channels: [String],
    channelsTimetokens: [Timetoken],
    onSuccess: @escaping (([String: Timetoken]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    let keys = Set(channels)
    let count = min(keys.count, channelsTimetokens.count)
    let dictionary = Dictionary(uniqueKeysWithValues: zip(keys.prefix(count), channelsTimetokens.prefix(count)))

    pubnub.messageCounts(channels: dictionary) {
      switch $0 {
      case .success(let response):
        onSuccess(response.mapValues { UInt64($0) })
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }
}
