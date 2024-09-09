//
//  PubNubObjC+Push.swift
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

extension PubNubObjC {
  func pushService(from rawString: String) -> PubNub.PushService? {
    switch rawString {
    case "gcm":
      return .fcm
    case "apns", "apns2":
      return .apns
    case "mpns":
      return .mpns
    default:
      return nil
    }
  }
}

@objc
public extension PubNubObjC {
  func addChannelsToPushNotifications(
    channels: [String],
    deviceId: Data,
    pushType: String,
    topic: String,
    environment: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushService = pushService(from: pushType) else {
      onFailure(PubNubErrorObjC(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid pushType parameter"]
        )
      ))
      return
    }
    guard let environment = PubNub.PushEnvironment(rawValue: environment) else {
      onFailure(PubNubErrorObjC(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid environment parameter"]
        )
      ))
      return
    }

    if !topic.isEmpty {
      pubnub.addAPNSDevicesOnChannels(channels, device: deviceId, on: topic, environment: environment) {
        switch $0 {
        case .success(let channels):
          onSuccess(channels)
        case .failure(let error):
          onFailure(PubNubErrorObjC(underlying: error))
        }
      }
    } else {
      pubnub.addPushChannelRegistrations(channels, for: deviceId, of: pushService) {
        switch $0 {
        case .success(let channels):
          onSuccess(channels)
        case .failure(let error):
          onFailure(PubNubErrorObjC(underlying: error))
        }
      }
    }
  }

  func listPushChannels(
    deviceId: Data,
    pushType: String,
    topic: String,
    environment: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushService = pushService(from: pushType) else {
      onFailure(PubNubErrorObjC(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid pushType parameter"]
        )
      ))
      return
    }
    guard let environment = PubNub.PushEnvironment(rawValue: environment) else {
      onFailure(PubNubErrorObjC(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid environment parameter"]
        )
      ))
      return
    }

    if !topic.isEmpty {
      pubnub.listAPNSPushChannelRegistrations(for: deviceId, on: topic, environment: environment) {
        switch $0 {
        case .success(let channels):
          onSuccess(channels)
        case .failure(let error):
          onFailure(PubNubErrorObjC(underlying: error))
        }
      }
    } else {
      pubnub.listPushChannelRegistrations(for: deviceId, of: pushService) {
        switch $0 {
        case .success(let channels):
          onSuccess(channels)
        case .failure(let error):
          onFailure(PubNubErrorObjC(underlying: error))
        }
      }
    }
  }

  func removeChannelsFromPush(
    channels: [String],
    deviceId: Data,
    pushType: String,
    topic: String,
    environment: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushService = pushService(from: pushType) else {
      onFailure(PubNubErrorObjC(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid pushType parameter"]
        )
      ))
      return
    }
    guard let environment = PubNub.PushEnvironment(rawValue: environment) else {
      onFailure(PubNubErrorObjC(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid environment parameter"]
        )
      ))
      return
    }

    if !topic.isEmpty {
      pubnub.removeAPNSDevicesOnChannels(channels, device: deviceId, on: topic, environment: environment) {
        switch $0 {
        case .success(let channels):
          onSuccess(channels)
        case .failure(let error):
          onFailure(PubNubErrorObjC(underlying: error))
        }
      }
    } else {
      pubnub.removePushChannelRegistrations(channels, for: deviceId, of: pushService) {
        switch $0 {
        case .success(let channels):
          onSuccess(channels)
        case .failure(let error):
          onFailure(PubNubErrorObjC(underlying: error))
        }
      }
    }

  }

  func removeAllChannelsFromPush(
    pushType: String,
    deviceId: Data,
    topic: String,
    environment: String,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushService = pushService(from: pushType) else {
      onFailure(PubNubErrorObjC(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid pushType parameter"]
        )
      ))
      return
    }
    guard let environment = PubNub.PushEnvironment(rawValue: environment) else {
      onFailure(PubNubErrorObjC(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid environment parameter"]
        )
      ))
      return
    }

    if !topic.isEmpty {
      pubnub.removeAllAPNSPushDevice(for: deviceId, on: topic, environment: environment) {
        switch $0 {
        case .success:
          onSuccess()
        case .failure(let error):
          onFailure(PubNubErrorObjC(underlying: error))
        }
      }
    } else {
      pubnub.removeAllPushChannelRegistrations(for: deviceId, of: pushService) {
        switch $0 {
        case .success:
          onSuccess()
        case .failure(let error):
          onFailure(PubNubErrorObjC(underlying: error))
        }
      }
    }
  }
}
