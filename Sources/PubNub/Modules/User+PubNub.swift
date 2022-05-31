//
//  User+PubNub.swift
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

public protocol PubNubUserInterface {
  static var moduleIdentifier: String { get }

  func fetchUser(
    userId: String?,
    includeCustom: Bool,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: @escaping (Result<PubNubUser, Error>) -> Void
  )

  func fetchUsers(
    includeCustom: Bool,
    includeTotalCount: Bool,
    filter: String?,
    sort: [PubNub.UserSort],
    limit: Int?,
    page: PubNubHashedPage?,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: @escaping ((Result<(users: [PubNubUser], next: PubNubHashedPage?), Error>) -> Void)
  )

  func createUser(
    userId: String,
    name: String?,
    type: String?,
    status: String?,
    externalId: String?,
    profileUrl: URL?,
    email: String?,
    custom: FlatJSONCodable?,
    includeCustom: Bool,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<PubNubUser, Error>) -> Void)?
  )
  func updateUser(
    userId: String,
    name: String?,
    type: String?,
    status: String?,
    externalId: String?,
    profileUrl: URL?,
    email: String?,
    custom: FlatJSONCodable?,
    includeCustom: Bool,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<PubNubUser, Error>) -> Void)?
  )
  func removeUser(
    userId: String?,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )
}

// MARK: - Request Objects

public extension PubNub {
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

    public var routerParameter: String {
      return "\(rawValue):\(ascending ? "" : "desc")"
    }
  }
}

// MARK: - Module Impl.

extension PubNubUserModule: PubNubUserInterface {
  public func fetchUser(
    userId: String?,
    includeCustom: Bool = true,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
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
        responseDecoder: PubNubUUIDMetadataResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) {
        completion($0.map { $0.payload.data.convert() })
      }
  }

  public func fetchUsers(
    includeCustom: Bool = true,
    includeTotalCount: Bool = true,
    filter: String? = nil,
    sort: [PubNub.UserSort] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = nil,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
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

    (requestConfig.customSession ?? pubnub?.networkSession)?
      .route(
        router,
        responseDecoder: PubNubUUIDsMetadataResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion(result.map { (
          users: $0.payload.data.map { $0.convert() },
          next: try? PubNubHashedPageBase(from: $0.payload)
        ) })
      }
  }

  public func createUser(
    userId: String,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    externalId: String? = nil,
    profileUrl: URL? = nil,
    email: String? = nil,
    custom: FlatJSONCodable? = nil,
    includeCustom: Bool = true,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<PubNubUser, Error>) -> Void)?
  ) {
    let router = ObjectsUUIDRouter(
      .set(
        metadata: PubNubUUIDMetadataBase(
          metadataId: userId,
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
        responseDecoder: PubNubUUIDMetadataResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { $0.payload.data.convert() })
      }
  }

  public func updateUser(
    userId: String,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    externalId: String? = nil,
    profileUrl: URL? = nil,
    email: String? = nil,
    custom: FlatJSONCodable? = nil,
    includeCustom: Bool = true,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<PubNubUser, Error>) -> Void)?
  ) {
    createUser(
      userId: userId,
      name: name,
      type: type,
      status: status,
      externalId: externalId,
      profileUrl: profileUrl,
      email: email,
      custom: custom,
      includeCustom: includeCustom,
      custom: requestConfig,
      completion: completion
    )
  }

  public func removeUser(
    userId: String?,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    let router = ObjectsUUIDRouter(
      .remove(metadataId: userId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: GenericServiceResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { _ in () })
      }
  }
}

// MARK: - Models

// Defined in PubNub
public struct PubNubUser {
  /// The unique identifier of the User
  public var id: String
  /// The name of the User
  public var name: String?
  /// The classification of User
  public var type: String?
  /// The current state of the User
  public var status: String?
  /// The external identifier for the User
  public var externalId: String?
  /// The profile URL for the User
  public var profileURL: URL?
  /// The email address of the User
  public var email: String?

  /// All custom fields set on the User
  public var custom: FlatJSONCodable?

  /// The last updated timestamp for the User
  public var updated: Date?
  /// The caching identifier for the User
  public var eTag: String?

  public init(
    id: String,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    externalId: String? = nil,
    profileURL: URL? = nil,
    email: String? = nil,
    custom: FlatJSONCodable? = nil,
    updated: Date? = nil,
    eTag: String? = nil
  ) {
    self.id = id
    self.name = name
    self.type = type
    self.status = status
    self.externalId = externalId
    self.profileURL = profileURL
    self.email = email
    self.custom = custom
    self.updated = updated
    self.eTag = eTag
  }
}

public extension PubNubUUIDMetadata {
  func convert() -> PubNubUser {
    return PubNubUser(
      id: metadataId,
      name: name,
      type: type,
      status: status,
      externalId: externalId,
      profileURL: URL(string: profileURL ?? ""),
      email: email,
      custom: FlatJSON(flatJSON: custom),
      updated: updated,
      eTag: eTag
    )
  }
}
