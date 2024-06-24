//
//  PubNubObjectEventResult.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - PubNubAppContextEventObjC

@objc
public class PubNubAppContextEventObjC: NSObject {
  @objc public let channel: String
  @objc public let subscription: String?
  @objc public let timetoken: NSNumber?
  @objc public let userMetadata: AnyJSONObjC?
  @objc public let publisher: String?
  @objc public let source: String
  @objc public let version: String
  @objc public let event: String
  @objc public let type: String

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
    self.userMetadata = if let metadata = userMetadata { AnyJSONObjC(metadata.codableValue) } else { nil }
    self.publisher = publisher
  }
}

// MARK: - PubNubSetUUIDMetadataResultObjC

@objc
public class PubNubSetUUIDMetadataResultObjC: PubNubAppContextEventObjC {
  @objc public let metadata: PubNubUUIDMetadataObjC

  init(metadata: PubNubUUIDMetadataObjC) {
    self.metadata = metadata
  }
}

// MARK: - PubNubRemoveUUIDMetadataResultObjC

@objc
public class PubNubRemoveUUIDMetadataResultObjC: PubNubAppContextEventObjC {
  @objc public let uuid: String

  init(uuid: String) {
    self.uuid = uuid
    super.init()
  }
}

// MARK: - PubNubSetChannelMetadataResultObjC

@objc
public class PubNubSetChannelMetadataResultObjC: PubNubAppContextEventObjC {
  @objc public let metadata: PubNubChannelMetadataObjC

  init(metadata: PubNubChannelMetadataObjC) {
    self.metadata = metadata
    super.init()
  }
}

// MARK: - PubNubRemoveChannelMetadataResultObjC

@objc
public class PubNubRemoveChannelMetadataResultObjC: PubNubAppContextEventObjC {
  @objc public let channelMetadataId: String

  init(channelMetadataId: String) {
    self.channelMetadataId = channelMetadataId
    super.init()
  }
}

// MARK: - PubNubSetMembershipResultObjC

@objc
public class PubNubSetMembershipResultObjC: PubNubAppContextEventObjC {
  @objc public let metadata: PubNubMembershipMetadataObjC

  init(metadata: PubNubMembershipMetadataObjC) {
    self.metadata = metadata
  }
}

// MARK: - PubNubRemoveMembershipResultObjC

@objc
public class PubNubRemoveMembershipResultObjC: PubNubAppContextEventObjC {
  @objc public let channelId: String
  @objc public let uuid: String

  init(channelId: String, uuid: String) {
    self.channelId = channelId
    self.uuid = uuid
  }
}

// MARK: - PubNubAppContextEventObjC (Factory Method)

extension PubNubAppContextEventObjC {
  static func from(event: PubNubAppContextEvent) -> PubNubAppContextEventObjC {
    switch event {
    case .userMetadataSet(let changeset):
      return PubNubSetUUIDMetadataResultObjC(metadata: PubNubUUIDMetadataObjC(changeset: changeset))
    case .userMetadataRemoved(let metadataId):
      return PubNubRemoveUUIDMetadataResultObjC(uuid: metadataId)
    case .channelMetadataSet(let changeset):
      return PubNubSetChannelMetadataResultObjC(metadata: PubNubChannelMetadataObjC(changeset: changeset))
    case .channelMetadataRemoved(let metadataId):
      return PubNubRemoveChannelMetadataResultObjC(channelMetadataId: metadataId)
    case .membershipMetadataSet(let metadata):
      return PubNubSetMembershipResultObjC(metadata: PubNubMembershipMetadataObjC(from: metadata))
    case .membershipMetadataRemoved(let metadata):
      return PubNubRemoveMembershipResultObjC(channelId: metadata.channelMetadataId, uuid: metadata.uuidMetadataId)
    }
  }
}

// MARK: - PubNubChannelMetadataObjC

@objc
public class PubNubChannelMetadataObjC: NSObject {
  @objc public var id: String
  @objc public var name: String?
  @objc public var descr: String?
  @objc public var custom: AnyJSONObjC?
  @objc public var updated: String?
  @objc public var eTag: String?
  @objc public var type: String?
  @objc public var status: String?

  init(changeset: PubNubChannelMetadataChangeset) {
    self.id = changeset.metadataId
    self.updated = DateFormatter.iso8601.string(from: changeset.updated )
    self.eTag = changeset.eTag

    for change in changeset.changes {
      switch change {
      case .stringOptional(let keyPath, let value):
        switch keyPath {
        case \.name:
          self.name = value
        case \.type:
          self.type = value
        case \.status:
          self.status = value
        case \.channelDescription:
          self.descr = value
        default:
          break
        }
      case .customOptional(_, let value):
        if let value {
          self.custom = AnyJSONObjC(AnyJSON(value.mapValues { $0.codableValue }))
        } else {
          self.custom = nil
        }
      }
    }
  }

  init(metadata: PubNubChannelMetadata) {
    self.id = metadata.metadataId
    self.name = metadata.name
    self.descr = metadata.channelDescription
    self.custom = AnyJSONObjC(AnyJSON(metadata.custom as Any))
    self.updated = if let date = metadata.updated { DateFormatter.iso8601.string(from: date) } else { nil }
    self.eTag = metadata.eTag
    self.type = metadata.type
    self.status = metadata.status
  }

  @objc
  public init(id: String, custom: AnyJSONObjC?, status: String?) {
    self.id = id
    self.custom = custom
    self.status = status
  }
}

// MARK: - PubNubUUIDMetadataObjC

@objc
public class PubNubUUIDMetadataObjC: NSObject {
  @objc public var id: String
  @objc public var name: String?
  @objc public var externalId: String?
  @objc public var profileUrl: String?
  @objc public var email: String?
  @objc public var custom: AnyJSONObjC?
  @objc public var updated: String?
  @objc public var eTag: String?
  @objc public var type: String?
  @objc public var status: String?

  @objc
  public init(
    id: String,
    custom: Any?,
    status: String?
  ) {
    self.id = id
    self.custom = if let custom { AnyJSONObjC(custom) } else { nil }
    self.status = status
  }

  init(changeset: PubNubUUIDMetadataChangeset) {
    self.id = changeset.metadataId
    self.updated = DateFormatter.iso8601.string(from: changeset.updated)
    self.eTag = changeset.eTag

    for change in changeset.changes {
      switch change {
      case .stringOptional(let keyPath, let value):
        switch keyPath {
        case \.name:
          self.name = value
        case \.type:
          self.type = value
        case \.status:
          self.status = value
        case \.externalId:
          self.externalId = value
        case \.profileURL:
          self.profileUrl = value
        case \.email:
          self.email = value
        default:
          break
        }
      case .customOptional(_, let value):
        if let value {
          self.custom = AnyJSONObjC(AnyJSON(value.mapValues { $0.codableValue.rawValue }))
        } else {
          self.custom = nil
        }
      }
    }
  }

  init(metadata: PubNubUUIDMetadata) {
    self.id = metadata.metadataId
    self.name = metadata.name
    self.externalId = metadata.externalId
    self.profileUrl = metadata.profileURL
    self.email = metadata.email
    self.custom = AnyJSONObjC(AnyJSON(metadata.custom as Any))
    self.updated = if let date = metadata.updated { DateFormatter.iso8601.string(from: date) } else { nil }
    self.eTag = metadata.eTag
    self.type = metadata.type
    self.status = metadata.status
  }
}

// MARK: - PubNubMembershipMetadataObjC

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
    self.updated =  if let date = from.updated { DateFormatter.iso8601.string(from: date) } else { nil }
    self.eTag = from.eTag
    self.custom = from.custom
  }
}
