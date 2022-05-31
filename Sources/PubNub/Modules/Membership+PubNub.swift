//
//  Membership+PubNub.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public protocol PubNubMembershipInterface {
  func fetchMemberships(
    userId: String?,
    includeCustom: Bool,
    includeTotalCount: Bool,
    includeSpaceFields: Bool,
    includeSpaceCustomFields: Bool,
    filter: String?,
    sort: [PubNub.SpaceMembershipSort],
    limit: Int?,
    page: PubNubHashedPage?,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: @escaping ((Result<(memberships: [PubNubMembership], next: PubNubHashedPage?), Error>) -> Void)
  )

  func fetchMemberships(
    spaceId: String,
    includeCustom: Bool,
    includeTotalCount: Bool,
    includeUserFields: Bool,
    includeUserCustomFields: Bool,
    filter: String?,
    sort: [PubNub.UserMembershipSort],
    limit: Int?,
    page: PubNubHashedPage?,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: @escaping ((Result<(memberships: [PubNubMembership], next: PubNubHashedPage?), Error>) -> Void)
  )

  func addMemberships(
    users: [PubNubMembership.MembershipPartial],
    to spaceId: String,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )

  func addMemberships(
    spaces: [PubNubMembership.MembershipPartial],
    to userId: String?,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )

  func updateMemberships(
    users: [PubNubMembership.MembershipPartial],
    on spaceId: String,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )

  func updateMemberships(
    spaces: [PubNubMembership.MembershipPartial],
    on userId: String?,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )

  func removeMemberships(
    userIds: [String],
    from spaceId: String,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )

  func removeMemberships(
    spaceIds: [String],
    from userId: String?,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )
}

// MARK: - Request Objects

public extension PubNub {
  enum UserMembershipSort: Hashable {
    case status(ascending: Bool)
    case updated(ascending: Bool)

    case user(UserSort, ascending: Bool)

    var routerParameter: String {
      switch self {
      case let .status(ascending: ascending):
        return "status:\(ascending ? "" : "desc")"
      case let .updated(ascending: ascending):
        return "updated:\(ascending ? "" : "desc")"
      case let .user(nested, ascending):
        return "uuid.\(nested.rawValue):\(ascending ? "" : "desc")"
      }
    }
  }

  enum SpaceMembershipSort: Hashable {
    case status(ascending: Bool)
    case updated(ascending: Bool)

    case space(SpaceSort, ascending: Bool)

    var routerParameter: String {
      switch self {
      case let .status(ascending: ascending):
        return "status:\(ascending ? "" : "desc")"
      case let .updated(ascending: ascending):
        return "updated:\(ascending ? "" : "desc")"
      case let .space(nested, ascending):
        return "channel.\(nested.rawValue):\(ascending ? "" : "desc")"
      }
    }
  }
}

// MARK: - Module Impl.

extension PubNubMembershipModule: PubNubMembershipInterface {
  public func fetchMemberships(
    userId: String?,
    includeCustom: Bool = true,
    includeTotalCount: Bool = false,
    includeSpaceFields: Bool = false,
    includeSpaceCustomFields: Bool = false,
    filter: String? = nil,
    sort: [PubNub.SpaceMembershipSort] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = nil,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: @escaping ((Result<(memberships: [PubNubMembership], next: PubNubHashedPage?), Error>) -> Void)
  ) {
    let computedUserId = userId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

    let router = ObjectsMembershipsRouter(
      .fetchMemberships(
        uuidMetadataId: computedUserId,
        customFields: .include(
          custom: includeCustom,
          space: includeSpaceFields,
          spaceCustom: includeSpaceCustomFields
        ),
        totalCount: includeTotalCount,
        filter: filter,
        sort: sort.map { $0.routerParameter },
        limit: limit,
        start: page?.start,
        end: page?.end
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: PubNubMembershipsResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion(result.map { response in
          (
            memberships: response.payload.data.compactMap {
              PubNubMembershipMetadataBase(from: $0, other: computedUserId)?.convert()
            },
            next: try? PubNubHashedPageBase(from: response.payload)
          )
        })
      }
  }

  public func fetchMemberships(
    spaceId: String,
    includeCustom: Bool = true,
    includeTotalCount: Bool = false,
    includeUserFields: Bool = false,
    includeUserCustomFields: Bool = false,
    filter: String? = nil,
    sort: [PubNub.UserMembershipSort] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = nil,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: @escaping ((Result<(memberships: [PubNubMembership], next: PubNubHashedPage?), Error>) -> Void)
  ) {
    let router = ObjectsMembershipsRouter(
      .fetchMembers(
        channelMetadataId: spaceId,
        customFields: .include(
          custom: includeCustom,
          user: includeUserFields,
          userCustom: includeUserCustomFields
        ),
        totalCount: includeTotalCount,
        filter: filter,
        sort: sort.map { $0.routerParameter },
        limit: limit,
        start: page?.start,
        end: page?.end
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: PubNubMembershipsResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion(result.map { response in
          (
            memberships: response.payload.data.compactMap {
              PubNubMembershipMetadataBase(from: $0, other: spaceId)?.convert()
            },
            next: try? PubNubHashedPageBase(from: response.payload)
          )
        })
      }
  }

  public func addMemberships(
    users: [PubNubMembership.MembershipPartial],
    to spaceId: String,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    let router = ObjectsMembershipsRouter(
      .setMembers(
        channelMetadataId: spaceId,
        customFields: nil,
        totalCount: false,
        changes: .init(
          set: users.map { .init(metadataId: $0.id, status: $0.status, custom: $0.custom?.flatJSON) },
          delete: []
        ),
        filter: nil,
        sort: [],
        limit: 0,
        start: nil,
        end: nil
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: PubNubMembershipsResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { _ in () })
      }
  }

  public func addMemberships(
    spaces: [PubNubMembership.MembershipPartial],
    to userId: String?,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    let computedUserId = userId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

    let router = ObjectsMembershipsRouter(
      .setMemberships(
        uuidMetadataId: computedUserId,
        customFields: nil,
        totalCount: false,
        changes: .init(
          set: spaces.map { .init(metadataId: $0.id, status: $0.status, custom: $0.custom?.flatJSON) },
          delete: []
        ),
        filter: nil,
        sort: [],
        limit: 0,
        start: nil,
        end: nil
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: PubNubMembershipsResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { _ in () })
      }
  }

  public func updateMemberships(
    users: [PubNubMembership.MembershipPartial],
    on spaceId: String,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    addMemberships(
      users: users,
      to: spaceId,
      custom: requestConfig,
      completion: completion
    )
  }

  public func updateMemberships(
    spaces: [PubNubMembership.MembershipPartial],
    on userId: String?,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    addMemberships(
      spaces: spaces,
      to: userId,
      custom: requestConfig,
      completion: completion
    )
  }

  public func removeMemberships(
    userIds: [String],
    from spaceId: String,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    let router = ObjectsMembershipsRouter(
      .setMembers(
        channelMetadataId: spaceId,
        customFields: nil,
        totalCount: false,
        changes: .init(
          set: [],
          delete: userIds.map { .init(metadataId: $0, status: nil, custom: nil) }
        ),
        filter: nil,
        sort: [],
        limit: 0,
        start: nil,
        end: nil
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: PubNubMembershipsResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { _ in () })
      }
  }

  public func removeMemberships(
    spaceIds: [String],
    from userId: String?,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    let computedUserId = userId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

    let router = ObjectsMembershipsRouter(
      .setMemberships(
        uuidMetadataId: computedUserId,
        customFields: nil,
        totalCount: false,
        changes: .init(
          set: [],
          delete: spaceIds.map { .init(metadataId: $0, status: nil, custom: nil) }
        ),
        filter: nil,
        sort: [],
        limit: 0,
        start: nil,
        end: nil
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: PubNubMembershipsResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { _ in () })
      }
  }
}

// MARK: - Models

public struct PubNubMembership {
  public typealias MembershipPartial = (id: String, status: String?, custom: FlatJSONCodable?)

  /// The associated User Entity
  public var user: PubNubUser
  /// The associated Space Entity
  public var space: PubNubSpace

  /// The current state of the Membership
  public var status: String?

  /// All custom fields set on the Membership
  public var custom: FlatJSONCodable?

  /// The last updated timestamp for the Membership
  public var updated: Date?
  /// The caching identifier for the Membership
  public var eTag: String?

  public init(
    user: PubNubUser,
    space: PubNubSpace,
    status: String? = nil,
    custom: FlatJSONCodable? = nil,
    updated: Date? = nil,
    eTag: String? = nil
  ) {
    self.user = user
    self.space = space
    self.status = status
    self.custom = custom
    self.updated = updated
    self.eTag = eTag
  }
}

public extension PubNubMembershipMetadata {
  func convert() -> PubNubMembership {
    return PubNubMembership(
      user: uuid?.convert() ?? PubNubUser(id: uuidMetadataId),
      space: channel?.convert() ?? PubNubSpace(id: channelMetadataId),
      status: status,
      custom: FlatJSON(flatJSON: custom),
      updated: updated,
      eTag: eTag
    )
  }
  // swiftlint:disable:next file_length
}
