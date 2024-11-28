//
//  Objects+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
import Foundation

public extension PubNub {
  /// The sort properties for Membership metadata objects
  enum MembershipSortProperty: Hashable {
    /// Sort based on the nested object (UUID or Channel) belonging to the Membership
    case object(ObjectSortProperty)
    /// Sort on the status property of the Membership
    case status
    /// Sort on the type property of the Membership
    case type
    /// Sort on the last updated property of the Membership
    case updated

    func rawValue(_ objectType: String) -> String {
      switch self {
      case let .object(property):
        return "\(objectType).\(property)"
      case .status:
        return "status"
      case .type:
        return "type"
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

    /// Creates a new `MembershipSortField` instance
    ///
    /// - Parameters:
    ///   - property: The property to sort by
    ///   - ascending: The direction of the sort
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
    /// The `type` field of the `Membership` object
    public var typeField: Bool
    /// The `status` field of the `Membership` object
    public var statusField: Bool
    /// The `type` field of the `PubNubChannelMetadata` instance in Membership
    public var channelTypeField: Bool
    /// The `status` field of the `PubNubChannelMetadata` instance in Membership
    public var channelStatusField: Bool
    /// The `custom` dictionary of the `PubNubChannelMetadata` for the Membership object
    public var channelCustomFields: Bool
    /// The `totalCount` of how many Objects are available
    public var totalCount: Bool

    /// Default init
    ///
    /// - Parameters:
    ///   - customFields: The `custom` dictionary for the Object
    ///   - channelFields: The `PubNubChannelMetadata` instance of the Membership
    ///   - statusField: The `status` field of the Membership
    ///   - typeField: The `type` field of the Membership
    ///   - channelCustomFields: The `custom` dictionary of the `PubNubChannelMetadata` for the Membership object
    ///   - channelTypeField: The `type` field of the `PubNubChannelMetadata` for the Membership object
    ///   - channelStatusField: The `status` field of the `PubNubChannelMetadata` for the Membership object
    ///   - totalCount: The `totalCount` of how many Objects are available
    public init(
      customFields: Bool = true,
      channelFields: Bool = false,
      statusField: Bool = true,
      typeField: Bool = true,
      channelCustomFields: Bool = false,
      channelTypeField: Bool = false,
      channelStatusField: Bool = false,
      totalCount: Bool = false
    ) {
      self.customFields = customFields
      self.channelFields = channelFields
      self.statusField = statusField
      self.typeField = typeField
      self.channelCustomFields = channelCustomFields
      self.channelTypeField = channelTypeField
      self.channelStatusField = channelStatusField
      self.totalCount = totalCount
    }

    var includeFields: [ObjectsMembershipsRouter.Include]? {
      var includes = [ObjectsMembershipsRouter.Include]()

      if customFields { includes.append(.custom) }
      if channelFields { includes.append(.channel) }
      if statusField { includes.append(.status) }
      if typeField { includes.append(.type) }
      if channelCustomFields { includes.append(.channelCustom) }
      if channelTypeField { includes.append(.channelType) }
      if channelStatusField { includes.append(.channelStatus) }

      return includes.isEmpty ? nil : includes
    }
  }

  struct MemberInclude: Hashable {
    /// The `custom` dictionary for the Object
    public var customFields: Bool
    /// The `PubNubUserMetadata` instance of the Membership
    public var uuidFields: Bool
    /// The `status` field of the `Membership` object
    public var statusField: Bool
    /// The `type` field of the `Membership` object
    public var typeField: Bool
    /// The `type` field of the `PubNubUserMetadata` instance in Membership
    public var uuidTypeField: Bool
    /// The `status` field of the `PubNubUserMetadata` instance in Membership
    public var uuidStatusField: Bool
    /// The `custom` dictionary of the `PubNubUserMetadata` for the Membership object
    public var uuidCustomFields: Bool
    /// The `totalCount` of how many Objects are available
    public var totalCount: Bool

    /// Default init
    ///
    /// - Parameters:
    ///   - customFields: The `custom` dictionary for the Object
    ///   - uuidFields: The `PubNubUserMetadata` instance of the Membership
    ///   - statusField: The `status` field of the Membership
    ///   - typeField: The `type` field of the Membership
    ///   - uuidCustomFields: The `custom` dictionary of the `PubNubUserMetadata` for the Membership object
    ///   - uuidTypeField: The `type` field of the `PubNubUserMetadata` for the Membership object
    ///   - uuidStatusField: The `status` field of the `PubNubUserMetadata` for the Membership object
    ///   - totalCount: The `totalCount` of how many Objects are available
    public init(
      customFields: Bool = true,
      uuidFields: Bool = false,
      statusField: Bool = true,
      typeField: Bool = true,
      uuidCustomFields: Bool = false,
      uuidTypeField: Bool = false,
      uuidStatusField: Bool = false,
      totalCount: Bool = false
    ) {
      self.customFields = customFields
      self.uuidFields = uuidFields
      self.statusField = statusField
      self.typeField = typeField
      self.uuidCustomFields = uuidCustomFields
      self.uuidTypeField = uuidTypeField
      self.uuidStatusField = uuidStatusField
      self.totalCount = totalCount
    }

    var includeFields: [ObjectsMembershipsRouter.Include]? {
      var includes = [ObjectsMembershipsRouter.Include]()

      if customFields { includes.append(.custom) }
      if uuidFields { includes.append(.uuid) }
      if statusField { includes.append(.status) }
      if typeField { includes.append(.type) }
      if uuidCustomFields { includes.append(.uuidCustom) }
      if uuidTypeField { includes.append(.uuidType) }
      if uuidStatusField { includes.append(.uuidStatus) }

      return includes.isEmpty ? nil : includes
    }
  }

  // swiftlint:disable:next line_length
  @available(*, deprecated, message: "Will be replaced with PubNub.UserIncludeFields and PubNub.ChannelIncludeFields for the User and Channel methods, respectively")
  /// Fields that include additional data inside the response for Channel or User metadata
  struct IncludeFields: Hashable {
    /// The `custom` dictionary for the Object
    public var customFields: Bool
    /// The `type` field for the Object
    public var typeField: Bool
    /// The `status` field for the Object
    public var statusField: Bool
    /// The `totalCount` of how many Objects are available
    public var totalCount: Bool

    /// Default init
    ///
    ///  - Parameters:
    ///   - custom: Whether to include `custom` data in the response
    ///   - type: Whether to include `type` in the response
    ///   - status: Whether to include `status` field in the response
    ///   - totalCount: Whether to include `totalCount` in the response
    public init(
      custom: Bool = true,
      type: Bool = true,
      status: Bool = true,
      totalCount: Bool = true
    ) {
      self.customFields = custom
      self.typeField = type
      self.statusField = status
      self.totalCount = totalCount
    }
  }

  /// Fields that include additional data inside the response for User metadata
  struct UserIncludeFields: Hashable {
    /// The `custom` dictionary for the Object
    public var custom: Bool
    /// The `type` field for the Object
    public var type: Bool
    /// The `status` field for the Object
    public var status: Bool
    /// The `totalCount` of how many Objects are available
    public var totalCount: Bool

    /// Default init
    ///
    ///  - Parameters:
    ///   - custom: Whether to include `custom` data in the response
    ///   - status: Whether to include `status` field in the response
    ///   - type: Whether to include `type` in the response
    ///   - totalCount: Whether to include `totalCount` in the response
    public init(
      custom: Bool = true,
      type: Bool = true,
      status: Bool = true,
      totalCount: Bool = true
    ) {
      self.custom = custom
      self.type = type
      self.status = status
      self.totalCount = totalCount
    }

    public var includeFields: [ObjectsUserRouter.Include]? {
      var includes = [ObjectsUserRouter.Include]()

      if custom { includes.append(.custom) }
      if status { includes.append(.status) }
      if type { includes.append(.type) }

      return includes.isEmpty ? nil : includes
    }
  }

  /// Fields that include additional data inside the response for Channel metadata
  struct ChannelIncludeFields: Hashable {
    /// The `custom` dictionary for the Object
    public var custom: Bool
    /// The `type` field for the Object
    public var type: Bool
    /// The `status` field for the Object
    public var status: Bool
    /// The `totalCount` of how many Objects are available
    public var totalCount: Bool

    /// Default init
    ///
    ///  - Parameters:
    ///   - custom: Whether to include `custom` data in the response
    ///   - status: Whether to include `status` field in the response
    ///   - type: Whether to include `type` in the response
    ///   - totalCount: Whether to include `totalCount` in the response
    public init(
      custom: Bool = true,
      type: Bool = true,
      status: Bool = true,
      totalCount: Bool = true
    ) {
      self.custom = custom
      self.type = type
      self.status = status
      self.totalCount = totalCount
    }

    public var includeFields: [ObjectsChannelRouter.Include]? {
      var includes = [ObjectsChannelRouter.Include]()

      if custom { includes.append(.custom) }
      if status { includes.append(.status) }
      if type { includes.append(.type) }

      return includes.isEmpty ? nil : includes
    }
  }

  /// The sort properties for User and Channel metadata objects
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

// MARK: - User Metadata Objects

public extension PubNub {
  /// Gets metadata for all Users.
  ///
  /// Returns a paginated list of User Metadata objects, optionally including the custom data object for each.
  ///
  /// - Parameters:
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubUserMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  @available(*, deprecated, renamed: "allUserMetadata(include:filter:sort:limit:page:custom:completion:)")
  func allUUIDMetadata(
    include: IncludeFields = IncludeFields(),
    filter: String? = nil,
    sort: [ObjectSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(uuids: [PubNubUserMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    allUserMetadata(
      include: UserIncludeFields(
        custom: include.customFields,
        type: include.typeField,
        status: include.statusField,
        totalCount: include.totalCount
      ),
      filter: filter,
      sort: sort,
      limit: limit,
      page: page,
      custom: requestConfig
    ) {
      switch $0 {
      case let .success((users, next)):
        completion?(.success((uuids: users, next: next)))
      case let .failure(error):
        completion?(.failure(error))
      }
    }
  }

  /// Gets metadata for all Users.
  ///
  /// Returns a paginated list of User Metadata objects, optionally including the custom data object for each.
  ///
  /// - Parameters:
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubUserMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func allUserMetadata(
    include: UserIncludeFields = UserIncludeFields(),
    filter: String? = nil,
    sort: [ObjectSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(users: [PubNubUserMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    let router = ObjectsUserRouter(
      .all(
        include: include.includeFields,
        totalCount: include.totalCount,
        filter: filter,
        sort: sort.urlValue,
        limit: limit,
        start: page?.start,
        end: page?.end
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      responseDecoder: PubNubUsersMetadataResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(
        result.map { (
          users: $0.payload.data,
          next: try? PubNubHashedPageBase(from: $0.payload)
        )
      })
    }
  }

  /// Get Metadata for a User.
  ///
  /// Returns metadata for the specified User, optionally including the custom data object for each.
  ///
  /// - Parameters:
  ///   - uuid: Unique User Metadata identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubUserMetadata` object belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  @available(*, deprecated, renamed: "fetchUserMetadata(_:include:custom:completion:)")
  func fetch(
    uuid metadataId: String?,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubUserMetadata, Error>) -> Void)?
  ) {
    fetchUserMetadata(
      metadataId,
      include: UserIncludeFields(custom: customFields),
      custom: requestConfig,
      completion: completion
    )
  }

  /// Get Metadata for a User.
  ///
  /// Returns metadata for the specified User, optionally including the custom data object for each.
  ///
  /// - Parameters:
  ///   - metadataId: Unique User Metadata identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubUserMetadata` object belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  func fetchUserMetadata(
    _ metadataId: String?,
    include: UserIncludeFields = UserIncludeFields(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubUserMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsUserRouter(
      .fetch(
        metadataId: metadataId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid),
        include: include.includeFields
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      responseDecoder: PubNubUserMetadataResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Set User Metadata.
  ///
  ///  Set metadata for a User in the database, optionally including the custom data object for each.
  /// - Parameters:
  ///   - uuid: The `PubNubUserMetadata` to set
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubUserMetadata` containing the set changes
  ///     - **Failure**: An `Error` describing the failure
  @available(*, deprecated, renamed: "setUserMetadata(_:include:custom:completion:)")
  func set(
    uuid metadata: PubNubUserMetadata,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubUserMetadata, Error>) -> Void)?
  ) {
    setUserMetadata(
      metadata,
      include: UserIncludeFields(custom: customFields),
      custom: requestConfig,
      completion: completion
    )
  }

  /// Set User Metadata.
  ///
  ///  Set metadata for a User in the database, optionally including the custom data object for each.
  /// - Parameters:
  ///   - user: The `PubNubUserMetadata` to set
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubUserMetadata` containing the set changes
  ///     - **Failure**: An `Error` describing the failure
  func setUserMetadata(
    _ metadata: PubNubUserMetadata,
    include: UserIncludeFields = UserIncludeFields(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubUserMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsUserRouter(
      .set(
        metadata: metadata,
        include: include.includeFields
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      responseDecoder: PubNubUserMetadataResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Remove metadata for a specified User.
  ///
  /// - Parameters:
  ///   - uuid: Unique User Metadata identifier to remove. If not supplied, then it will use the request configuration and then the default configuration
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The User identifier of the removed object
  ///     - **Failure**: An `Error` describing the failure
  @available(*, deprecated, renamed: "removeUserMetadata(_:custom:completion:)")
  func remove(
    uuid metadataId: String?,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    removeUserMetadata(
      metadataId,
      custom: requestConfig,
      completion: completion
    )
  }

  /// Remove metadata for a specified User.
  ///
  /// - Parameters:
  ///   - metadataId: Unique User Metadata identifier to remove. If not supplied, then it will use the request configuration and then the default configuration
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The identifier of the removed object
  ///     - **Failure**: An `Error` describing the failure
  func removeUserMetadata(
    _ metadataId: String?,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    // Capture the response or current configuration uuid
    let metadataId = metadataId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

    let router = ObjectsUserRouter(
      .remove(metadataId: metadataId),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      responseDecoder: GenericServiceResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in metadataId })
    }
  }
}

// MARK: - Channel Metadata Objects

public extension PubNub {
  /// Get Metadata for All Channels.
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
    let channelIncludeFields = ChannelIncludeFields(
      custom: include.customFields,
      type: include.typeField,
      status: include.statusField,
      totalCount: include.totalCount
    )
    let router = ObjectsChannelRouter(
      .all(
        include: channelIncludeFields.includeFields,
        totalCount: include.totalCount,
        filter: filter,
        sort: sort.map { "\($0.property.rawValue)\($0.ascending ? "" : ":desc")" },
        limit: limit,
        start: page?.start,
        end: page?.end
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      responseDecoder: PubNubChannelsMetadataResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(
        result.map { (
          channels: $0.payload.data,
          next: try? PubNubHashedPageBase(from: $0.payload)
        )}
      )
    }
  }

  /// Returns metadata for the specified channel including the channel's custom data.
  ///
  /// - Parameters:
  ///   - channel: Unique Channel Metadata identifier
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubChannelMetadata` object belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  @available(*, deprecated, renamed: "fetchChannelMetadata(_:include:custom:completion:)")
  func fetch(
    channel metadataId: String,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubChannelMetadata, Error>) -> Void)?
  ) {
    fetchChannelMetadata(
      metadataId,
      include: ChannelIncludeFields(custom: customFields),
      custom: requestConfig,
      completion: completion
    )
  }

  /// Returns metadata for the specified channel including the channel's custom data.
  ///
  /// - Parameters:
  ///   - metadataId: Unique Channel Metadata identifier
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubChannelMetadata` object belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  func fetchChannelMetadata(
    _ metadataId: String,
    include: ChannelIncludeFields = ChannelIncludeFields(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubChannelMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .fetch(
        metadataId: metadataId,
        include: include.includeFields
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      responseDecoder: PubNubChannelMetadataResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Set metadata for a channel in the database.
  ///
  /// - Parameters:
  ///   - channel: The `PubNubChannelMetadata` to set
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubChannelMetadata` containing the set changes
  ///     - **Failure**: An `Error` describing the failure
  @available(*, deprecated, renamed: "setChannelMetadata(_:include:custom:completion:)")
  func set(
    channel metadata: PubNubChannelMetadata,
    include customFields: Bool = true,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubChannelMetadata, Error>) -> Void)?
  ) {
    setChannelMetadata(
      metadata,
      include: ChannelIncludeFields(custom: customFields),
      custom: requestConfig,
      completion: completion
    )
  }

  /// Set metadata for a channel in the database.
  ///
  /// - Parameters:
  ///   - metadata: The `PubNubChannelMetadata` to set
  ///   - include: Include respective additional fields in the response.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The `PubNubChannelMetadata` containing the set changes
  ///     - **Failure**: An `Error` describing the failure
  func setChannelMetadata(
    _ metadata: PubNubChannelMetadata,
    include: ChannelIncludeFields = ChannelIncludeFields(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<PubNubChannelMetadata, Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .set(metadata: metadata, include: include.includeFields),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      responseDecoder: PubNubChannelMetadataResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Remove metadata for a specified channel.
  ///
  /// - Parameters:
  ///   - channel: Unique Channel Metadata identifier to remove.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The Channel identifier of the removed object
  ///     - **Failure**: An `Error` describing the failure
  @available(*, deprecated, renamed: "removeChannelMetadata(_:custom:completion:)")
  func remove(
    channel metadataId: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    removeChannelMetadata(
      metadataId,
      custom: requestConfig,
      completion: completion
    )
  }

  /// Remove metadata for a specified channel.
  ///
  /// - Parameters:
  ///   - metadataId: Unique Channel Metadata identifier to remove.
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The Channel identifier of the removed object
  ///     - **Failure**: An `Error` describing the failure
  func removeChannelMetadata(
    _ metadataId: String,
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<String, Error>) -> Void)?
  ) {
    let router = ObjectsChannelRouter(
      .remove(metadataId: metadataId),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      responseDecoder: GenericServiceResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in metadataId })
    }
  }
}

// MARK: - Memberships

public extension PubNub {
  /// Get Channel Memberships.
  ///
  /// The method returns a list of channel memberships for a user. It does not return a user's subscriptions.
  ///
  /// - Parameters:
  ///   - uuid: Unique User identifier. If not supplied, then it will use the request configuration and then the default configuration
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  @available(*, deprecated, renamed: "fetchMemberships(userId:include:filter:sort:limit:page:custom:completion:)")
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
    fetchMemberships(
      userId: uuid,
      include: include,
      filter: filter,
      sort: sort,
      limit: limit,
      page: page,
      custom: requestConfig,
      completion: completion
    )
  }

  /// Get Channel Memberships.
  ///
  /// The method returns a list of channel memberships for a user. It does not return a user's subscriptions.
  ///
  /// - Parameters:
  ///   - userId: Unique User identifier. If not supplied, then it will use the request configuration and then the default configuration
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
    userId: String?,
    include: MembershipInclude = MembershipInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    let metadataId = userId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

    let router = ObjectsMembershipsRouter(
      .fetchMemberships(
        uuidMetadataId: metadataId,
        customFields: include.includeFields,
        totalCount: include.totalCount, filter: filter,
        sort: sort.membershipURLValue,
        limit: limit, start: page?.start, end: page?.end
      ),
      configuration: requestConfig.customConfiguration ?? configuration
    )

    route(
      router,
      responseDecoder: PubNubMembershipsResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { response in
        (
          memberships: response.payload.data.compactMap { PubNubMembershipMetadataBase(from: $0, other: metadataId) },
          next: try? PubNubHashedPageBase(from: response.payload)
        )
      })
    }
  }

  /// Get Channel Members.
  ///
  /// The method returns a list of members in a channel. The list will include user metadata for members that have additional metadata stored in the database.
  ///
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
      channelMetadataId: metadataId, customFields: include.includeFields,
      totalCount: include.totalCount, filter: filter,
      sort: sort.memberURLValue,
      limit: limit, start: page?.start, end: page?.end
    ),
    configuration: requestConfig.customConfiguration ?? configuration)

    route(
      router,
      responseDecoder: PubNubMembershipsResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { response in
        (
          memberships: response.payload.data.compactMap { PubNubMembershipMetadataBase(from: $0, other: metadataId) },
          next: try? PubNubHashedPageBase(from: response.payload)
        )
      })
    }
  }

  /// Set Channel memberships for a User.
  ///
  /// - Parameters:
  ///   - uuid: Unique User identifier. If not supplied, then it will use the request configuration and then the default configuration
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
  @available(*, deprecated, renamed: "setMemberships(userId:channels:include:filter:sort:limit:page:custom:completion:)")
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
    setMemberships(
      userId: metadataId,
      channels: memberships,
      include: include,
      filter: filter,
      sort: sort,
      limit: limit,
      page: page,
      custom: requestConfig,
      completion: completion
    )
  }

  /// Set Channel memberships for a User ID.
  ///
  /// - Parameters:
  ///   - userId: Unique User identifier. If not supplied, then it will use the request configuration and then the default configuration
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
    userId metadataId: String?,
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
      userId: metadataId, setting: memberships, removing: [],
      include: include, filter: filter, sort: sort, limit: limit, page: page,
      custom: requestConfig, completion: completion
    )
  }

  /// Remove Channel memberships for a User.
  ///
  /// - Parameters:
  ///   - uuid: Unique User identifier. If not supplied, then it will use the request configuration and then the default configuration
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
  @available(*, deprecated, renamed: "removeMemberships(userId:channels:include:filter:sort:limit:page:custom:completion:)")
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
    removeMemberships(
      userId: metadataId,
      channels: memberships,
      include: include,
      filter: filter,
      sort: sort,
      limit: limit,
      page: page,
      custom: requestConfig,
      completion: completion
    )
  }

  /// Remove Channel memberships for a User ID.
  ///
  /// - Parameters:
  ///   - userId: Unique User identifier. If not supplied, then it will use the request configuration and then the default configuration
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
    userId metadataId: String?,
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
      userId: metadataId, setting: [], removing: memberships,
      include: include, filter: filter, sort: sort, limit: limit, page: page,
      custom: requestConfig, completion: completion
    )
  }

  /// Modify the Channel membership list for a User.
  ///
  /// - Parameters:
  ///   - uuid: Unique User identifier. If not supplied, then it will use the request configuration and then the default configuration
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
  @available(*, deprecated, renamed: "manageMemberships(userId:setting:removing:include:filter:sort:limit:page:custom:completion:)")
  // swiftlint:disable:previous line_length
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
    manageMemberships(
      userId: uuid,
      setting: channelMembershipSets,
      removing: channelMembershipDeletes,
      include: include,
      filter: filter,
      sort: sort,
      limit: limit,
      page: page,
      custom: requestConfig,
      completion: completion
    )
  }

  /// Modify the Channel membership list for a User.
  ///
  /// - Parameters:
  ///   - userId: Unique User identifier. If not supplied, then it will use the request configuration and then the default configuration
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
    userId: String?,
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
    let metadataId = userId ?? (requestConfig.customConfiguration?.uuid ?? configuration.uuid)

    let router = ObjectsMembershipsRouter(.setMemberships(
      uuidMetadataId: metadataId, customFields: include.includeFields, totalCount: include.totalCount,
      changes: .init(
        set: channelMembershipSets.map {
          .init(metadataId: $0.channelMetadataId, status: $0.status, type: $0.type, custom: $0.custom)
        },
        delete: channelMembershipDeletes.map {
          .init(metadataId: $0.channelMetadataId, status: $0.status, type: $0.type, custom: $0.custom)
        }
      ),
      filter: filter, sort: sort.membershipURLValue,
      limit: limit, start: page?.start, end: page?.end
    ), configuration: requestConfig.customConfiguration ?? configuration)

    route(
      router,
      responseDecoder: PubNubMembershipsResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { response in
        (
          memberships: response.payload.data.compactMap { PubNubMembershipMetadataBase(from: $0, other: metadataId) },
          next: try? PubNubHashedPageBase(from: response.payload)
        )
      })
    }
  }

  /// Set the specified user's space memberships.
  ///
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - uuids: Array of `PubNubMembershipMetadata` with the `PubNubUserMetadata` or `userMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  @available(*, deprecated, renamed: "setMembers(channels:users:include:filter:sort:limit:page:custom:completion:)")
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
    setMembers(
      channel: metadataId,
      users: members,
      include: include,
      filter: filter,
      sort: sort,
      limit: limit,
      page: page,
      custom: requestConfig,
      completion: completion
    )
  }

  /// Set the specified user's space memberships.
  ///
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - users: Array of `PubNubMembershipMetadata` with the `PubNubUserMetadata` or `userMetadataId` provided
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
    users members: [PubNubMembershipMetadata],
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

  /// Remove User members from a Channel.
  ///
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - uuids: Array of `PubNubMembershipMetadata` with the `PubNubUserMetadata` or `userMetadataId` provided
  ///   - include: Include respective additional fields in the response.
  ///   - filter: Expression used to filter the results. Only objects whose properties satisfy the given expression are returned. The filter language is defined [here](https://www.pubnub.com/docs/swift/stream-filtering-tutorial#filtering-language-definition).
  ///   - sort: List of properties to sort response objects
  ///   - limit: The number of objects to retrieve at a time
  ///   - page: The paging hash strings used for pagination
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of `PubNubMembershipMetadata`, and the next pagination `PubNubHashedPage` (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  @available(*, deprecated, renamed: "removeMembers(channel:users:include:filter:sort:limit:page:custom:completion:)")
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
    removeMembers(
      channel: metadataId,
      users: members,
      include: include,
      filter: filter,
      sort: sort,
      limit: limit,
      page: page,
      custom: requestConfig,
      completion: completion
    )
  }

  /// Remove User members from a Channel.
  ///
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - users: Array of `PubNubMembershipMetadata` with the `PubNubUserMetadata` or `uuidMetadataId` provided
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
    users members: [PubNubMembershipMetadata],
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

  /// Modify the User member list for a Channel.
  ///
  /// - Parameters:
  ///   - channel: Unique Channel identifier.
  ///   - setting: Array of `PubNubMembershipMetadata` with the `PubNubUserMetadata` or `userMetadataId` provided
  ///   - removing: Array of `PubNubMembershipMetadata` with the `PubNubUserMetadata` or `userMetadataId` provided
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
    setting userMembershipSets: [PubNubMembershipMetadata],
    removing userMembershipDeletes: [PubNubMembershipMetadata],
    include: MemberInclude = MemberInclude(),
    filter: String? = nil,
    sort: [MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = Page(),
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubMembershipMetadata], next: PubNubHashedPage?), Error>) -> Void)?
  ) {
    let router = ObjectsMembershipsRouter(.setMembers(
      channelMetadataId: metadataId, customFields: include.includeFields, totalCount: include.totalCount,
      changes: .init(
        set: userMembershipSets.map {
          .init(metadataId: $0.userMetadataId, status: $0.status, type: $0.type, custom: $0.custom)
        },
        delete: userMembershipDeletes.map {
          .init(metadataId: $0.userMetadataId, status: $0.status, type: $0.type, custom: $0.custom)
        }
      ),
      filter: filter, sort: sort.memberURLValue,
      limit: limit, start: page?.start, end: page?.end
    ), configuration: requestConfig.customConfiguration ?? configuration)

    route(
      router,
      responseDecoder: PubNubMembershipsResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { response in
        (
          memberships: response.payload.data.compactMap { PubNubMembershipMetadataBase(from: $0, other: metadataId) },
          next: try? PubNubHashedPageBase(from: response.payload)
        )
      })
    }
  }
  // swiftlint:disable:next file_length
}
