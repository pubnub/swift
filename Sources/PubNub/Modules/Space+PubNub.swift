//
//  Space+PubNub.swift
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

public protocol PubNubSpaceInterface {
  func fetchSpace(
    spaceId: String,
    includeCustom: Bool,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: @escaping (Result<PubNubSpace, Error>) -> Void
  )

  func fetchSpaces(
    includeCustom: Bool,
    includeTotalCount: Bool,
    filter: String?,
    sort: [PubNub.SpaceSort],
    limit: Int?,
    page: PubNubHashedPage?,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: @escaping ((Result<(spaces: [PubNubSpace], next: PubNubHashedPage?), Error>) -> Void)
  )

  func createSpace(
    spaceId: String,
    name: String?,
    type: String?,
    status: String?,
    description: String?,
    custom: FlatJSONCodable?,
    includeCustom: Bool,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<PubNubSpace, Error>) -> Void)?
  )

  func updateSpace(
    spaceId: String,
    name: String?,
    type: String?,
    status: String?,
    description: String?,
    custom: FlatJSONCodable?,
    includeCustom: Bool,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<PubNubSpace, Error>) -> Void)?
  )

  func removeSpace(
    spaceId: String,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  )
}

// MARK: - Request Objects

public extension PubNub {
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

extension PubNubSpaceModule: PubNubSpaceInterface {
  public func fetchSpace(
    spaceId: String,
    includeCustom: Bool = true,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: @escaping (Result<PubNubSpace, Error>) -> Void
  ) {
    let router = ObjectsChannelRouter(
      .fetch(metadataId: spaceId, customFields: includeCustom),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    (requestConfig.customSession ?? networkSession)
      .route(
        router,
        responseDecoder: PubNubChannelMetadataResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion(result.map { $0.payload.data.convert() })
      }
  }

  public func fetchSpaces(
    includeCustom: Bool = true,
    includeTotalCount: Bool = true,
    filter: String? = nil,
    sort: [PubNub.SpaceSort] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = nil,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
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
        responseDecoder: PubNubChannelsMetadataResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion(result.map { (
          spaces: $0.payload.data.map { $0.convert() },
          next: try? PubNubHashedPageBase(from: $0.payload)
        ) })
      }
  }

  public func createSpace(
    spaceId: String,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    description: String? = nil,
    custom: FlatJSONCodable? = nil,
    includeCustom: Bool = true,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
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
        responseDecoder: PubNubChannelMetadataResponseDecoder(),
        responseQueue: requestConfig.responseQueue
      ) { result in
        completion?(result.map { $0.payload.data.convert() })
      }
  }

  public func updateSpace(
    spaceId: String,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    description: String? = nil,
    custom: FlatJSONCodable? = nil,
    includeCustom: Bool = true,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
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
      custom: requestConfig,
      completion: completion
    )
  }

  public func removeSpace(
    spaceId: String,
    custom requestConfig: PubNub.RequestConfiguration = .init(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .remove(metadataId: spaceId),
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

public struct PubNubSpace {
  /// The unique identifier of the Space
  public var id: String
  /// The name of the Space
  public var name: String?
  /// The classification of Space
  public var type: String?
  /// The current state of the Space
  public var status: String?
  /// Text describing the purpose of the Space
  public var spaceDescription: String?

  /// All custom fields set on the Space
  public var custom: FlatJSONCodable?

  /// The last updated timestamp for the Space
  public var updated: Date?
  /// The caching identifier for the Space
  public var eTag: String?

  public init(
    id: String,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    spaceDescription: String? = nil,
    custom: FlatJSONCodable? = nil,
    updated: Date? = nil,
    eTag: String? = nil
  ) {
    self.id = id
    self.name = name
    self.type = type
    self.status = status
    self.spaceDescription = spaceDescription
    self.custom = custom
    self.updated = updated
    self.eTag = eTag
  }
}

public extension PubNubChannelMetadata {
  func convert() -> PubNubSpace {
    return PubNubSpace(
      id: metadataId,
      name: name,
      type: type,
      status: status,
      spaceDescription: channelDescription,
      custom: FlatJSON(flatJSON: custom),
      updated: updated,
      eTag: eTag
    )
  }
}
