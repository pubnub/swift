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

// MARK: - PubNubObjectEventResultObjC

@objc
public class PubNubObjectEventResultObjC: NSObject {
  @objc public let channel: String
  @objc public let subscription: String?
  @objc public let timetoken: NSNumber?
  @objc public let userMetadata: AnyJSONObjC?
  @objc public let publisher: String?
  @objc public let message: PubNubObjectEventMessageObjC

  private init(
    channel: String,
    subscription: String? = nil,
    timetoken: NSNumber? = nil,
    userMetadata: AnyJSON? = nil,
    publisher: String? = nil,
    message: PubNubObjectEventMessageObjC
  ) {
    self.channel = channel
    self.subscription = subscription
    self.timetoken = timetoken
    self.userMetadata = if let metadata = userMetadata { AnyJSONObjC(metadata.codableValue) } else { nil }
    self.publisher = publisher
    self.message = message
  }

  static func from(event: PubNubAppContextEvent) -> PubNubObjectEventResultObjC {
    switch event {
    case .userMetadataSet(let changeset):
      return PubNubObjectEventResultObjC(
        channel: "", // TODO: Missing channel name
        message: PubNubSetUUIDMetadataEventMessageObjC(data: PubNubUUIDMetadataObjC(changeset: changeset))
      )
    case .userMetadataRemoved(let metadataId):
      return PubNubObjectEventResultObjC(
        channel: "", // TODO: Missing channel name
        message: PubNubDeleteUUIDMetadataEventMessageObjC(uuid: metadataId)
      )
    case .channelMetadataSet(let changeset):
      return PubNubObjectEventResultObjC(
        channel: "", // TODO: Missing channel name
        message: PubNubSetChannelMetadataEventMessageObjC(data: PubNubChannelMetadataObjC(changeset: changeset))
      )
    case .channelMetadataRemoved(let metadataId):
      return PubNubObjectEventResultObjC(
        channel: "", // TODO: Missing channel name
        message: PubNubDeleteChannelMetadataEventMessageObjC(channel: metadataId)
      )
    case .membershipMetadataSet(let metadata):
      return PubNubObjectEventResultObjC(
        channel: "", // TODO: Missing channel name
        message: PubNubSetMembershipEventMessageObjC(data: PubNubSetMembershipEventObjC(metadata: metadata))
      )
    case .membershipMetadataRemoved(let metadata):
      return PubNubObjectEventResultObjC(
        channel: "", // TODO: Missing channel name
        message: PubNubDeleteMembershipEventMessageObjC(data: PubNubDeleteMembershipEventObjC(
          channelId: metadata.channelMetadataId,
          uuid: metadata.uuidMetadataId
        ))
      )
    }
  }
}

@objc
public class PubNubObjectEventMessageObjC: NSObject {
  @objc public let source: String
  @objc public let version: String
  @objc public let event: String
  @objc public let type: String

  // TODO: Missing source, version, event, type
  init(
    source: String,
    version: String,
    event: String,
    type: String
  ) {
    self.source = source
    self.version = version
    self.event = event
    self.type = type
  }
}

// MARK: - SetChannelMetadata

@objc
public class PubNubSetChannelMetadataEventMessageObjC: PubNubObjectEventMessageObjC {
  @objc public let data: PubNubChannelMetadataObjC

  init(
    source: String = "",
    version: String = "",
    event: String = "",
    type: String = "",
    data: PubNubChannelMetadataObjC
  ) {
    self.data = data
    super.init(
      source: source,
      version: version,
      event: event,
      type: type
    )
  }
}

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
    self.updated = changeset.updated.stringOptional // TODO: Date format
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
    self.updated = metadata.updated?.stringOptional // TODO: Date format
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

// MARK: - SetUUIDMetadata

@objc
public class PubNubSetUUIDMetadataEventMessageObjC: PubNubObjectEventMessageObjC {
  @objc public let data: PubNubUUIDMetadataObjC

  init(
    source: String = "",
    version: String = "",
    event: String = "",
    type: String = "",
    data: PubNubUUIDMetadataObjC
  ) {
    self.data = data
    super.init(source: source, version: version, event: event, type: type)
  }
}

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

  init(changeset: PubNubUUIDMetadataChangeset) {
    self.id = changeset.metadataId
    self.updated = changeset.updated.stringOptional // TODO: Date format
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
    self.custom = AnyJSONObjC(AnyJSON(metadata.custom as Any))
    self.updated = metadata.updated?.stringOptional // TODO: Date format
    self.eTag = metadata.eTag
    self.type = metadata.type
    self.status = metadata.status
  }
}

// MARK: - DeleteChannelMetadata

@objc
public class PubNubDeleteChannelMetadataEventMessageObjC: PubNubObjectEventMessageObjC {
  @objc public let channel: String

  init(
    source: String = "",
    version: String = "",
    event: String = "",
    type: String = "",
    channel: String
  ) {
    self.channel = channel
    super.init(source: source, version: version, event: event, type: type)
  }
}

// MARK: - DeleteUUIDMetadata

@objc
public class PubNubDeleteUUIDMetadataEventMessageObjC: PubNubObjectEventMessageObjC {
  @objc public let uuid: String

  init(
    source: String = "",
    version: String = "",
    event: String = "",
    type: String = "",
    uuid: String
  ) {
    self.uuid = uuid
    super.init(source: source, version: version, event: event, type: type)
  }
}

// MARK: - SetMembership

@objc
public class PubNubSetMembershipEventMessageObjC: PubNubObjectEventMessageObjC {
  @objc public let data: PubNubSetMembershipEventObjC

  init(
    source: String = "",
    version: String = "",
    event: String = "",
    type: String = "",
    data: PubNubSetMembershipEventObjC
  ) {
    self.data = data
    super.init(
      source: source,
      version: version,
      event: event,
      type: type
    )
  }
}

@objc
public class PubNubSetMembershipEventObjC: NSObject {
  @objc public let channel: String
  @objc public let uuid: String
  @objc public let custom: AnyJSONObjC?
  @objc public let eTag: String
  @objc public let updated: String
  @objc public let status: String?

  init(metadata: PubNubMembershipMetadata) {
    self.channel = metadata.channelMetadataId
    self.uuid = metadata.uuidMetadataId
    self.custom = if let custom = metadata.custom { AnyJSONObjC(AnyJSON(custom)) } else { nil }
    self.eTag = metadata.eTag ?? ""
    self.updated = metadata.updated?.stringOptional ?? "" // TODO: Date format
    self.status = metadata.status
  }
}

// MARK: - DeleteMembership

@objc
public class PubNubDeleteMembershipEventMessageObjC: PubNubObjectEventMessageObjC {
  @objc public let data: PubNubDeleteMembershipEventObjC

  init(
    source: String = "",
    version: String = "",
    event: String = "",
    type: String = "",
    data: PubNubDeleteMembershipEventObjC
  ) {
    self.data = data
    super.init(source: source, version: version, event: event, type: type)
  }
}

@objc
public class PubNubDeleteMembershipEventObjC: NSObject {
  @objc public let channelId: String
  @objc public let uuid: String

  init(channelId: String, uuid: String) {
    self.channelId = channelId
    self.uuid = uuid
  }
}
