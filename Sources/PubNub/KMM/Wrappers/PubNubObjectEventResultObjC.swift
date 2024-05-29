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
  @objc public let userMetadata: Any?
  @objc public let publisher: String?
  @objc public let message: PubNubObjectEventMessageObjC

  private init(
    channel: String,
    subscription: String? = nil,
    timetoken: NSNumber? = nil,
    userMetadata: Any? = nil,
    publisher: String? = nil,
    message: PubNubObjectEventMessageObjC
  ) {
    self.channel = channel
    self.subscription = subscription
    self.timetoken = timetoken
    self.userMetadata = userMetadata
    self.publisher = publisher
    self.message = message
  }

  static func from(event: PubNubAppContextEvent) -> PubNubObjectEventResultObjC {
    switch event {
    case .userMetadataSet(let metadata):
      let object = PubNubUUIDMetadataObjC(
        id: metadata.metadataId,
        updated: metadata.updated.stringOptional, // TODO: Convert date object to correct String format
        eTag: metadata.eTag
      )
      for change in metadata.changes {
        switch change {
        case .stringOptional(let keyPath, let value):
          switch keyPath {
          case \.name:
            object.name = value
          case \.type:
            object.type = value
          case \.status:
            object.status = value
          case \.externalId:
            object.externalId = value
          case \.profileURL:
            object.profileUrl = value
          case \.email:
            object.email = value
          default:
            break
          }
        case .customOptional(_, let value):
          object.custom = value?.mapValues { $0.codableValue.rawValue }
        }
      }
      return PubNubObjectEventResultObjC(
        channel: "", // TODO: Missing channel name
        message: PubNubSetUUIDMetadataEventMessageObjC(data: object)
      )
    case .userMetadataRemoved(let metadataId):
      return PubNubObjectEventResultObjC(
        channel: "", // TODO: Missing channel name
        message: PubNubDeleteUUIDMetadataEventMessageObjC(uuid: metadataId)
      )
    case .channelMetadataSet(let metadata):
      let object = PubNubChannelMetadataObjC(
        id: metadata.metadataId,
        updated: metadata.updated.stringOptional, // TODO: Convert date object to correct String format
        eTag: metadata.eTag
      )
      for change in metadata.changes {
        switch change {
        case .stringOptional(let keyPath, let value):
          switch keyPath {
          case \.name:
            object.name = value
          case \.type:
            object.type = value
          case \.status:
            object.status = value
          case \.channelDescription:
            object.descr = value
          default:
            break
          }
        case .customOptional(_, let value):
          object.custom = value?.mapValues { $0.codableValue.rawValue }
        }
      }
      return PubNubObjectEventResultObjC(
        channel: "", // TODO: Missing channel name
        message: PubNubSetChannelMetadataEventMessageObjC(data: object)
      )
    case .channelMetadataRemoved(let metadataId):
      return PubNubObjectEventResultObjC(
        channel: "", // TODO: Missing channel name
        message: PubNubDeleteChannelMetadataEventMessageObjC(channel: metadataId)
      )
    case .membershipMetadataSet(let metadata):
      return PubNubObjectEventResultObjC(
        channel: "", // TODO: Missing channel name
        message: PubNubSetMembershipEventMessageObjC(
          data: PubNubSetMembershipEventObjC(
            channel: "", // TODO: Missing channel name
            uuid: metadata.uuidMetadataId,
            custom: metadata.custom,
            eTag: metadata.eTag?.stringOptional ?? "",
            updated: metadata.updated?.stringOptional ?? "", // TODO: Convert date object to correct String format
            status: metadata.status
          )
        )
      )
    case .membershipMetadataRemoved(let metadata):
      return PubNubObjectEventResultObjC(
        channel: "", // TODO: Missing channel name
        message: PubNubDeleteMembershipEventMessageObjC(
          data: PubNubDeleteMembershipEventObjC(
            channelId: metadata.channelMetadataId,
            uuid: metadata.uuidMetadataId
          )
        )
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
  @objc public var custom: Any?
  @objc public var updated: String?
  @objc public var eTag: String?
  @objc public var type: String?
  @objc public var status: String?

  init(
    id: String,
    name: String? = nil,
    descr: String? = nil,
    custom: Any? = nil,
    updated: String? = nil,
    eTag: String? = nil,
    type: String? = nil,
    status: String? = nil
  ) {
    self.id = id
    self.name = name
    self.descr = descr
    self.custom = custom
    self.updated = updated
    self.eTag = eTag
    self.type = type
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
  @objc public var custom: Any?
  @objc public var updated: String?
  @objc public var eTag: String?
  @objc public var type: String?
  @objc public var status: String?

  init(
    id: String,
    name: String? = nil,
    externalId: String? = nil,
    profileUrl: String? = nil,
    email: String? = nil,
    custom: Any? = nil,
    updated: String? = nil,
    eTag: String? = nil,
    type: String? = nil,
    status: String? = nil
  ) {
    self.id = id
    self.name = name
    self.externalId = externalId
    self.profileUrl = profileUrl
    self.email = email
    self.custom = custom
    self.updated = updated
    self.eTag = eTag
    self.type = type
    self.status = status
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
  @objc public let custom: Any?
  @objc public let eTag: String
  @objc public let updated: String
  @objc public let status: String?

  init(
    channel: String,
    uuid: String,
    custom: Any?,
    eTag: String,
    updated: String,
    status: String?
  ) {
    self.channel = channel
    self.uuid = uuid
    self.custom = custom
    self.eTag = eTag
    self.updated = updated
    self.status = status
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
