//
//  User+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

import PubNub

/// Protocol interface to manage `PubNubUser` entities using closures
public protocol PubNubUserInterface {
  /// A copy of the configuration object used for this session
  var configuration: PubNubConfiguration { get }

  /// Session used for performing request/response REST calls
  var networkSession: SessionReplaceable { get }

  /// Fetch all `PubNubUser` that exist on a keyset
  ///
  /// - Parameters:
  ///   - includeCustom: Should the `PubNubUser.custom` properties be included in the response
  ///   - includeTotalCount: Should the next page include total amount of Users to fetch accessed via `next.totalCount`
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: `Tuple` containing an `Array` of `PubNubUser`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func fetchUsers(
    includeCustom: Bool,
    includeTotalCount: Bool,
    filter: String?,
    sort: [PubNub.UserSort],
    limit: Int?,
    page: PubNubHashedPage?,
    requestConfig: PubNub.RequestConfiguration,
    completion: @escaping ((Result<(users: [PubNubUser], next: PubNubHashedPage?), Error>) -> Void)
  )

  /// Fetch a `PubNubUser` using its unique identifier
  ///
  /// - Parameters:
  ///   - userId: Unique identifier for the `PubNubUser`. If not supplied, then it will use the request configuration and then the default configuration
  ///   - includeCustom: Should the `PubNubUser.custom` properties be included in the response
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: `PubNubUser` object belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  func fetchUser(
    userId: String?,
    includeCustom: Bool,
    requestConfig: PubNub.RequestConfiguration,
    completion: @escaping (Result<PubNubUser, Error>) -> Void
  )

  /// Create a new `PubNubUser`
  ///
  /// - Parameters:
  ///   - userId: Unique identifier for the `PubNubUser`. If not supplied, then it will use the request configuration and then the default configuration
  ///   - name: The name of the User
  ///   - type: The classification of User
  ///   - status: The current state of the User
  ///   - externalId: The external identifier for the User
  ///   - profileUrl: The profile URL for the User
  ///   - email: The email address of the User
  ///   - custom: All custom properties set on the User
  ///   - includeCustom: Should the `PubNubUser.custom` properties be included in the response
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: `PubNubUser` that was created
  ///     - **Failure**: An `Error` describing the failure
  func createUser(
    userId: String?,
    name: String?,
    type: String?,
    status: String?,
    externalId: String?,
    profileUrl: URL?,
    email: String?,
    custom: FlatJSONCodable?,
    includeCustom: Bool,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<PubNubUser, Error>) -> Void)?
  )

  /// Updates an existing `PubNubUser`
  ///
  /// - Parameters:
  ///   - userId: Unique identifier for the `PubNubUser`. If not supplied, then it will use the request configuration and then the default configuration
  ///   - name: The name of the User
  ///   - type: The classification of User
  ///   - status: The current state of the User
  ///   - externalId: The external identifier for the User
  ///   - profileUrl: The profile URL for the User
  ///   - email: The email address of the User
  ///   - custom: All custom properties set on the User
  ///   - includeCustom: Should the `PubNubUser.custom` properties be included in the response
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: `PubNubUser` containing the updated changes
  ///     - **Failure**: An `Error` describing the failure
  func updateUser(
    userId: String?,
    name: String?,
    type: String?,
    status: String?,
    externalId: String?,
    profileUrl: URL?,
    email: String?,
    custom: FlatJSONCodable?,
    includeCustom: Bool,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<PubNubUser, Error>) -> Void)?
  )

  /// Removes a previously created `PubNubUser` (if it existed)
  ///
  /// - Parameters:
  ///   - userId: Unique identifier for the `PubNubUser`. If not supplied, then it will use the request configuration and then the default configuration
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: Acknowledgement that the removal was successful
  ///     - **Failure**: An `Error` describing the failure
  func removeUser(
    userId: String?,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )
}

// MARK: - Request Objects

public extension PubNub {
  /// All available fileds that can be sorted on for a `PubNubUser`
  enum UserSort: Hashable {
    /// Sort on the unique identifier property
    case id(ascending: Bool)
    /// Sort on the name property
    case name(ascending: Bool)
    /// Sort on the type property
    case type(ascending: Bool)
    /// Sort on the status property
    case status(ascending: Bool)
    /// Sort on the last updated property
    case updated(ascending: Bool)

    /// The string representation of the field
    public var rawValue: String {
      switch self {
      case .id:
        return "id"
      case .name:
        return "name"
      case .type:
        return "type"
      case .status:
        return "status"
      case .updated:
        return "updated"
      }
    }

    /// Direction of the sort for the sort field
    public var ascending: Bool {
      switch self {
      case let .id(ascending):
        return ascending
      case let .name(ascending):
        return ascending
      case let .type(ascending):
        return ascending
      case let .status(ascending):
        return ascending
      case let .updated(ascending):
        return ascending
      }
    }

    /// The finalized query parameter value for the sort field
    public var routerParameter: String {
      return "\(rawValue)\(ascending ? "" : ":desc")"
    }
  }
}

// MARK: - Module Impl.

extension PubNub: PubNubUserInterface {}

public extension PubNubUserInterface {
  func fetchUsers(
    includeCustom: Bool = true,
    includeTotalCount: Bool = true,
    filter: String? = nil,
    sort: [PubNub.UserSort] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = nil,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: @escaping ((Result<(users: [PubNubUser], next: PubNubHashedPage?), Error>) -> Void)
  ) {
    let router = ObjectsUUIDRouter(
      .all(
        customFields: includeCustom,
        totalCount: includeTotalCount,
        filter: filter,
        sort: sort.map { $0.routerParameter },
        limit: limit,
        start: page?.start,
        end: page?.end
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)?
      .route(
        router,
        responseDecoder: FetchMultipleValueResponseDecoder<PubNubUser>(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion(result.map { (
          users: $0.payload.data,
          next: PubNub.Page(next: $0.payload.next, prev: $0.payload.prev, totalCount: $0.payload.totalCount)
        ) })
      }
  }

  func fetchUser(
    userId: String? = nil,
    includeCustom: Bool = true,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: @escaping (Result<PubNubUser, Error>) -> Void
  ) {
    let router = ObjectsUUIDRouter(
      .fetch(
        metadataId: userId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid),
        customFields: includeCustom
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: FetchSingleValueResponseDecoder<PubNubUser>(),
        responseQueue: requestConfig.responseQueue
      ) {
        completion($0.map { $0.payload.data })
      }
  }

  func createUser(
    userId: String? = nil,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    externalId: String? = nil,
    profileUrl: URL? = nil,
    email: String? = nil,
    custom: FlatJSONCodable? = nil,
    includeCustom: Bool = true,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<PubNubUser, Error>) -> Void)?
  ) {
    let router = ObjectsUUIDRouter(
      .set(
        metadata: PubNubUUIDMetadataBase(
          metadataId: userId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid),
          name: name,
          type: type,
          status: status,
          externalId: externalId,
          profileURL: profileUrl?.absoluteString,
          email: email,
          custom: custom?.flatJSON
        ),
        customFields: includeCustom
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: FetchSingleValueResponseDecoder<PubNubUser>(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { $0.payload.data })
      }
  }

  func updateUser(
    userId: String? = nil,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    externalId: String? = nil,
    profileUrl: URL? = nil,
    email: String? = nil,
    custom: FlatJSONCodable? = nil,
    includeCustom: Bool = true,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<PubNubUser, Error>) -> Void)?
  ) {
    createUser(
      userId: userId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid),
      name: name,
      type: type,
      status: status,
      externalId: externalId,
      profileUrl: profileUrl,
      email: email,
      custom: custom,
      includeCustom: includeCustom,
      requestConfig: requestConfig,
      completion: completion
    )
  }

  func removeUser(
    userId: String? = nil,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    let router = ObjectsUUIDRouter(
      .remove(metadataId: userId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)),
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
}
