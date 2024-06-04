//
//  StatusListenerObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class StatusListenerObjC: NSObject {
  @objc public let uuid: UUID
  @objc public var onStatusChange: ((PubNubConnectionStatusObjC) -> Void)?
  
  @objc
  public init(onStatusChange: ((PubNubConnectionStatusObjC) -> Void)? = nil) {
    self.uuid = UUID()
    self.onStatusChange = onStatusChange
  }
}

@objc
public class PubNubConnectionStatusObjC: NSObject {
  @objc public let category: PubNubConnectionStatusCategoryObjC
  @objc public let error: Error?
  @objc public let currentTimetoken: NSNumber?
  @objc public let affectedChannels: Set<String>
  @objc public let affectedChannelGroups: Set<String>
  
  init(
    category: PubNubConnectionStatusCategoryObjC,
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
public enum PubNubConnectionStatusCategoryObjC: Int {
  case connected
  case subscriptionChanged
  case disconnectedUnexpectedly
  case disconnected
  case connectionError
  case heartbeatFailed
  case heartbeatSuccess
  case malformedResponseCategory
}
