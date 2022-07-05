//
//  Objects+PubNub.swift
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

public extension PubNub {
  /// The sort properties for Membership metadata objects
  enum MembershipSortProperty: Hashable {
    /// Sort based on the nested object (UUID or Channel) belonging to the Membership
    case object(ObjectSortProperty)

    case status
    /// Sort on the last updated property of the Membership
    case updated

    func rawValue(_ objectType: String) -> String {
      switch self {
      case let .object(property):
        return "\(objectType).\(property)"
      case .status:
        return "status"
      case .updated:
        return "updated"
      }
    }

    var membershipRawValue: String {
      return rawValue("channel")
    }

    var memberRawValue: String {
      return rawValue("uuid")
    }
  }

  /// The property and direction to sort a multi-membership-metadata response
  struct MembershipSortField: Hashable {
    /// The property to sort by
    public let property: MembershipSortProperty
    /// The direction of the sort
    public let ascending: Bool

    public init(property: MembershipSortProperty, ascending: Bool = true) {
      self.property = property
      self.ascending = ascending
    }
  }

  /// Fields that include additional data inside a Membership metadata response
  struct MembershipInclude: Hashable {
    /// The `custom` dictionary for the Object
    public var customFields: Bool
    /// The `PubNubChannelMetadata` instance of the Membership
    public var channelFields: Bool
    /// The `custom` dictionary of the `PubNubChannelMetadata` for the Membership object
    public var channelCustomFields: Bool
    /// The `totalCount` of how many Objects are available
    public var totalCount: Bool

    /// Default init
    /// - Parameters:
    ///   - customFields: The `custom` dictionary for the Object
    ///   - channelFields: The `PubNubChannelMetadata` instance of the Membership
    ///   - channelCustomFields: The `custom` dictionary of the `PubNubChannelMetadata` for the Membership object
    ///   - totalCount: The `totalCount` of how many Objects are available
    public init(
      customFields: Bool = true,
      channelFields: Bool = false,
      channelCustomFields: Bool = false,
      totalCount: Bool = false
    ) {
      self.customFields = customFields
      self.channelFields = channelFields
      self.channelCustomFields = channelCustomFields
      self.totalCount = totalCount
    }

    var customIncludes: [ObjectsMembershipsRouter.Include]? {
      var includes = [ObjectsMembershipsRouter.Include]()

      if customFields { includes.append(.custom) }
      if channelFields { includes.append(.channel) }
      if channelCustomFields { includes.append(.channelCustom) }

      return includes.isEmpty ? nil : includes
    }
  }

  struct MemberInclude: Hashable {
    /// The `custom` dictionary for the Object
    public var customFields: Bool
    /// The `PubNubUUIDMetadata` instance of the Membership
    public var uuidFields: Bool
    /// The `custom` dictionary of the `PubNubUUIDMetadata` for the Membership object
    public var uuidCustomFields: Bool
    /// The `totalCount` of how many Objects are available
    public var totalCount: Bool

    /// Default init
    /// - Parameters:
    ///   - customFields: The `custom` dictionary for the Object
    ///   - uuidFields: The `PubNubUUIDMetadata` instance of the Membership
    ///   - uuidCustomFields: The `custom` dictionary of the `PubNubUUIDMetadata` for the Membership object
    ///   - totalCount: The `totalCount` of how many Objects are available
    public init(
      customFields: Bool = true,
      uuidFields: Bool = false,
      uuidCustomFields: Bool = false,
      totalCount: Bool = false
    ) {
      self.customFields = customFields
      self.uuidFields = uuidFields
      self.uuidCustomFields = uuidCustomFields
      self.totalCount = totalCount
    }

    var customIncludes: [ObjectsMembershipsRouter.Include]? {
      var includes = [ObjectsMembershipsRouter.Include]()

      if customFields { includes.append(.custom) }
      if uuidFields { includes.append(.uuid) }
      if uuidCustomFields { includes.append(.uuidCustom) }

      return includes.isEmpty ? nil : includes
    }
  }

  /// Fields that include additional data inside the response
  struct IncludeFields: Hashable {
    /// The `custom` dictionary for the Object
    public var customFields: Bool
    /// The `totalCount` of how many Objects are available
    public var totalCount: Bool

    /// Default init
    ///  - Parameters:
    ///   - custom: Whether to include `custom` data in the response
    ///   - totalCount: Whether to include `totalCount` in the response
    public init(custom: Bool = true, totalCount: Bool = true) {
      customFields = custom
      self.totalCount = totalCount
    }
  }

  /// The sort properties for UUID and Channel metadata objects
  enum ObjectSortProperty: String, Hashable {
    /// Sort on the unique identifier property
    case id
    /// Sort on the name property
    case name
    /// Sort on the type property
    case type
    /// Sort on the status property
    case status
    /// Sort on the last updated property
    case updated
  }

  /// The property and direction to sort a multi-object-metadata response
  struct ObjectSortField: Hashable {
    /// The property to sort by
    public let property: ObjectSortProperty
    /// The direction of the sort
    public let ascending: Bool

    public init(property: ObjectSortProperty, ascending: Bool = true) {
      self.property = property
      self.ascending = ascending
    }
  }
}

extension Array where Element == PubNub.ObjectSortField {
  var urlValue: [String] {
    return map { "\($0.property.rawValue)\($0.ascending ? "" : ":desc")" }
  }
}

extension Array where Element == PubNub.MembershipSortField {
  var memberURLValue: [String] {
    return map { "\($0.property.memberRawValue)\($0.ascending ? "" : ":desc")" }
  }

  var membershipURLValue: [String] {
    return map { "\($0.property.membershipRawValue)\($0.ascending ? "" : ":desc")" }
  }
}

// MARK: - UUID Metadat Objects

public extension PubNub {
  /// Gets metadata for all UUIDs
  ///
  /// Returns a paginated list of UUID Metadata objects, optionally including the custom data object for each.
  /// - Parameters:
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubUUIDMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func allUUIDMetadata(
    include: IncludeFields = IncludeFields(),
    filter: String? = nil,
    sort: [ObjectSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(uuids: [PubNubUUIDMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    let router = ObjectsUUIDRouter(
      .all(customFields: include.customFields, totalCount: include.totalCount,
           filter: filter, sort: sort.urlValue,
           limit: limit, start: page?.start, end: page?.end),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: PubNubUUIDsMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { (
        uuids: $0.payload.data,
        next: try? PubNubHashedPageBase(from: $0.payload)
      ) })
    }
  }

  /// Get Metadata for a UUID
  ///
  /// Returns metadata for the specified UUID, optionally including the custom data object for each.
  /// - Parameters:
  ///   - uuid: Unique UUID Metadata identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubUUIDMetadata` object belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  func fetch(
    uuid metadata: String?,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubUUIDMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsUUIDRouter(
      .fetch(metadataId: metadata ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid),
             customFields: customFields),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: PubNubUUIDMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Set UUID Metadata
  ///
  ///  Set metadata for a UUID in the database, optionally including the custom data object for each.
  /// - Parameters:
  ///   - uuid: The `PubNubUUIDMetadata` to set
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubUUIDMetadata` containing the set changes
  ///     - **Failure**: An `Error` describing the failure
  func set(
    uuid metadata: PubNubUUIDMetadata,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubUUIDMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsUUIDRouter(
      .set(metadata: metadata, customFields: customFields),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: PubNubUUIDMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Remove UUID Metadata
  ///
  /// Remove metadata for a specified UUID.
  /// - Parameters:
  ///   - uuid: Unique UUID Metadata identifier to remove. If not supplied, then it will use the request configuration and then the default configuration
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The UUID identifier of the removed object
  ///     - **Failure**: An `Error` describing the failure
  func remove(
    uuid metadataId: String?,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    // Capture the response or current configuration uuid
    let metadataId = metadataId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

    let router = ObjectsUUIDRouter(
      .remove(metadataId: metadataId),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: GenericServiceResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { _ in metadataId })
    }
  }
}

// MARK: - Channel Metadata Objects

public extension PubNub {
  /// Get Metadata for All Channels
  ///
  ///  Returns a paginated list of metadata objects for channels, optionally including custom data objects.
  /// - Parameters:
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubChannelMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func allChannelMetadata(
    include: IncludeFields = IncludeFields(),
    filter: String? = nil,
    sort: [ObjectSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(channels: [PubNubChannelMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .all(customFields: include.customFields, totalCount: include.totalCount,
           filter: filter, sort: sort.map { "\($0.property.rawValue)\($0.ascending ? "" : ":desc")" },
           limit: limit, start: page?.start, end: page?.end),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: PubNubChannelsMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { (
        channels: $0.payload.data,
        next: try? PubNubHashedPageBase(from: $0.payload)
      ) })
    }
  }

  /// Get Metadata for a Channel
  ///
  /// Returns metadata for the specified channel including the channel's custom data.
  /// - Parameters:
  ///   - channel: Unique Channel Metadata identifier
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubChannelMetadata` object belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  func fetch(
    channel metadataId: String,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubChannelMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .fetch(metadataId: metadataId, customFields: customFields),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: PubNubChannelMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Set Channel Metadata
  ///
  /// Set metadata for a channel in the database.
  /// - Parameters:
  ///   - channel: The `PubNubChannelMetadata` to set
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubChannelMetadata` containing the set changes
  ///     - **Failure**: An `Error` describing the failure
  func set(
    channel metadata: PubNubChannelMetadata,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubChannelMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .set(metadata: metadata, customFields: customFields),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: PubNubChannelMetadataResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Remove Channel Metadata
  ///
  /// Remove metadata for a specified channel
  /// - Parameters:
  ///   - channel: Unique Channel Metadata identifier to remove.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The Channel identifier of the removed object
  ///     - **Failure**: An `Error` describing the failure
  func remove(
    channel metadataId: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .remove(metadataId: metadataId),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: GenericServiceResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { _ in metadataId })
    }
  }
}

// MARK: - Memberships

public extension PubNub {
  /// Get Channel Memberships
  ///
  /// The method returns a list of channel memberships for a user. It does not return a user's subscriptions.
  /// - Parameters:
  ///   - uuid: Unique UUID identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func fetchMemberships(
    uuid: String?,
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    let metadataId = uuid ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

    let router = ObjectsMembershipsRouter(
      .fetchMemberships(
        uuidMetadataId: metadataId,
        customFields: include.customIncludes,
        totalCount: include.totalCount, filter: filter,
        sort: sort.membershipURLValue,
        limit: limit, start: page?.start, end: page?.end
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(router,
          responseDecoder: PubNubMembershipsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { response in
        (
          memberships: response.payload.data.compactMap {
            PubNubMembershipMetadataBase(from: $0, other: metadataId)
          },
          next: try? PubNubHashedPageBase(from: response.payload)
        )
      })
    }
  }

  /// Get Channel Members
  ///
  /// The method returns a list of members in a channel. The list will include user metadata for members that have additional metadata stored in the database.
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func fetchMembers(
    channel metadataId: String,
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    let router = ObjectsMembershipsRouter(.fetchMembers(
      channelMetadataId: metadataId, customFields: include.customIncludes,
      totalCount: include.totalCount, filter: filter,
      sort: sort.memberURLValue,
      limit: limit, start: page?.start, end: page?.end
    ),
    configuration: requestConfig.customConfiguration ?? configuration)

    route(router,
          responseDecoder: PubNubMembershipsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { response in
        (
          memberships: response.payload.data.compactMap {
            PubNubMembershipMetadataBase(from: $0, other: metadataId)
          },
          next: try? PubNubHashedPageBase(from: response.payload)
        )
      })
    }
  }

  /// Set Channel memberships for a UUID.
  /// - Parameters:
  ///   - uuid: Unique UUID identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - channels: Array of `PubNubMembershipMetadata` with the `PubNubChannelMetadata` or `channelMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func setMemberships(
    uuid metadataId: String?,
    channels memberships: [PubNubMembershipMetadata],
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    manageMemberships(
      uuid: metadataId, setting: memberships, removing: [],
      include: include, filter: filter, sort: sort, limit: limit, page: page,
      custom: requestConfig, completion: completion
    )
  }

  /// Remove Channel memberships for a UUID.
  /// - Parameters:
  ///   - uuid: Unique UUID identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - channels: Array of `PubNubMembershipMetadata` with the `PubNubChannelMetadata` or `channelMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func removeMemberships(
    uuid metadataId: String?,
    channels memberships: [PubNubMembershipMetadata],
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = nil,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    manageMemberships(
      uuid: metadataId, setting: [], removing: memberships,
      include: include, filter: filter, sort: sort, limit: limit, page: page,
      custom: requestConfig, completion: completion
    )
  }

  /// Modify the Channel membership list for a UUID
  /// - Parameters:
  ///   - uuid: Unique UUID identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - setting: Array of `PubNubMembershipMetadata` with the `PubNubChannelMetadata` or `channelMetadataId` provided
  ///   - removing: Array of `PubNubMembershipMetadata` with the `PubNubChannelMetadata` or `channelMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func manageMemberships(
    uuid: String?,
    setting channelMembershipSets: [PubNubMembershipMetadata],
    removing channelMembershipDeletes: [PubNubMembershipMetadata],
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    let metadataId = uuid ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

    let router = ObjectsMembershipsRouter(.setMemberships(
      uuidMetadataId: metadataId, customFields: include.customIncludes, totalCount: include.totalCount,
      changes: .init(
        set: channelMembershipSets.map {
          .init(metadataId: $0.channelMetadataId, status: $0.status, custom: $0.custom)
        },
        delete: channelMembershipDeletes.map {
          .init(metadataId: $0.channelMetadataId, status: $0.status, custom: $0.custom)
        }
      ),
      filter: filter, sort: sort.membershipURLValue,
      limit: limit, start: page?.start, end: page?.end
    ), configuration: requestConfig.customConfiguration ?? configuration)

    route(router,
          responseDecoder: PubNubMembershipsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { response in
        (
          memberships: response.payload.data.compactMap {
            PubNubMembershipMetadataBase(from: $0, other: metadataId)
          },
          next: try? PubNubHashedPageBase(from: response.payload)
        )
      })
    }
  }

  /// Get the specified user's space memberships.
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - uuids: Array of `PubNubMembershipMetadata` with the `PubNubUUIDMetadata` or `uuidMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func setMembers(
    channel metadataId: String,
    uuids members: [PubNubMembershipMetadata],
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    manageMembers(
      channel: metadataId, setting: members, removing: [],
      include: include, filter: filter, sort: sort, limit: limit, page: page,
      custom: requestConfig, completion: completion
    )
  }

  /// Remove UUID members from a Channel.
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - uuids: Array of `PubNubMembershipMetadata` with the `PubNubUUIDMetadata` or `uuidMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func removeMembers(
    channel metadataId: String,
    uuids members: [PubNubMembershipMetadata],
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    manageMembers(
      channel: metadataId, setting: [], removing: members,
      include: include, filter: filter, sort: sort,
      limit: limit, page: page, custom: requestConfig, completion: completion
    )
  }

  /// Modify the UUID member list for a Channel
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - setting: Array of `PubNubMembershipMetadata` with the `PubNubUUIDMetadata` or `uuidMetadataId` provided
  ///   - removing: Array of `PubNubMembershipMetadata` with the `PubNubUUIDMetadata` or `uuidMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func manageMembers(
    channel metadataId: String,
    setting uuidMembershipSets: [PubNubMembershipMetadata],
    removing uuidMembershipDeletes: [PubNubMembershipMetadata],
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    let router = ObjectsMembershipsRouter(.setMembers(
      channelMetadataId: metadataId, customFields: include.customIncludes, totalCount: include.totalCount,
      changes: .init(
        set: uuidMembershipSets.map { .init(metadataId: $0.uuidMetadataId, status: $0.status, custom: $0.custom) },
        delete: uuidMembershipDeletes.map { .init(metadataId: $0.uuidMetadataId, status: $0.status, custom: $0.custom) }
      ),
      filter: filter, sort: sort.memberURLValue,
      limit: limit, start: page?.start, end: page?.end
    ), configuration: requestConfig.customConfiguration ?? configuration)

    route(router,
          responseDecoder: PubNubMembershipsResponseDecoder(),
          custom: requestConfig) { result in
      completion?(result.map { response in
        (
          memberships: response.payload.data.compactMap {
            PubNubMembershipMetadataBase(from: $0, other: metadataId)
          },
          next: try? PubNubHashedPageBase(from: response.payload)
        )
      })
    }
  }
  // swiftlint:disable:next file_length
}
