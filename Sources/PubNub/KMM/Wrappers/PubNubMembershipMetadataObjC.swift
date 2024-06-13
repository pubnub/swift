//
//  PubNubMembershipMetadataObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubMembershipMetadataObjC: NSObject {
  @objc public var uuidMetadataId: String
  @objc public var channelMetadataId: String
  @objc public var status: String?
  @objc public var uuid: PubNubUUIDMetadataObjC?
  @objc public var channel: PubNubChannelMetadataObjC?
  @objc public var updated: String?
  @objc public var eTag: String?
  @objc public var custom: [String: Any]?
  
  init(from: PubNubMembershipMetadata) {
    self.uuidMetadataId = from.uuidMetadataId
    self.channelMetadataId = from.channelMetadataId
    self.status = from.status
    self.uuid = if let uuid = from.uuid { PubNubUUIDMetadataObjC(metadata: uuid) } else { nil }
    self.channel = if let channel = from.channel { PubNubChannelMetadataObjC(metadata: channel) } else { nil }
    self.updated = from.updated?.stringOptional // TODO: Valid date format
    self.eTag = from.eTag
    self.custom = from.custom
  }
}
