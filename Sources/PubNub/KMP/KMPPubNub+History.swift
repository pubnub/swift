//
//  KMPPubNub+History.swift
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
  func fetchMessages(
    from channels: [String],
    includeUUID: Bool,
    includeMeta: Bool,
    includeMessageActions: Bool,
    includeMessageType: Bool,
    includeCustomMessageType: Bool,
    page: KMPBoundedPage?,
    onSuccess: @escaping ((KMPFetchMessagesResult)) -> Void,
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetchMessageHistory(
      for: channels,
      includeActions: includeMessageActions,
      includeMeta: includeMeta,
      includeUUID: includeUUID,
      includeMessageType: includeMessageType,
      includeCustomMessageType: includeCustomMessageType,
      page: PubNubBoundedPageBase(
        start: page?.start?.uint64Value,
        end: page?.end?.uint64Value,
        limit: page?.limit?.intValue
      )
    ) {
      switch $0 {
      case .success(let response):
        onSuccess(KMPFetchMessagesResult(
          messages: response.messagesByChannel.mapValues { $0.map { KMPMessage(message: $0) } },
          page: KMPBoundedPage(page: response.next)
        ))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  // swiftlint:disable todo
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
        onFailure(KMPError(underlying: error))
      }
    }
  }

  // swiftlint:enable todo

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
        onFailure(KMPError(underlying: error))
      }
    }
  }
}
