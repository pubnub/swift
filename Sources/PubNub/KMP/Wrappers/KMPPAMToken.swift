//
//  KMPPAMToken.swift
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

@objc public class KMPPAMToken: NSObject {
  @objc public let version: NSNumber
  @objc public let timestamp: NSNumber
  @objc public let ttl: NSNumber
  @objc public let authorizedUUID: String
  @objc public let resources: KMPPAMTokenResource
  @objc public let patterns: KMPPAMTokenResource
  @objc public let meta: KMPAnyJSON

  init(from token: PAMToken) {
    version = NSNumber(integerLiteral: token.version)
    timestamp = NSNumber(integerLiteral: token.timestamp)
    ttl = NSNumber(integerLiteral: token.ttl)
    authorizedUUID = token.authorizedUUID ?? ""
    resources = KMPPAMTokenResource(from: token.resources)
    patterns = KMPPAMTokenResource(from: token.patterns)
    meta = KMPAnyJSON(token.meta)
  }
}

@objc public class KMPPAMTokenResource: NSObject {
  @objc public let channels: [String: KMPPAMPermission]
  @objc public let channelGroups: [String: KMPPAMPermission]
  @objc public let uuids: [String: KMPPAMPermission]

  init(from resource: PAMTokenResource) {
    channels = resource.channels.compactMapValues { KMPPAMPermission(from: $0) }
    channelGroups = resource.groups.compactMapValues { KMPPAMPermission(from: $0) }
    uuids = resource.uuids.compactMapValues { KMPPAMPermission(from: $0) }
  }
}

@objc public class KMPPAMPermission: NSObject {
  @objc public let read: Bool
  @objc public let write: Bool
  @objc public let manage: Bool
  @objc public let delete: Bool
  @objc public let get: Bool
  @objc public let update: Bool
  @objc public let join: Bool

  init(from permission: PAMPermission) {
    read = permission.contains(.read)
    write = permission.contains(.write)
    manage = permission.contains(.manage)
    delete = permission.contains(.delete)
    get = permission.contains(.get)
    update = permission.contains(.update)
    join = permission.contains(.join)
  }
}
