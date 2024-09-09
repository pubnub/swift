//
//  PubNubObjC+AppContext.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// All public symbols in this file that are annotated with @objc are intended to allow interoperation
/// with Kotlin Multiplatform for other PubNub frameworks.
///
/// While these symbols are public, they are intended strictly for internal usage.

/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

extension PubNubObjC {
  private func objectSortProperties(from properties: [PubNubObjectSortPropertyObjC]) -> [PubNub.ObjectSortField] {
    properties.compactMap {
      if let property = PubNub.ObjectSortProperty(rawValue: $0.key) {
        return PubNub.ObjectSortField(property: property, ascending: $0.direction == "asc")
      } else {
        return nil
      }
    }
  }

  private func convertPage(from page: PubNubHashedPageObjC?) -> PubNubHashedPage? {
    guard let page = page else {
      return nil
    }
    return PubNub.Page(
      start: page.start,
      end: page.end,
      totalCount: page.totalCount?.intValue
    )
  }

  private func convertDictionaryToScalars(_ dictionary: [String: Any]?) -> [String: JSONCodableScalar]? {
    dictionary?.compactMapValues { item -> JSONCodableScalar? in
      if let number = item as? NSNumber {
        if let intValue = number as? Int {
          return intValue
        } else if let doubleValue = number as? Double {
          return doubleValue
        } else if let boolValue = number as? Bool {
          return boolValue
        } else {
          return nil
        }
      } else {
        return item as? JSONCodableScalar
      }
    }
  }

  // TODO: Swift SDK allows to sort by the status field, it's not present in KMP

  private func mapToMembershipSortFields(from array: [String]) -> [PubNub.MembershipSortField] {
    array.compactMap {
      switch $0 {
      case "channel.id", "uuid.id":
        return PubNub.MembershipSortField(property: .object(.id))
      case "channel.name", "uuid.name":
        return PubNub.MembershipSortField(property: .object(.name))
      case "channel.updated", "uuid.updated":
        return PubNub.MembershipSortField(property: .object(.updated))
      case "updated":
        return PubNub.MembershipSortField(property: .updated)
      default:
        return nil
      }
    }
  }
}

@objc
public extension PubNubObjC {
  func getAllChannelMetadata(
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [PubNubObjectSortPropertyObjC],
    includeCount: Bool,
    includeCustom: Bool,
    onSuccess: @escaping (([PubNubChannelMetadataObjC], NSNumber?, PubNubHashedPageObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.allChannelMetadata(
      include: PubNub.IncludeFields(custom: includeCustom, totalCount: includeCount),
      filter: filter,
      sort: objectSortProperties(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.channels.map { PubNubChannelMetadataObjC(metadata: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next)
        )
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func getChannelMetadata(
    channel: String,
    includeCustom: Bool,
    onSuccess: @escaping ((PubNubChannelMetadataObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetch(channel: channel, include: includeCustom) {
      switch $0 {
      case .success(let metadata):
        onSuccess(PubNubChannelMetadataObjC(metadata: metadata))
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func setChannelMetadata(
    channel: String,
    name: String?,
    description: String?,
    custom: AnyJSONObjC?,
    includeCustom: Bool,
    type: String?,
    status: String?,
    onSuccess: @escaping ((PubNubChannelMetadataObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.set(
      channel: PubNubChannelMetadataBase(
        metadataId: channel,
        name: name,
        type: type,
        status: status,
        channelDescription: description,
        custom: convertDictionaryToScalars(custom?.asMap())
      ),
      include: includeCustom
    ) {
      switch $0 {
      case .success(let metadata):
        onSuccess(PubNubChannelMetadataObjC(metadata: metadata))
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func removeChannelMetadata(
    channel: String,
    onSuccess: @escaping ((String) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.remove(channel: channel) {
      switch $0 {
      case .success(let channel):
        onSuccess(channel)
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func getAllUUIDMetadata(
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [PubNubObjectSortPropertyObjC],
    includeCount: Bool,
    includeCustom: Bool,
    onSuccess: @escaping (([PubNubUUIDMetadataObjC], NSNumber?, PubNubHashedPageObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.allUUIDMetadata(
      include: PubNub.IncludeFields(custom: includeCustom, totalCount: includeCount),
      filter: filter,
      sort: objectSortProperties(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.uuids.map { PubNubUUIDMetadataObjC(metadata: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next)
        )
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func getUUIDMetadata(
    uuid: String?,
    includeCustom: Bool,
    onSuccess: @escaping ((PubNubUUIDMetadataObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetch(uuid: uuid, include: includeCustom) {
      switch $0 {
      case .success(let metadata):
        onSuccess(PubNubUUIDMetadataObjC(metadata: metadata))
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func setUUIDMetadata(
    uuid: String?,
    name: String?,
    externalId: String?,
    profileUrl: String?,
    email: String?,
    custom: AnyJSONObjC?,
    includeCustom: Bool,
    type: String?,
    status: String?,
    onSuccess: @escaping ((PubNubUUIDMetadataObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.set(
      uuid: PubNubUUIDMetadataBase(
        metadataId: uuid ?? pubnub.configuration.userId,
        name: name,
        type: type,
        status: status,
        externalId: externalId,
        profileURL: profileUrl,
        email: email,
        custom: convertDictionaryToScalars(custom?.asMap())
      ),
      include: includeCustom
    ) {
      switch $0 {
      case .success(let metadata):
        onSuccess(PubNubUUIDMetadataObjC(metadata: metadata))
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func removeUUIDMetadata(
    uuid: String?,
    onSuccess: @escaping ((String) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.remove(uuid: uuid) {
      switch $0 {
      case .success(let result):
        onSuccess(result)
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func getMemberships(
    uuid: String?,
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [String],
    includeCount: Bool,
    includeCustom: Bool,
    includeChannelFields: Bool,
    includeChannelCustomFields: Bool,
    includeChannelType: Bool,
    onSuccess: @escaping (([PubNubMembershipMetadataObjC], NSNumber?, PubNubHashedPageObjC?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetchMemberships(
      uuid: uuid,
      include: .init(
        customFields: includeCustom,
        channelFields: includeChannelFields,
        channelCustomFields: includeChannelCustomFields,
        channelTypeField: includeChannelType,
        totalCount: includeCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { PubNubMembershipMetadataObjC(from: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next)
        )
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func setMemberships(
    channels: [PubNubChannelMetadataObjC],
    uuid: String?,
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [String],
    includeCount: Bool,
    includeCustom: Bool,
    includeChannelFields: Bool,
    includeChannelCustomFields: Bool,
    includeChannelType: Bool,
    onSuccess: @escaping (([PubNubMembershipMetadataObjC], NSNumber?, PubNubHashedPageObjC?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.setMemberships(
      uuid: uuid,
      channels: channels.map {
        PubNubMembershipMetadataBase(
          uuidMetadataId: uuid ?? pubnub.configuration.userId,
          channelMetadataId: $0.id,
          status: $0.status,
          custom: convertDictionaryToScalars($0.custom)
        )
      },
      include: .init(
        customFields: includeCustom,
        channelFields: includeChannelFields,
        channelCustomFields: includeChannelCustomFields,
        channelTypeField: includeChannelType,
        totalCount: includeCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { PubNubMembershipMetadataObjC(from: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next)
        )
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func removeMemberships(
    channels: [String],
    uuid: String?,
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [String],
    includeCount: Bool,
    includeCustom: Bool,
    includeChannelFields: Bool,
    includeChannelCustomFields: Bool,
    includeChannelType: Bool,
    onSuccess: @escaping (([PubNubMembershipMetadataObjC], NSNumber?, PubNubHashedPageObjC?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.removeMemberships(
      uuid: uuid,
      channels: channels.map {
        PubNubMembershipMetadataBase(
          uuidMetadataId: uuid ?? pubnub.configuration.userId,
          channelMetadataId: $0
        )
      },
      include: .init(
        customFields: includeCustom,
        channelFields: includeChannelFields,
        channelCustomFields: includeChannelCustomFields,
        channelTypeField: includeChannelType,
        totalCount: includeCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { PubNubMembershipMetadataObjC(from: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next)
        )
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func getChannelMembers(
    channel: String,
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [String],
    includeCount: Bool,
    includeCustom: Bool,
    includeUUIDFields: Bool,
    includeUUIDCustomFields: Bool,
    includeUUIDType: Bool,
    onSuccess: @escaping (([PubNubMembershipMetadataObjC], NSNumber?, PubNubHashedPageObjC?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetchMembers(
      channel: channel,
      include: .init(
        customFields: includeCustom,
        uuidFields: includeUUIDFields,
        uuidCustomFields: includeUUIDCustomFields,
        uuidTypeField: includeUUIDType,
        totalCount: includeCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { PubNubMembershipMetadataObjC(from: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next)
        )
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func setChannelMembers(
    channel: String,
    uuids: [PubNubUUIDMetadataObjC],
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [String],
    includeCount: Bool,
    includeCustom: Bool,
    includeUUIDFields: Bool,
    includeUUIDCustomFields: Bool,
    includeUUIDType: Bool,
    onSuccess: @escaping (([PubNubMembershipMetadataObjC], NSNumber?, PubNubHashedPageObjC?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.setMembers(
      channel: channel,
      uuids: uuids.map {
        PubNubMembershipMetadataBase(
          uuidMetadataId: $0.id,
          channelMetadataId: channel,
          status: $0.status,
          custom: convertDictionaryToScalars($0.custom)
        )
      },
      include: .init(
        customFields: includeCustom,
        uuidFields: includeUUIDFields,
        uuidCustomFields: includeUUIDCustomFields,
        uuidTypeField: includeUUIDType,
        totalCount: includeCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { PubNubMembershipMetadataObjC(from: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next)
        )
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }

  func removeChannelMembers(
    channel: String,
    uuids: [String],
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [String],
    includeCount: Bool,
    includeCustom: Bool,
    includeUUIDFields: Bool,
    includeUUIDCustomFields: Bool,
    includeUUIDType: Bool,
    onSuccess: @escaping (([PubNubMembershipMetadataObjC], NSNumber?, PubNubHashedPageObjC?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.removeMembers(
      channel: channel,
      uuids: uuids.map {
        PubNubMembershipMetadataBase(
          uuidMetadataId: $0,
          channelMetadataId: channel
        )
      },
      include: .init(
        customFields: includeCustom,
        uuidFields: includeUUIDFields,
        uuidCustomFields: includeUUIDCustomFields,
        uuidTypeField: includeUUIDType,
        totalCount: includeCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { PubNubMembershipMetadataObjC(from: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next)
        )
      case .failure(let error):
        onFailure(PubNubErrorObjC(underlying: error))
      }
    }
  }
  // swiftlint:disable:next file_length
}
