//
//  KMPPubNub+Push.swift
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

extension KMPPubNub {
  func pushService(from rawString: String) -> PubNub.PushService? {
    switch rawString {
    case "gcm":
      return .fcm
    case "fcm":
      return .fcm
    case "apns", "apns2":
      return .apns
    default:
      return nil
    }
  }

  func data(from deviceId: String, for pushService: PubNub.PushService) -> Data? {
    if pushService == .apns {
      Data(hexEncodedString: deviceId)
    } else {
      deviceId.data(using: .utf8)
    }
  }
}

@objc
public extension KMPPubNub {
  func addChannelsToPushNotifications(
    channels: [String],
    deviceId: String,
    pushType: String,
    topic: String,
    environment: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushService = pushService(from: pushType) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid pushType parameter"]
        )
      ))
      return
    }
    guard let environment = PubNub.PushEnvironment(rawValue: environment) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid environment parameter"]
        )
      ))
      return
    }
    guard let deviceIdData = data(from: deviceId, for: pushService) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid deviceId"]
        )
      ))
      return
    }

    if !topic.isEmpty {
      pubnub.addAPNSDevicesOnChannels(channels, device: deviceIdData, on: topic, environment: environment) {
        switch $0 {
        case .success(let channels):
          onSuccess(channels)
        case .failure(let error):
          onFailure(KMPError(underlying: error))
        }
      }
    } else {
      pubnub.addPushChannelRegistrations(channels, for: deviceIdData, of: pushService) {
        switch $0 {
        case .success(let channels):
          onSuccess(channels)
        case .failure(let error):
          onFailure(KMPError(underlying: error))
        }
      }
    }
  }

  func listPushChannels(
    deviceId: String,
    pushType: String,
    topic: String,
    environment: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushService = pushService(from: pushType) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid pushType parameter"]
        )
      ))
      return
    }
    guard let environment = PubNub.PushEnvironment(rawValue: environment) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid environment parameter"]
        )
      ))
      return
    }
    guard let deviceIdData = data(from: deviceId, for: pushService) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid deviceId"]
        )
      ))
      return
    }

    if !topic.isEmpty {
      pubnub.listAPNSPushChannelRegistrations(for: deviceIdData, on: topic, environment: environment) {
        switch $0 {
        case .success(let channels):
          onSuccess(channels)
        case .failure(let error):
          onFailure(KMPError(underlying: error))
        }
      }
    } else {
      pubnub.listPushChannelRegistrations(for: deviceIdData, of: pushService) {
        switch $0 {
        case .success(let channels):
          onSuccess(channels)
        case .failure(let error):
          onFailure(KMPError(underlying: error))
        }
      }
    }
  }

  func removeChannelsFromPush(
    channels: [String],
    deviceId: String,
    pushType: String,
    topic: String,
    environment: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushService = pushService(from: pushType) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid pushType parameter"]
        )
      ))
      return
    }
    guard let environment = PubNub.PushEnvironment(rawValue: environment) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid environment parameter"]
        )
      ))
      return
    }
    guard let deviceIdData = data(from: deviceId, for: pushService) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid deviceId"]
        )
      ))
      return
    }

    if !topic.isEmpty {
      pubnub.removeAPNSDevicesOnChannels(channels, device: deviceIdData, on: topic, environment: environment) {
        switch $0 {
        case .success(let channels):
          onSuccess(channels)
        case .failure(let error):
          onFailure(KMPError(underlying: error))
        }
      }
    } else {
      pubnub.removePushChannelRegistrations(channels, for: deviceIdData, of: pushService) {
        switch $0 {
        case .success(let channels):
          onSuccess(channels)
        case .failure(let error):
          onFailure(KMPError(underlying: error))
        }
      }
    }

  }

  func removeAllChannelsFromPush(
    pushType: String,
    deviceId: String,
    topic: String,
    environment: String,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushService = pushService(from: pushType) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid pushType parameter"]
        )
      ))
      return
    }
    guard let environment = PubNub.PushEnvironment(rawValue: environment) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid environment parameter"]
        )
      ))
      return
    }
    guard let deviceIdData = data(from: deviceId, for: pushService) else {
      onFailure(KMPError(
        underlying: PubNubError(
          .invalidArguments,
          additional: ["Invalid deviceId"]
        )
      ))
      return
    }

    if !topic.isEmpty {
      pubnub.removeAllAPNSPushDevice(for: deviceIdData, on: topic, environment: environment) {
        switch $0 {
        case .success:
          onSuccess()
        case .failure(let error):
          onFailure(KMPError(underlying: error))
        }
      }
    } else {
      pubnub.removeAllPushChannelRegistrations(for: deviceIdData, of: pushService) {
        switch $0 {
        case .success:
          onSuccess()
        case .failure(let error):
          onFailure(KMPError(underlying: error))
        }
      }
    }
  }
}
