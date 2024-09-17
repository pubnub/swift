//
//  KMPPubNub+ChannelGroups.swift
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
  func addChannels(
    to channelGroup: String,
    channels: [String],
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error)) -> Void
  ) {
    pubnub.add(
      channels: channels,
      to: channelGroup
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(res.channels)
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func listChannels(
    for channelGroup: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.listChannels(for: channelGroup) {
      switch $0 {
      case .success(let res):
        onSuccess(res.channels)
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func remove(
    channels: [String],
    from channelGroup: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error)) -> Void
  ) {
    pubnub.remove(channels: channels, from: channelGroup) {
      switch $0 {
      case .success(let res):
        onSuccess(res.channels)
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func listChannelGroups(
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error)) -> Void
  ) {
    pubnub.listChannelGroups {
      switch $0 {
      case .success(let channelGroups):
        onSuccess(channelGroups)
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func delete(
    channelGroup: String,
    onSuccess: @escaping ((String) -> Void),
    onFailure: @escaping ((Error)) -> Void
  ) {
    pubnub.remove(channelGroup: channelGroup) {
      switch $0 {
      case .success(let channelGroup):
        onSuccess(channelGroup)
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }
}
