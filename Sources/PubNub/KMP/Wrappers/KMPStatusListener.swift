//
//  PubNubStatusListenerObjC.swift
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
public class KMPStatusListener: NSObject {
  @objc public let uuid: UUID
  @objc public var onStatusChange: ((KMPConnectionStatus) -> Void)?

  @objc
  public init(onStatusChange: ((KMPConnectionStatus) -> Void)? = nil) {
    self.uuid = UUID()
    self.onStatusChange = onStatusChange
  }
}

@objc
public class KMPConnectionStatus: NSObject {
  @objc public let category: KMPConnectionStatusCategory
  @objc public let error: Error?
  @objc public let currentTimetoken: NSNumber?
  @objc public let affectedChannels: Set<String>
  @objc public let affectedChannelGroups: Set<String>

  init(
    category: KMPConnectionStatusCategory,
    error: Error?,
    currentTimetoken: NSNumber?,
    affectedChannels: Set<String>,
    affectedChannelGroups: Set<String>
  ) {
    self.category = category
    self.error = error
    self.currentTimetoken = currentTimetoken
    self.affectedChannels = affectedChannels
    self.affectedChannelGroups = affectedChannelGroups
  }
}

@objc
public enum KMPConnectionStatusCategory: Int {
  case connected
  case subscriptionChanged
  case disconnectedUnexpectedly
  case disconnected
  case connectionError
  case heartbeatFailed
  case heartbeatSuccess
  case malformedResponseCategory
}
