//
//  PubNubObjectEventResult.swift
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

// MARK: - KMPAppContextEventResult

@objc
public class KMPAppContextEventResult: NSObject {
  @objc public let channel: String
  @objc public let subscription: String?
  @objc public let timetoken: NSNumber?
  @objc public let userMetadata: KMPAnyJSON?
  @objc public let publisher: String?
  @objc public let source: String
  @objc public let version: String
  @objc public let event: String
  @objc public let type: String

  // swiftlint:disable todo
  // TODO: These parameters are not retrieved from Swift SDK

  init(
    channel: String = "",
    subscription: String? = nil,
    timetoken: NSNumber? = nil,
    userMetadata: AnyJSON? = nil,
    publisher: String? = nil,
    source: String = "",
    version: String = "",
    event: String = "",
    type: String = ""
  ) {
    self.channel = channel
    self.source = source
    self.version = version
    self.event = event
    self.type = type
    self.subscription = subscription
    self.timetoken = timetoken
    self.userMetadata = if let metadata = userMetadata { KMPAnyJSON(metadata.codableValue) } else { nil }
    self.publisher = publisher
  }

  // swiftlint:enable todo
}

// MARK: - KMPSetUUIDMetadataResult

@objc
public class KMPSetUUIDMetadataResult: KMPAppContextEventResult {
  @objc public let metadata: KMPUserMetadata

  init(metadata: KMPUserMetadata) {
    self.metadata = metadata
    super.init()
  }
}

// MARK: - KMPRemoveUUIDMetadataResult

@objc
public class KMPRemoveUUIDMetadataResult: KMPAppContextEventResult {
  @objc public let uuid: String

  init(uuid: String) {
    self.uuid = uuid
    super.init()
  }
}

// MARK: - KMPSetChannelMetadataResult

@objc
public class KMPSetChannelMetadataResult: KMPAppContextEventResult {
  @objc public let metadata: KMPChannelMetadata

  init(metadata: KMPChannelMetadata) {
    self.metadata = metadata
    super.init(channel: metadata.id)
  }
}

// MARK: - PubNubRemoveChannelMetadataResultObjC

@objc
public class KMPRemoveChannelMetadataResult: KMPAppContextEventResult {
  @objc public let channelMetadataId: String

  init(channelMetadataId: String) {
    self.channelMetadataId = channelMetadataId
    super.init(channel: channelMetadataId)
  }
}

// MARK: - KMPSetMembershipResult

@objc
public class KMPSetMembershipResult: KMPAppContextEventResult {
  @objc public let metadata: KMPMembershipMetadata

  init(metadata: KMPMembershipMetadata) {
    self.metadata = metadata
    super.init(channel: metadata.channelMetadataId)
  }
}

// MARK: - KMPRemoveMembershipResult

@objc
public class KMPRemoveMembershipResult: KMPAppContextEventResult {
  @objc public let channelId: String
  @objc public let uuid: String

  init(channelId: String, uuid: String) {
    self.channelId = channelId
    self.uuid = uuid
    super.init(channel: channelId)
  }
}

// MARK: - KMPAppContextEventResult (Factory Method)

extension KMPAppContextEventResult {
  static func from(event: PubNubAppContextEvent) -> KMPAppContextEventResult {
    switch event {
    case .userMetadataSet(let changeset):
      return KMPSetUUIDMetadataResult(metadata: KMPUserMetadata(changeset: changeset))
    case .userMetadataRemoved(let metadataId):
      return KMPRemoveUUIDMetadataResult(uuid: metadataId)
    case .channelMetadataSet(let changeset):
      return KMPSetChannelMetadataResult(metadata: KMPChannelMetadata(changeset: changeset))
    case .channelMetadataRemoved(let metadataId):
      return KMPRemoveChannelMetadataResult(channelMetadataId: metadataId)
    case .membershipMetadataSet(let metadata):
      return KMPSetMembershipResult(metadata: KMPMembershipMetadata(from: metadata))
    case .membershipMetadataRemoved(let metadata):
      return KMPRemoveMembershipResult(channelId: metadata.channelMetadataId, uuid: metadata.uuidMetadataId)
    }
  }
}

// MARK: - KMPChannelMetadata

@objc
public class KMPChannelMetadata: NSObject {
  @objc public var id: String
  @objc public var name: String?
  @objc public var descr: String?
  @objc public var custom: [String: Any]?
  @objc public var updated: String?
  @objc public var eTag: String?
  @objc public var type: String?
  @objc public var status: String?

  @objc public var hasName: Bool = false
  @objc public var hasDescr: Bool = false
  @objc public var hasCustom: Bool = false
  @objc public var hasType: Bool = false
  @objc public var hasStatus: Bool = false

  init(changeset: PubNubChannelMetadataChangeset) {
    self.id = changeset.metadataId
    self.updated = DateFormatter.iso8601.string(from: changeset.updated)
    self.eTag = changeset.eTag

    for change in changeset.changes {
      switch change {
      case let .stringOptional(keyPath, value):
        switch keyPath {
        case \.name:
          self.name = value
          self.hasName = true
        case \.type:
          self.type = value
          self.hasType = true
        case \.status:
          self.status = value
          self.hasStatus = true
        case \.channelDescription:
          self.descr = value
          self.hasDescr = true
        default:
          break
        }
      case .customOptional(_, let value):
        if let value {
          self.custom = value.asObjCRepresentable()
          self.hasCustom = true
        } else {
          self.custom = nil
          self.hasCustom = true
        }
      }
    }
  }

  init(metadata: PubNubChannelMetadata) {
    self.id = metadata.metadataId
    self.name = metadata.name
    self.descr = metadata.channelDescription
    self.custom = metadata.custom?.asObjCRepresentable()
    self.updated = if let date = metadata.updated { DateFormatter.iso8601.string(from: date) } else { nil }
    self.eTag = metadata.eTag
    self.type = metadata.type
    self.status = metadata.status
  }

  @objc
  public init(id: String, custom: KMPAnyJSON, status: String?) {
    self.id = id
    self.custom = custom.asMap()
    self.status = status
  }
}

// MARK: - KMPUserMetadata

@objc
public class KMPUserMetadata: NSObject {
  @objc public var id: String
  @objc public var name: String?
  @objc public var externalId: String?
  @objc public var profileUrl: String?
  @objc public var email: String?
  @objc public var custom: [String: Any]?
  @objc public var updated: String?
  @objc public var eTag: String?
  @objc public var type: String?
  @objc public var status: String?

  @objc public var hasName: Bool = false
  @objc public var hasExternalId: Bool = false
  @objc public var hasProfileUrl: Bool = false
  @objc public var hasEmail: Bool = false
  @objc public var hasCustom: Bool = false
  @objc public var hasType: Bool = false
  @objc public var hasStatus: Bool = false

  @objc
  public init(
    id: String,
    custom: KMPAnyJSON?,
    status: String?
  ) {
    self.id = id
    self.custom = custom?.asMap()
    self.status = status
  }

  // swiftlint:disable:next cyclomatic_complexity
  init(changeset: PubNubUUIDMetadataChangeset) {
    self.id = changeset.metadataId
    self.updated = DateFormatter.iso8601.string(from: changeset.updated)
    self.eTag = changeset.eTag

    for change in changeset.changes {
      switch change {
      case let .stringOptional(keyPath, value):
        switch keyPath {
        case \.name:
          self.name = value
          self.hasName = true
        case \.type:
          self.type = value
          self.hasType = true
        case \.status:
          self.status = value
          self.hasStatus = true
        case \.externalId:
          self.externalId = value
          self.hasExternalId = true
        case \.profileURL:
          self.profileUrl = value
          self.hasProfileUrl = true
        case \.email:
          self.email = value
          self.hasEmail = true
        default:
          break
        }
      case .customOptional(_, let value):
        if let value {
          self.custom = value.asObjCRepresentable()
          self.hasCustom = true
        } else {
          self.custom = nil
          self.hasCustom = true
        }
      }
    }
  }

  init(metadata: PubNubUserMetadata) {
    self.id = metadata.metadataId
    self.name = metadata.name
    self.externalId = metadata.externalId
    self.profileUrl = metadata.profileURL
    self.email = metadata.email
    self.custom = metadata.custom?.asObjCRepresentable()
    self.updated = if let date = metadata.updated { DateFormatter.iso8601.string(from: date) } else { nil }
    self.eTag = metadata.eTag
    self.type = metadata.type
    self.status = metadata.status
  }
}

// MARK: - KMPMembershipMetadata

@objc
public class KMPMembershipMetadata: NSObject {
  @objc public var uuidMetadataId: String
  @objc public var channelMetadataId: String
  @objc public var status: String?
  @objc public var type: String?
  @objc public var user: KMPUserMetadata?
  @objc public var channel: KMPChannelMetadata?
  @objc public var updated: String?
  @objc public var eTag: String?
  @objc public var custom: [String: Any]?

  init(from: PubNubMembershipMetadata) {
    self.uuidMetadataId = from.uuidMetadataId
    self.channelMetadataId = from.channelMetadataId
    self.status = from.status
    self.type = from.type
    self.user = if let user = from.uuid { KMPUserMetadata(metadata: user) } else { nil }
    self.channel = if let channel = from.channel { KMPChannelMetadata(metadata: channel) } else { nil }
    self.updated =  if let date = from.updated { DateFormatter.iso8601.string(from: date) } else { nil }
    self.eTag = from.eTag
    self.custom = from.custom?.asObjCRepresentable()
  }
}
