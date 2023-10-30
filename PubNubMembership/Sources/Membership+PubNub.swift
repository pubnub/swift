//
//  Membership+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

import PubNub
import PubNubSpace
import PubNubUser

/// Protocol interface to manage `PubNubMembership` entities using closures
public protocol PubNubMembershipInterface {
  /// A copy of the configuration object used for this session
  var configuration: PubNubConfiguration { get }

  /// Session used for performing request/response REST calls
  var networkSession: SessionReplaceable { get }

  /// Fetch all `PubNubMembership` linked to a specific `PubNubUser.id`
  ///
  /// - Parameters:
  ///   - userId: Unique identifier for the `PubNubUser`. If not supplied, then it will use the request configuration and then the default configuration
  ///   - includeCustom: Should the `PubNubMembership.custom` properties be included in the response
  ///   - includeSpaceFields: Should the `PubNubSpace` properties be included in the response
  ///   - includeSpaceCustomFields: Should the `PubNubSpace.custom` properties be included in the response
  ///   - includeTotalCount: Should the next page include total amount of Space to fetch accessed via `next.totalCount`
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: Async `Result` of the method call
  ///     - **Success**: `Tuple` containing an `Array` of `PubNubMembership`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: `Error` describing the failure
  func fetchMemberships(
    userId: String?,
    includeCustom: Bool,
    includeSpaceFields: Bool,
    includeSpaceCustomFields: Bool,
    includeTotalCount: Bool,
    filter: String?,
    sort: [PubNub.SpaceMembershipSort],
    limit: Int?,
    page: PubNubHashedPage?,
    requestConfig: PubNub.RequestConfiguration,
    completion: @escaping ((Result<(memberships: [PubNubMembership], next: PubNubHashedPage?), Error>) -> Void)
  )

  /// Fetch all `PubNubMembership` linked to a specific `PubNubSpace.id`
  ///
  /// - Parameters:
  ///   - spaceId: Unique identifier for the `PubNubSpace`.
  ///   - includeCustom: Should the `PubNubMembership.custom` properties be included in the response
  ///   - includeUserFields: Should the `PubNubUser` properties be included in the response
  ///   - includeUserCustomFields: Should the `PubNubUser.custom` properties be included in the response
  ///   - includeTotalCount: Should the next page include total amount of Space to fetch accessed via `next.totalCount`
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: Async `Result` of the method call
  ///     - **Success**: `Tuple` containing an `Array` of `PubNubMembership`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: `Error` describing the failure
  func fetchMemberships(
    spaceId: String,
    includeCustom: Bool,
    includeUserFields: Bool,
    includeUserCustomFields: Bool,
    includeTotalCount: Bool,
    filter: String?,
    sort: [PubNub.UserMembershipSort],
    limit: Int?,
    page: PubNubHashedPage?,
    requestConfig: PubNub.RequestConfiguration,
    completion: @escaping ((Result<(memberships: [PubNubMembership], next: PubNubHashedPage?), Error>) -> Void)
  )

  /// Add a `PubNubMembership` relationship between a `PubNubSpace` and one or more `PubNubUser`
  ///
  /// - Parameters:
  ///   - users: List of `PubNubUser`that will be associated with the `PubNubSpace`
  ///   - spaceId: Unique identifier for the `PubNubSpace`
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: Async `Result` of the method call
  ///     - **Success**: Acknowledgement that the request was successful
  ///     - **Failure**: `Error` describing the failure
  func addMemberships(
    users: [PubNubMembership.PartialUser],
    to spaceId: String,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )

  /// Add a `PubNubMembership` relationship between a `PubNubUser` and one or more `PubNubSpace`
  ///
  /// - Parameters:
  ///   - spaces: List of `PubNubSpace`that will be associated with the `PubNubUser`
  ///   - userId: Unique identifier for the `PubNubUser`. If not supplied, then it will use the request configuration and then the default configuration
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: Async `Result` of the method call
  ///     - **Success**: Acknowledgement that the request was successful
  ///     - **Failure**: `Error` describing the failure
  func addMemberships(
    spaces: [PubNubMembership.PartialSpace],
    to userId: String?,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )

  /// Updates a `PubNubMembership` relationship between a `PubNubSpace` and one or more `PubNubUser`
  ///
  /// - Parameters:
  ///   - users: List of `PubNubUser`that will be associated with the `PubNubSpace`
  ///   - spaceId: Unique identifier for the `PubNubSpace`
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: Async `Result` of the method call
  ///     - **Success**: Acknowledgement that the request was successful
  ///     - **Failure**: `Error` describing the failure
  func updateMemberships(
    users: [PubNubMembership.PartialUser],
    on spaceId: String,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )

  /// Updates a `PubNubMembership` relationship between a `PubNubUser` and one or more `PubNubSpace`
  ///
  /// - Parameters:
  ///   - spaces: List of `PubNubSpace`that will be associated with the `PubNubUser`
  ///   - userId: Unique identifier for the `PubNubUser`. If not supplied, then it will use the request configuration and then the default configuration
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: Async `Result` of the method call
  ///     - **Success**: Acknowledgement that the request was successful
  ///     - **Failure**: `Error` describing the failure
  func updateMemberships(
    spaces: [PubNubMembership.PartialSpace],
    on userId: String?,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )

  /// Removes the `PubNubMembership` relationship between a `PubNubSpace` and one or more `PubNubUser`
  ///
  /// - Parameters:
  ///   - userIds: List of `PubNubUser.id``String` values that will be separated from the `PubNubSpace`
  ///   - userId: Unique identifier for the `PubNubSpace`
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: Async `Result` of the method call
  ///     - **Success**: Acknowledgement that the request was successful
  ///     - **Failure**: `Error` describing the failure
  func removeMemberships(
    userIds: [String],
    from spaceId: String,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )

  /// Removes the `PubNubMembership` relationship between a `PubNubUser` and one or more `PubNubSpace`
  ///
  /// - Parameters:
  ///   - spaceIds: List of `PubNubSpace.id``String` values that will be separated from the `PubNubUser`
  ///   - userId: Unique identifier for the `PubNubUser`. If not supplied, then it will use the request configuration and then the default configuration
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: Async `Result` of the method call
  ///     - **Success**: Acknowledgement that the request was successful
  ///     - **Failure**: `Error` describing the failure
  func removeMemberships(
    spaceIds: [String],
    from userId: String?,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )
}

// MARK: - Request Objects

public extension PubNub {
  /// All available fileds that can be sorted on for a `PubNubMembership` using a `PubNubSpace`
  enum UserMembershipSort: Hashable {
    /// Sort on the status property
    case status(ascending: Bool)
    /// Sort on the last updated property
    case updated(ascending: Bool)
    /// Sort on the `PubNubUser` properties
    case user(UserSort)

    /// The finalized query parameter value for the sort field
    var routerParameter: String {
      switch self {
      case let .status(ascending: ascending):
        return "status\(ascending ? "" : ":desc")"
      case let .updated(ascending: ascending):
        return "updated\(ascending ? "" : ":desc")"
      case let .user(nested):
        return "uuid.\(nested.rawValue)\(nested.ascending ? "" : ":desc")"
      }
    }
  }

  /// All available fileds that can be sorted on for a `PubNubMembership` using a `PubNubUser`
  enum SpaceMembershipSort: Hashable {
    /// Sort on the status property
    case status(ascending: Bool)
    /// Sort on the last updated property
    case updated(ascending: Bool)
    /// Sort on the `PubNubSpace` properties
    case space(SpaceSort)

    /// The finalized query parameter value for the sort field
    var routerParameter: String {
      switch self {
      case let .status(ascending: ascending):
        return "status\(ascending ? "" : ":desc")"
      case let .updated(ascending: ascending):
        return "updated\(ascending ? "" : ":desc")"
      case let .space(nested):
        return "channel.\(nested.rawValue)\(nested.ascending ? "" : ":desc")"
      }
    }
  }
}

// MARK: - Module Impl.

extension PubNub: PubNubMembershipInterface {}

public extension PubNubMembershipInterface {
  func fetchMemberships(
    userId: String? = nil,
    includeCustom: Bool = true,
    includeSpaceFields: Bool = false,
    includeSpaceCustomFields: Bool = false,
    includeTotalCount: Bool = false,
    filter: String? = nil,
    sort: [PubNub.SpaceMembershipSort] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = nil,
    requestConfig: PubNub.RequestConfiguration = .init(),
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
        responseDecoder: FetchMultipleValueResponseDecoder<PubNubMembership.PartialSpace>(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion(result.map { response in
          (
            memberships: response.payload.data.compactMap {
              PubNubMembership(user: .init(id: computedUserId), space: $0)
            },
            next: PubNub.Page(
              next: response.payload.next,
              prev: response.payload.prev,
              totalCount: response.payload.totalCount
            )
          )
        })
      }
  }

  func fetchMemberships(
    spaceId: String,
    includeCustom: Bool = true,
    includeUserFields: Bool = false,
    includeUserCustomFields: Bool = false,
    includeTotalCount: Bool = false,
    filter: String? = nil,
    sort: [PubNub.UserMembershipSort] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = nil,
    requestConfig: PubNub.RequestConfiguration = .init(),
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
        responseDecoder: FetchMultipleValueResponseDecoder<PubNubMembership.PartialUser>(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion(result.map { response in
          (
            memberships: response.payload.data.compactMap {
              PubNubMembership(space: .init(id: spaceId), user: $0)
            },
            next: PubNub.Page(
              next: response.payload.next,
              prev: response.payload.prev,
              totalCount: response.payload.totalCount
            )
          )
        })
      }
  }

  func addMemberships(
    users: [PubNubMembership.PartialUser],
    to spaceId: String,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    let router = ObjectsMembershipsRouter(
      .setMembers(
        channelMetadataId: spaceId,
        customFields: nil,
        totalCount: false,
        changes: .init(
          set: users.map { .init(metadataId: $0.user.id, status: $0.status, custom: $0.custom?.flatJSON) },
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
        responseDecoder: FetchStatusResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { _ in () })
      }
  }

  func addMemberships(
    spaces: [PubNubMembership.PartialSpace],
    to userId: String? = nil,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    let computedUserId = userId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

    let router = ObjectsMembershipsRouter(
      .setMemberships(
        uuidMetadataId: computedUserId,
        customFields: nil,
        totalCount: false,
        changes: .init(
          set: spaces.map { .init(metadataId: $0.space.id, status: $0.status, custom: $0.custom?.flatJSON) },
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
        responseDecoder: FetchStatusResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { _ in () })
      }
  }

  func updateMemberships(
    users: [PubNubMembership.PartialUser],
    on spaceId: String,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    addMemberships(
      users: users,
      to: spaceId,
      requestConfig: requestConfig,
      completion: completion
    )
  }

  func updateMemberships(
    spaces: [PubNubMembership.PartialSpace],
    on userId: String? = nil,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    addMemberships(
      spaces: spaces,
      to: userId,
      requestConfig: requestConfig,
      completion: completion
    )
  }

  func removeMemberships(
    userIds: [String],
    from spaceId: String,
    requestConfig: PubNub.RequestConfiguration = .init(),
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
        responseDecoder: FetchStatusResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { _ in () })
      }
  }

  func removeMemberships(
    spaceIds: [String],
    from userId: String? = nil,
    requestConfig: PubNub.RequestConfiguration = .init(),
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
        responseDecoder: FetchStatusResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { _ in () })
      }
  }
  // swiftlint:disable:next file_length
}
