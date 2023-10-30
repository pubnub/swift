//
//  Space+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

import PubNub

/// Protocol interface to manage `PubNubSpace` entities using closures
public protocol PubNubSpaceInterface {
  /// A copy of the configuration object used for this session
  var configuration: PubNubConfiguration { get }

  /// Session used for performing request/response REST calls
  var networkSession: SessionReplaceable { get }

  /// Fetch all `PubNubSpace` that exist on a keyset
  ///
  /// - Parameters:
  ///   - includeCustom: Should the `PubNubSpace.custom` properties be included in the response
  ///   - includeTotalCount: Should the next page include total amount of Space to fetch accessed via `next.totalCount`
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: Async `Result` of the method call
  ///     - **Success**: `Tuple` containing an `Array` of `PubNubSpace`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: `Error` describing the failure
  func fetchSpaces(
    includeCustom: Bool,
    includeTotalCount: Bool,
    filter: String?,
    sort: [PubNub.SpaceSort],
    limit: Int?,
    page: PubNubHashedPage?,
    requestConfig: PubNub.RequestConfiguration,
    completion: @escaping ((Result<(spaces: [PubNubSpace], next: PubNubHashedPage?), Error>) -> Void)
  )

  /// Fetch a `PubNubSpace` using its unique identifier
  ///
  /// - Parameters:
  ///   - spaceId: Unique identifier for the `PubNubSpace`.
  ///   - includeCustom: Should the `PubNubSpace.custom` properties be included in the response
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: `PubNubSpace` object belonging to the identifier
  ///     - **Failure**: `Error` describing the failure
  func fetchSpace(
    spaceId: String,
    includeCustom: Bool,
    requestConfig: PubNub.RequestConfiguration,
    completion: @escaping (Result<PubNubSpace, Error>) -> Void
  )

  /// Create a new `PubNubSpace`
  ///
  /// - Parameters:
  ///   - spaceId: Unique identifier for the `PubNubSpace`.
  ///   - name: The name of the Space
  ///   - type: The classification of Space
  ///   - status: The current state of the Space
  ///   - description: Text describing the purpose of the Space
  ///   - custom: All custom properties set on the Space
  ///   - includeCustom: Should the `PubNubSpace.custom` properties be included in the response
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: Async `Result` of the method call
  ///     - **Success**: `PubNubSpace` that was created
  ///     - **Failure**: `Error` describing the failure
  func createSpace(
    spaceId: String,
    name: String?,
    type: String?,
    status: String?,
    description: String?,
    custom: FlatJSONCodable?,
    includeCustom: Bool,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<PubNubSpace, Error>) -> Void)?
  )

  /// Updates an existing`PubNubSpace`
  ///
  /// - Parameters:
  ///   - spaceId: Unique identifier for the `PubNubSpace`.
  ///   - name: The name of the Space
  ///   - type: The classification of Space
  ///   - status: The current state of the Space
  ///   - description: Text describing the purpose of the Space
  ///   - custom: All custom properties set on the Space
  ///   - includeCustom: Should the `PubNubSpace.custom` properties be included in the response
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: Async`Result` of the method call
  ///     - **Success**: `PubNubSpace` containing the updated changes
  ///     - **Failure**: `Error` describing the failure
  func updateSpace(
    spaceId: String,
    name: String?,
    type: String?,
    status: String?,
    description: String?,
    custom: FlatJSONCodable?,
    includeCustom: Bool,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<PubNubSpace, Error>) -> Void)?
  )

  /// Removes a previously created `PubNubSpace` (if it existed)
  ///
  /// - Parameters:
  ///   - spaceId: Unique identifier for the `PubNubSpace`
  ///   - requestConfig: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: Acknowledgement that the removal was successful
  ///     - **Failure**: An `Error` describing the failure
  func removeSpace(
    spaceId: String,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )
}

// MARK: - Request Objects

public extension PubNub {
  /// All available fileds that can be sorted on for a `PubNubSpace`
  enum SpaceSort: Hashable {
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

extension PubNub: PubNubSpaceInterface {}

public extension PubNubSpaceInterface {
  func fetchSpaces(
    includeCustom: Bool = true,
    includeTotalCount: Bool = true,
    filter: String? = nil,
    sort: [PubNub.SpaceSort] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = nil,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: @escaping ((Result<(spaces: [PubNubSpace], next: PubNubHashedPage?), Error>) -> Void)
  ) {
    let router = ObjectsChannelRouter(
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

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: FetchMultipleValueResponseDecoder<PubNubSpace>(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion(result.map { (
          spaces: $0.payload.data,
          next: PubNub.Page(next: $0.payload.next, prev: $0.payload.prev, totalCount: $0.payload.totalCount)
        ) })
      }
  }

  func fetchSpace(
    spaceId: String,
    includeCustom: Bool = true,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: @escaping (Result<PubNubSpace, Error>) -> Void
  ) {
    let router = ObjectsChannelRouter(
      .fetch(metadataId: spaceId, customFields: includeCustom),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: FetchSingleValueResponseDecoder<PubNubSpace>(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion(result.map { $0.payload.data })
      }
  }

  func createSpace(
    spaceId: String,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    description: String? = nil,
    custom: FlatJSONCodable? = nil,
    includeCustom: Bool = true,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<PubNubSpace, Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .set(
        metadata: PubNubChannelMetadataBase(
          metadataId: spaceId,
          name: name,
          type: type,
          status: status,
          channelDescription: description,
          custom: custom?.flatJSON
        ),
        customFields: includeCustom
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: FetchSingleValueResponseDecoder<PubNubSpace>(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { $0.payload.data })
      }
  }

  func updateSpace(
    spaceId: String,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    description: String? = nil,
    custom: FlatJSONCodable? = nil,
    includeCustom: Bool = true,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<PubNubSpace, Error>) -> Void)?
  ) {
    createSpace(
      spaceId: spaceId,
      name: name,
      type: type,
      status: status,
      description: description,
      custom: custom,
      includeCustom: includeCustom,
      requestConfig: requestConfig,
      completion: completion
    )
  }

  func removeSpace(
    spaceId: String,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .remove(metadataId: spaceId),
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
