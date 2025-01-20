//
//  KMPPubNub+AppContext.swift
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

extension KMPPubNub {
  private func objectSortProperties(from properties: [KMPObjectSortProperty]) -> [PubNub.ObjectSortField] {
    properties.compactMap {
      if let property = PubNub.ObjectSortProperty(rawValue: $0.key) {
        return PubNub.ObjectSortField(property: property, ascending: $0.direction == "asc")
      } else {
        return nil
      }
    }
  }

  private func convertPage(from page: KMPHashedPage?) -> PubNubHashedPage? {
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

  private func mapToMembershipSortFields(from array: [String]) -> [PubNub.MembershipSortField] {
    array.compactMap {
      switch $0 {
      case "channel.id", "uuid.id":
        return PubNub.MembershipSortField(property: .object(.id))
      case "channel.name", "uuid.name":
        return PubNub.MembershipSortField(property: .object(.name))
      case "channel.updated", "uuid.updated":
        return PubNub.MembershipSortField(property: .object(.updated))
      case "channel.type", "uuid.type":
        return PubNub.MembershipSortField(property: .object(.type))
      case "channel.status", "uuid.status":
        return PubNub.MembershipSortField(property: .object(.status))
      case "updated":
        return PubNub.MembershipSortField(property: .updated)
      case "status":
        return PubNub.MembershipSortField(property: .status)
      case "type":
        return PubNub.MembershipSortField(property: .type)
      default:
        return nil
      }
    }
  }

  private func mapToPubNubIncludeFields(from includeFields: KMPAppContextIncludeFields) -> PubNub.IncludeFields {
    PubNub.IncludeFields(
      custom: includeFields.includeCustom,
      type: includeFields.includeType,
      status: includeFields.includeStatus,
      totalCount: includeFields.includeTotalCount
    )
  }

  private func mapToChannelIncludeFields(from includeFields: KMPChannelIncludeFields) -> PubNub.ChannelIncludeFields {
    PubNub.ChannelIncludeFields(
      custom: includeFields.includeCustom,
      type: includeFields.includeType,
      status: includeFields.includeStatus,
      totalCount: includeFields.includeTotalCount
    )
  }

  private func mapToPubNubUserIncludeFields(from includeFields: KMPUserIncludeFields) -> PubNub.UserIncludeFields {
    PubNub.UserIncludeFields(
      custom: includeFields.includeCustom,
      type: includeFields.includeType,
      status: includeFields.includeStatus,
      totalCount: includeFields.includeTotalCount
    )
  }
}

@objc
public extension KMPPubNub {
  func getAllChannelMetadata(
    limit: NSNumber?,
    page: KMPHashedPage?,
    filter: String?,
    sort: [KMPObjectSortProperty],
    include includeFields: KMPChannelIncludeFields,
    onSuccess: @escaping (([KMPChannelMetadata], NSNumber?, KMPHashedPage) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.allChannelMetadata(
      include: mapToPubNubIncludeFields(from: includeFields),
      filter: filter,
      sort: objectSortProperties(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.channels.map { KMPChannelMetadata(metadata: $0) },
          res.next?.totalCount?.asNumber,
          KMPHashedPage(page: res.next)
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func getChannelMetadata(
    metadataId: String,
    include includeFields: KMPChannelIncludeFields,
    onSuccess: @escaping ((KMPChannelMetadata) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetchChannelMetadata(metadataId, include: mapToChannelIncludeFields(from: includeFields)) {
      switch $0 {
      case .success(let metadata):
        onSuccess(KMPChannelMetadata(metadata: metadata))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func setChannelMetadata(
    metadataId: String,
    name: String?,
    description: String?,
    custom: KMPAnyJSON?,
    type: String?,
    status: String?,
    ifMatchesEtag: String?,
    include includeFields: KMPChannelIncludeFields,
    onSuccess: @escaping ((KMPChannelMetadata) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    let channelMetadata = PubNubChannelMetadataBase(
      metadataId: metadataId,
      name: name,
      type: type,
      status: status,
      channelDescription: description,
      custom: convertDictionaryToScalars(custom?.asMap())
    )
    pubnub.setChannelMetadata(
      channelMetadata,
      ifMatchesEtag: ifMatchesEtag,
      include: mapToChannelIncludeFields(from: includeFields)
    ) {
      switch $0 {
      case .success(let metadata):
        onSuccess(KMPChannelMetadata(metadata: metadata))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func removeChannelMetadata(
    metadataId: String,
    onSuccess: @escaping ((String) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.removeChannelMetadata(metadataId) {
      switch $0 {
      case .success(let channel):
        onSuccess(channel)
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func getAllUserMetadata(
    limit: NSNumber?,
    page: KMPHashedPage?,
    filter: String?,
    sort: [KMPObjectSortProperty],
    include includeFields: KMPUserIncludeFields,
    onSuccess: @escaping (([KMPUserMetadata], NSNumber?, KMPHashedPage) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.allUserMetadata(
      include: mapToPubNubUserIncludeFields(from: includeFields),
      filter: filter,
      sort: objectSortProperties(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.users.map { KMPUserMetadata(metadata: $0) },
          res.next?.totalCount?.asNumber,
          KMPHashedPage(page: res.next)
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func getUserMetadata(
    metadataId: String?,
    include includeFields: KMPUserIncludeFields,
    onSuccess: @escaping ((KMPUserMetadata) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetchUserMetadata(metadataId, include: mapToPubNubUserIncludeFields(from: includeFields)) {
      switch $0 {
      case .success(let metadata):
        onSuccess(KMPUserMetadata(metadata: metadata))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func setUserMetadata(
    metadataId: String?,
    name: String?,
    externalId: String?,
    profileUrl: String?,
    email: String?,
    custom: KMPAnyJSON?,
    type: String?,
    status: String?,
    ifMatchesEtag: String?,
    include includeFields: KMPUserIncludeFields,
    onSuccess: @escaping ((KMPUserMetadata) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    let userMetadata = PubNubUserMetadataBase(
      metadataId: metadataId ?? pubnub.configuration.userId,
      name: name,
      type: type,
      status: status,
      externalId: externalId,
      profileURL: profileUrl,
      email: email,
      custom: convertDictionaryToScalars(custom?.asMap())
    )
    pubnub.setUserMetadata(
      userMetadata,
      ifMatchesEtag: ifMatchesEtag,
      include: mapToPubNubUserIncludeFields(from: includeFields)
    ) {
      switch $0 {
      case .success(let metadata):
        onSuccess(KMPUserMetadata(metadata: metadata))
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func removeUserMetadata(
    metadataId: String?,
    onSuccess: @escaping ((String) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.removeUserMetadata(metadataId) {
      switch $0 {
      case .success(let result):
        onSuccess(result)
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func getMemberships(
    userId: String?,
    limit: NSNumber?,
    page: KMPHashedPage?,
    filter: String?,
    sort: [String],
    include includeFields: KMPMembershipIncludeFields,
    onSuccess: @escaping (([KMPMembershipMetadata], NSNumber?, KMPHashedPage?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetchMemberships(
      userId: userId,
      include: .init(
        customFields: includeFields.includeCustom,
        channelFields: includeFields.includeChannel,
        statusField: includeFields.includeStatus,
        typeField: includeFields.includeType,
        channelCustomFields: includeFields.includeChannelCustom,
        channelTypeField: includeFields.includeChannelType,
        channelStatusField: includeFields.includeChannelStatus,
        totalCount: includeFields.includeTotalCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { KMPMembershipMetadata(from: $0) },
          res.next?.totalCount?.asNumber,
          KMPHashedPage(page: res.next)
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func setMemberships(
    channels: [KMPChannelMetadata],
    userId: String?,
    limit: NSNumber?,
    page: KMPHashedPage?,
    filter: String?,
    sort: [String],
    include includeFields: KMPMembershipIncludeFields,
    onSuccess: @escaping (([KMPMembershipMetadata], NSNumber?, KMPHashedPage?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.setMemberships(
      userId: userId,
      channels: channels.map {
        PubNubMembershipMetadataBase(
          userMetadataId: userId ?? pubnub.configuration.userId,
          channelMetadataId: $0.id,
          status: $0.status,
          type: $0.type,
          custom: convertDictionaryToScalars($0.custom)
        )
      },
      include: .init(
        customFields: includeFields.includeCustom,
        channelFields: includeFields.includeChannel,
        statusField: includeFields.includeStatus,
        typeField: includeFields.includeType,
        channelCustomFields: includeFields.includeChannelCustom,
        channelTypeField: includeFields.includeChannelType,
        channelStatusField: includeFields.includeChannelStatus,
        totalCount: includeFields.includeTotalCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { KMPMembershipMetadata(from: $0) },
          res.next?.totalCount?.asNumber,
          KMPHashedPage(page: res.next)
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func removeMemberships(
    channels: [String],
    userId: String?,
    limit: NSNumber?,
    page: KMPHashedPage?,
    filter: String?,
    sort: [String],
    include includeFields: KMPMembershipIncludeFields,
    onSuccess: @escaping (([KMPMembershipMetadata], NSNumber?, KMPHashedPage?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.removeMemberships(
      userId: userId,
      channels: channels.map {
        PubNubMembershipMetadataBase(
          userMetadataId: userId ?? pubnub.configuration.userId,
          channelMetadataId: $0
        )
      },
      include: .init(
        customFields: includeFields.includeCustom,
        channelFields: includeFields.includeChannel,
        statusField: includeFields.includeStatus,
        typeField: includeFields.includeType,
        channelCustomFields: includeFields.includeChannelCustom,
        channelTypeField: includeFields.includeChannelType,
        channelStatusField: includeFields.includeChannelStatus,
        totalCount: includeFields.includeTotalCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { KMPMembershipMetadata(from: $0) },
          res.next?.totalCount?.asNumber,
          KMPHashedPage(page: res.next)
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func getChannelMembers(
    channel: String,
    limit: NSNumber?,
    page: KMPHashedPage?,
    filter: String?,
    sort: [String],
    include includeFields: KMPMemberIncludeFields,
    onSuccess: @escaping (([KMPMembershipMetadata], NSNumber?, KMPHashedPage?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetchMembers(
      channel: channel,
      include: .init(
        customFields: includeFields.includeCustom,
        uuidFields: includeFields.includeUser,
        statusField: includeFields.includeStatus,
        typeField: includeFields.includeType,
        uuidCustomFields: includeFields.includeUserCustom,
        uuidTypeField: includeFields.includeUserType,
        uuidStatusField: includeFields.includeUserStatus,
        totalCount: includeFields.includeTotalCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { KMPMembershipMetadata(from: $0) },
          res.next?.totalCount?.asNumber,
          KMPHashedPage(page: res.next)
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func setChannelMembers(
    channel: String,
    users: [KMPUserMetadata],
    limit: NSNumber?,
    page: KMPHashedPage?,
    filter: String?,
    sort: [String],
    include includeFields: KMPMemberIncludeFields,
    onSuccess: @escaping (([KMPMembershipMetadata], NSNumber?, KMPHashedPage?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.setMembers(
      channel: channel,
      users: users.map {
        PubNubMembershipMetadataBase(
          userMetadataId: $0.id,
          channelMetadataId: channel,
          status: $0.status,
          type: $0.type,
          custom: convertDictionaryToScalars($0.custom)
        )
      },
      include: .init(
        customFields: includeFields.includeCustom,
        uuidFields: includeFields.includeUser,
        statusField: includeFields.includeStatus,
        typeField: includeFields.includeType,
        uuidCustomFields: includeFields.includeUserCustom,
        uuidTypeField: includeFields.includeUserType,
        uuidStatusField: includeFields.includeUserStatus,
        totalCount: includeFields.includeTotalCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { KMPMembershipMetadata(from: $0) },
          res.next?.totalCount?.asNumber,
          KMPHashedPage(page: res.next)
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }

  func removeChannelMembers(
    channel: String,
    users: [String],
    limit: NSNumber?,
    page: KMPHashedPage?,
    filter: String?,
    sort: [String],
    include includeFields: KMPMemberIncludeFields,
    onSuccess: @escaping (([KMPMembershipMetadata], NSNumber?, KMPHashedPage?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.removeMembers(
      channel: channel,
      users: users.map {
        PubNubMembershipMetadataBase(
          userMetadataId: $0,
          channelMetadataId: channel
        )
      },
      include: .init(
        customFields: includeFields.includeCustom,
        uuidFields: includeFields.includeUser,
        statusField: includeFields.includeStatus,
        typeField: includeFields.includeType,
        uuidCustomFields: includeFields.includeUserCustom,
        uuidTypeField: includeFields.includeUserType,
        uuidStatusField: includeFields.includeUserStatus,
        totalCount: includeFields.includeTotalCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { KMPMembershipMetadata(from: $0) },
          res.next?.totalCount?.asNumber,
          KMPHashedPage(page: res.next)
        )
      case .failure(let error):
        onFailure(KMPError(underlying: error))
      }
    }
  }
  // swiftlint:disable:next file_length
}
