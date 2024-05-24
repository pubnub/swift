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
public class PubNubObjectEventResultObjC : NSObject {
  @objc public var channel: String
  @objc public var subscription: String?
  @objc public var timetoken: NSNumber?
  @objc public var userMetadata: Any?
  @objc public var publisher: String?
  @objc public var message: PubNubObjectEventMessageObjC
  
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
  @objc public var source: String
  @objc public var version: String
  @objc public var event: String
  @objc public var type: String
  
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
  @objc public var data: PubNubChannelMetadataObjC
  
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
public class PubNubSetUUIDMetadataEventMessageObjC : PubNubObjectEventMessageObjC {
  @objc public var data: PubNubUUIDMetadataObjC
  
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
  @objc public var channel: String
  
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
  @objc public var uuid: String
  
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
  @objc public var data: PubNubSetMembershipEventObjC
  
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
public class PubNubSetMembershipEventObjC : NSObject {
  @objc public var channel: String
  @objc public var uuid: String
  @objc public var custom: Any?
  @objc public var eTag: String
  @objc public var updated: String
  @objc public var status: String?
  
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
  @objc public var data: PubNubDeleteMembershipEventObjC
  
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
public class PubNubDeleteMembershipEventObjC : NSObject {
  @objc public var channelId: String
  @objc public var uuid: String
  
  init(channelId: String, uuid: String) {
    self.channelId = channelId
    self.uuid = uuid
  }
}
