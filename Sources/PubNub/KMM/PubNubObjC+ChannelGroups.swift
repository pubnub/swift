//
//  PubNubObjC+ChannelGroups.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Channel group management

@objc
public extension PubNubObjC {
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
        onFailure(error)
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
        onFailure(error)
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
        onFailure(error)
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
        onFailure(error)
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
        onFailure(error)
      }
    }
  }
}
