//
//  DataSync+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - JSON Patch

/// A single [RFC 6902](https://datatracker.ietf.org/doc/html/rfc6902) JSON Patch operation applied by the DataSync `update*` methods.
public enum PubNubDataSyncPatchOperation {
  /// Adds a value at the given path
  case add(path: String, value: JSONCodable)
  /// Removes the value at the given path
  case remove(path: String)
  /// Replaces the value at the given path
  case replace(path: String, value: JSONCodable)
  /// Moves the value at `from` to the given path
  case move(from: String, path: String)
  /// Copies the value at `from` to the given path
  case copy(from: String, path: String)
  /// Asserts that the value at the given path matches, failing the whole patch when it doesn't
  case test(path: String, value: JSONCodable)

  var patchOperation: JSONPatchOperation {
    switch self {
    case let .add(path, value):
      return .add(path: path, value: value.codableValue)
    case let .remove(path):
      return .remove(path: path)
    case let .replace(path, value):
      return .replace(path: path, value: value.codableValue)
    case let .move(from, path):
      return .move(from: from, path: path)
    case let .copy(from, path):
      return .copy(from: from, path: path)
    case let .test(path, value):
      return .test(path: path, value: value.codableValue)
    }
  }
}

extension PubNubDataSyncPatchOperation: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .add(path, value):
      return "add(path: \(path), value: \(value))"
    case let .remove(path):
      return "remove(path: \(path))"
    case let .replace(path, value):
      return "replace(path: \(path), value: \(value))"
    case let .move(from, path):
      return "move(from: \(from), path: \(path))"
    case let .copy(from, path):
      return "copy(from: \(from), path: \(path))"
    case let .test(path, value):
      return "test(path: \(path), value: \(value))"
    }
  }
}

// MARK: - Sorting

public extension PubNub {
  /// The property and direction to sort a paged DataSync response
  ///
  /// Only properties declared by the class the results conform to can be sorted on. Sorting on anything
  /// else, including system fields such as `createdAt` or `status`, fails the request.
  struct DataSyncSortField: Hashable {
    /// The name of the property to sort by
    public let property: String
    /// The direction of the sort
    public let ascending: Bool

    /// Creates a new `DataSyncSortField` instance
    ///
    /// - Parameters:
    ///   - property: The name of the property to sort by
    ///   - ascending: The direction of the sort
    public init(property: String, ascending: Bool = true) {
      self.property = property
      self.ascending = ascending
    }
  }
}

extension PubNub.DataSyncSortField: CustomStringConvertible {
  public var description: String {
    "\(property)\(ascending ? "" : ":desc")"
  }
}

extension Array where Element == PubNub.DataSyncSortField {
  /// The comma-separated value sent as the `sort` query parameter, or `nil` when there is nothing to sort by
  var urlValue: String? {
    isEmpty ? nil : map { $0.description }.csvString
  }
}

// MARK: - Namespace

public extension PubNub {
  /// The entry point for all PubNub DataSync requests.
  var dataSync: DataSyncAPI {
    DataSyncAPI(pubnub: self)
  }

  /// A namespace exposing the PubNub DataSync request methods.
  ///
  /// Obtain an instance through ``PubNub/dataSync``.
  struct DataSyncAPI {
    private let pubnub: PubNub

    init(pubnub: PubNub) {
      self.pubnub = pubnub
    }
  }
}

// MARK: - Entities

public extension PubNub.DataSyncAPI {
  /// Gets a page of entities of a given class.
  ///
  /// - Parameters:
  ///   - entityClass: The name of the class to list entities of
  ///   - entityClassVersion: Restricts results to a single class version. If omitted, every version is returned, including classes that extend this one
  ///   - entityClassLevel: The level to resolve the class name at. If omitted, the first level declaring it wins, searching `subKey`, `account`, then `global`
  ///   - cursor: The ``PubNubDataSyncPage/cursor`` of a previous page, or `nil` for the first page
  ///   - limit: The number of entities to retrieve, between 1 and 100. Defaults to 20
  ///   - filter: Expression used to filter the results. Mutually exclusive with `filterAdvanced`
  ///   - filterAdvanced: Advanced expression used to filter the results. Mutually exclusive with `filter`
  ///   - sort: List of properties to sort the results by
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of ``PubNubDataSyncEntity``, and the next page (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func getEntities(
    entityClass: String,
    entityClassVersion: Int? = nil,
    entityClassLevel: PubNubDataSyncClassLevel? = nil,
    cursor: String? = nil,
    limit: Int? = nil,
    filter: String? = nil,
    filterAdvanced: String? = nil,
    sort: [PubNub.DataSyncSortField] = [],
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<(entities: [PubNubDataSyncEntity], next: PubNubDataSyncPage?), Error>) -> Void)?
  ) {
    log(
      operation: "getEntities",
      details: "List DataSync entities",
      arguments: [
        ("entityClass", entityClass),
        ("entityClassVersion", entityClassVersion),
        ("entityClassLevel", entityClassLevel?.stringValue),
        ("cursor", cursor),
        ("limit", limit),
        ("filter", filter),
        ("filterAdvanced", filterAdvanced),
        ("sort", sort),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncEntityRouter(
      .all(
        entityClass: entityClass,
        entityClassVersion: entityClassVersion,
        entityClassLevel: entityClassLevel?.stringValue,
        cursor: cursor,
        limit: limit,
        filter: filter,
        filterAdvanced: filterAdvanced,
        sort: sort.urlValue
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncListValueResponseDecoder<PubNubDataSyncEntity>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { (
        entities: $0.payload.data,
        next: PubNubDataSyncPage(from: $0.payload.meta, requestedLimit: limit)
      ) })
    }
  }

  /// Gets a single entity by identifier.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the entity
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The ``PubNubDataSyncEntity`` belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  func getEntity(
    _ id: String,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncEntity, Error>) -> Void)?
  ) {
    log(
      operation: "getEntity",
      details: "Fetch DataSync entity",
      arguments: [("id", id), ("custom", requestConfig)]
    )

    let router = DataSyncEntityRouter(
      .fetch(id: id),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncEntity>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Creates an entity of a given class.
  ///
  /// - Parameters:
  ///   - entityClass: The name of the class to create the entity in
  ///   - entityClassVersion: The version of the class the payload conforms to
  ///   - entityClassLevel: The level to resolve the class name at. If omitted, the first level declaring it wins, searching `subKey`, `account`, then `global`
  ///   - id: The unique identifier to create the entity with, or `nil` to let the service assign one
  ///   - status: An arbitrary status to store with the entity
  ///   - payload: The entity fields
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The created ``PubNubDataSyncEntity``
  ///     - **Failure**: An `Error` describing the failure
  func createEntity(
    entityClass: String,
    entityClassVersion: Int,
    entityClassLevel: PubNubDataSyncClassLevel? = nil,
    id: String? = nil,
    status: String? = nil,
    payload: JSONCodable? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncEntity, Error>) -> Void)?
  ) {
    log(
      operation: "createEntity",
      details: "Create DataSync entity",
      arguments: [
        ("entityClass", entityClass),
        ("entityClassVersion", entityClassVersion),
        ("entityClassLevel", entityClassLevel?.stringValue),
        ("id", id),
        ("status", status),
        ("payload", payload),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncEntityRouter(
      .create(
        body: .init(
          id: id,
          entityClass: entityClass,
          entityClassVersion: entityClassVersion,
          entityClassLevel: entityClassLevel?.stringValue,
          status: status,
          payload: payload?.codableValue
        )
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncEntity>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Replaces an entity in full.
  ///
  /// Every mutable field is overwritten. Omitting `status` or `payload` clears the stored value rather than preserving it, so a read-modify-write
  /// must send back every field it wants to keep. Use ``updateEntity(_:operations:ifMatchesEtag:custom:completion:)`` to change
  /// part of an entity.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the entity
  ///   - entityClassVersion: The version of the class the payload conforms to
  ///   - status: An arbitrary status to store with the entity
  ///   - payload: The replacement entity fields
  ///   - ifMatchesEtag: The ``PubNubDataSyncEntity/eTag`` last read, to fail the request when the entity changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The replaced ``PubNubDataSyncEntity``
  ///     - **Failure**: An `Error` describing the failure
  func setEntity(
    _ id: String,
    entityClassVersion: Int,
    status: String? = nil,
    payload: JSONCodable? = nil,
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncEntity, Error>) -> Void)?
  ) {
    log(
      operation: "setEntity",
      details: "Replace DataSync entity",
      arguments: [
        ("id", id),
        ("entityClassVersion", entityClassVersion),
        ("status", status),
        ("payload", payload),
        ("ifMatchesEtag", ifMatchesEtag),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncEntityRouter(
      .replace(
        id: id,
        body: .init(status: status, entityClassVersion: entityClassVersion, payload: payload?.codableValue),
        ifMatch: ifMatchesEtag
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncEntity>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Applies a set of JSON Patch operations to an entity.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the entity
  ///   - operations: The RFC 6902 operations to apply, which must not be empty
  ///   - ifMatchesEtag: The ``PubNubDataSyncEntity/eTag`` last read, to fail the request when the entity changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The patched ``PubNubDataSyncEntity``
  ///     - **Failure**: An `Error` describing the failure
  func updateEntity(
    _ id: String,
    operations: [PubNubDataSyncPatchOperation],
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncEntity, Error>) -> Void)?
  ) {
    log(
      operation: "updateEntity",
      details: "Patch DataSync entity",
      arguments: [
        ("id", id),
        ("operations", operations),
        ("ifMatchesEtag", ifMatchesEtag),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncEntityRouter(
      .patch(id: id, operations: operations.map { $0.patchOperation }, ifMatch: ifMatchesEtag),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncEntity>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Removes an entity.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the entity
  ///   - ifMatchesEtag: The ``PubNubDataSyncEntity/eTag`` last read, to fail the request when the entity changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An acknowledgement that the entity was removed
  ///     - **Failure**: An `Error` describing the failure
  func removeEntity(
    _ id: String,
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    log(
      operation: "removeEntity",
      details: "Remove DataSync entity",
      arguments: [("id", id), ("ifMatchesEtag", ifMatchesEtag), ("custom", requestConfig)]
    )

    let router = DataSyncEntityRouter(
      .remove(id: id, ifMatch: ifMatchesEtag),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncStatusResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in () })
    }
  }
}

// MARK: - Users

public extension PubNub.DataSyncAPI {
  /// Gets a page of users.
  ///
  /// Called without any class parameters, this lists users of the built-in `User` class declared at `global`.
  ///
  /// - Parameters:
  ///   - classVersion: Restricts results to a single version of the `User` class. If omitted, every version is returned, including classes that extend `User`
  ///   - className: The class to list, which must be `User` or a class that extends it. Defaults to `User`
  ///   - classLevel: The level to resolve `className` at
  ///     - **Omitted**: the first level declaring it wins, searching `subKey`, `account`, then `global`
  ///     - **Provided**: only that level is searched
  ///   - cursor: The ``PubNubDataSyncPage/cursor`` of a previous page, or `nil` for the first page
  ///   - limit: The number of users to retrieve, between 1 and 100. Defaults to 20
  ///   - filter: Expression used to filter the results. Mutually exclusive with `filterAdvanced`
  ///   - filterAdvanced: Advanced expression used to filter the results. Mutually exclusive with `filter`
  ///   - sort: List of properties to sort the results by
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of ``PubNubDataSyncUser``, and the next page (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func getUsers(
    classVersion: Int? = nil,
    className: String? = nil,
    classLevel: PubNubDataSyncClassLevel? = nil,
    cursor: String? = nil,
    limit: Int? = nil,
    filter: String? = nil,
    filterAdvanced: String? = nil,
    sort: [PubNub.DataSyncSortField] = [],
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<(users: [PubNubDataSyncUser], next: PubNubDataSyncPage?), Error>) -> Void)?
  ) {
    log(
      operation: "getUsers",
      details: "List DataSync users",
      arguments: [
        ("classVersion", classVersion),
        ("className", className),
        ("classLevel", classLevel?.stringValue),
        ("cursor", cursor),
        ("limit", limit),
        ("filter", filter),
        ("filterAdvanced", filterAdvanced),
        ("sort", sort),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncUserRouter(
      .all(
        entityClass: className,
        entityClassVersion: classVersion,
        entityClassLevel: classLevel?.stringValue,
        cursor: cursor,
        limit: limit,
        filter: filter,
        filterAdvanced: filterAdvanced,
        sort: sort.urlValue
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncListValueResponseDecoder<PubNubDataSyncUser>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { (
        users: $0.payload.data,
        next: PubNubDataSyncPage(from: $0.payload.meta, requestedLimit: limit)
      ) })
    }
  }

  /// Gets a single user by identifier.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the user
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The ``PubNubDataSyncUser`` belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  func getUser(
    _ id: String,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncUser, Error>) -> Void)?
  ) {
    log(
      operation: "getUser",
      details: "Fetch DataSync user",
      arguments: [("id", id), ("custom", requestConfig)]
    )

    let router = DataSyncUserRouter(
      .fetch(id: id),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncUser>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Creates a user.
  ///
  /// Called without any class parameters, this creates a user of the built-in `User` class declared at `global`.
  ///
  /// - Parameters:
  ///   - classVersion: The version of the `User` class the payload conforms to
  ///   - className: The class to create the user in, which must be `User` or a class that extends it. Defaults to `User`
  ///   - classLevel: The level to resolve `className` at
  ///     - **Omitted**: the first level declaring it wins, searching `subKey`, `account`, then `global`
  ///     - **Provided**: only that level is searched
  ///   - id: The unique identifier to create the user with, or `nil` to let the service assign one
  ///   - status: An arbitrary status to store with the user
  ///   - payload: The user fields
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The created ``PubNubDataSyncUser``
  ///     - **Failure**: An `Error` describing the failure
  func createUser(
    classVersion: Int,
    className: String? = nil,
    classLevel: PubNubDataSyncClassLevel? = nil,
    id: String? = nil,
    status: String? = nil,
    payload: JSONCodable? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncUser, Error>) -> Void)?
  ) {
    log(
      operation: "createUser",
      details: "Create DataSync user",
      arguments: [
        ("classVersion", classVersion),
        ("className", className),
        ("classLevel", classLevel?.stringValue),
        ("id", id),
        ("status", status),
        ("payload", payload),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncUserRouter(
      .create(
        body: .init(
          id: id,
          status: status,
          entityClass: className,
          entityClassVersion: classVersion,
          entityClassLevel: classLevel?.stringValue,
          payload: payload?.codableValue
        )
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncUser>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Replaces a user in full.
  ///
  /// Every mutable field is overwritten. Omitting `status` or `payload` clears the stored value rather than preserving it, so a read-modify-write
  /// must send back every field it wants to keep. Use ``updateUser(_:operations:ifMatchesEtag:custom:completion:)`` to change
  /// part of a user.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the user
  ///   - classVersion: The version of the `User` class the payload conforms to
  ///   - status: An arbitrary status to store with the user
  ///   - payload: The replacement user fields
  ///   - ifMatchesEtag: The ``PubNubDataSyncUser/eTag`` last read, to fail the request when the user changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The replaced ``PubNubDataSyncUser``
  ///     - **Failure**: An `Error` describing the failure
  func setUser(
    _ id: String,
    classVersion: Int,
    status: String? = nil,
    payload: JSONCodable? = nil,
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncUser, Error>) -> Void)?
  ) {
    log(
      operation: "setUser",
      details: "Replace DataSync user",
      arguments: [
        ("id", id),
        ("classVersion", classVersion),
        ("status", status),
        ("payload", payload),
        ("ifMatchesEtag", ifMatchesEtag),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncUserRouter(
      .replace(
        id: id,
        body: .init(status: status, entityClassVersion: classVersion, payload: payload?.codableValue),
        ifMatch: ifMatchesEtag
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncUser>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Applies a set of JSON Patch operations to a user.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the user
  ///   - operations: The RFC 6902 operations to apply, which must not be empty
  ///   - ifMatchesEtag: The ``PubNubDataSyncUser/eTag`` last read, to fail the request when the user changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The patched ``PubNubDataSyncUser``
  ///     - **Failure**: An `Error` describing the failure
  func updateUser(
    _ id: String,
    operations: [PubNubDataSyncPatchOperation],
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncUser, Error>) -> Void)?
  ) {
    log(
      operation: "updateUser",
      details: "Patch DataSync user",
      arguments: [
        ("id", id),
        ("operations", operations),
        ("ifMatchesEtag", ifMatchesEtag),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncUserRouter(
      .patch(id: id, operations: operations.map { $0.patchOperation }, ifMatch: ifMatchesEtag),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncUser>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Removes a user.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the user
  ///   - ifMatchesEtag: The ``PubNubDataSyncUser/eTag`` last read, to fail the request when the user changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An acknowledgement that the user was removed
  ///     - **Failure**: An `Error` describing the failure
  func removeUser(
    _ id: String,
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    log(
      operation: "removeUser",
      details: "Remove DataSync user",
      arguments: [("id", id), ("ifMatchesEtag", ifMatchesEtag), ("custom", requestConfig)]
    )

    let router = DataSyncUserRouter(
      .remove(id: id, ifMatch: ifMatchesEtag),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncStatusResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in () })
    }
  }
}

// MARK: - Channels

public extension PubNub.DataSyncAPI {
  /// Gets a page of channels.
  ///
  /// Called without any class parameters, this lists channels of the built-in `Channel` class declared at `global`.
  ///
  /// - Parameters:
  ///   - classVersion: Restricts results to a single version of the `Channel` class. If omitted, every version is returned, including classes that extend `Channel`
  ///   - className: The class to list, which must be `Channel` or a class that extends it. Defaults to `Channel`
  ///   - classLevel: The level to resolve `className` at
  ///     - **Omitted**: the first level declaring it wins, searching `subKey`, `account`, then `global`
  ///     - **Provided**: only that level is searched
  ///   - cursor: The ``PubNubDataSyncPage/cursor`` of a previous page, or `nil` for the first page
  ///   - limit: The number of channels to retrieve, between 1 and 100. Defaults to 20
  ///   - filter: Expression used to filter the results. Mutually exclusive with `filterAdvanced`
  ///   - filterAdvanced: Advanced expression used to filter the results. Mutually exclusive with `filter`
  ///   - sort: List of properties to sort the results by
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of ``PubNubDataSyncChannel``, and the next page (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func getChannels(
    classVersion: Int? = nil,
    className: String? = nil,
    classLevel: PubNubDataSyncClassLevel? = nil,
    cursor: String? = nil,
    limit: Int? = nil,
    filter: String? = nil,
    filterAdvanced: String? = nil,
    sort: [PubNub.DataSyncSortField] = [],
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<(channels: [PubNubDataSyncChannel], next: PubNubDataSyncPage?), Error>) -> Void)?
  ) {
    log(
      operation: "getChannels",
      details: "List DataSync channels",
      arguments: [
        ("classVersion", classVersion),
        ("className", className),
        ("classLevel", classLevel?.stringValue),
        ("cursor", cursor),
        ("limit", limit),
        ("filter", filter),
        ("filterAdvanced", filterAdvanced),
        ("sort", sort),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncChannelRouter(
      .all(
        entityClass: className,
        entityClassVersion: classVersion,
        entityClassLevel: classLevel?.stringValue,
        cursor: cursor,
        limit: limit,
        filter: filter,
        filterAdvanced: filterAdvanced,
        sort: sort.urlValue
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncListValueResponseDecoder<PubNubDataSyncChannel>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { (
        channels: $0.payload.data,
        next: PubNubDataSyncPage(from: $0.payload.meta, requestedLimit: limit)
      ) })
    }
  }

  /// Gets a single channel by identifier.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the channel
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The ``PubNubDataSyncChannel`` belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  func getChannel(
    _ id: String,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncChannel, Error>) -> Void)?
  ) {
    log(
      operation: "getChannel",
      details: "Fetch DataSync channel",
      arguments: [("id", id), ("custom", requestConfig)]
    )

    let router = DataSyncChannelRouter(
      .fetch(id: id),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncChannel>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Creates a channel.
  ///
  /// Called without any class parameters, this creates a channel of the built-in `Channel` class declared at `global`.
  ///
  /// - Parameters:
  ///   - classVersion: The version of the `Channel` class the payload conforms to
  ///   - className: The class to create the channel in, which must be `Channel` or a class that extends it. Defaults to `Channel`
  ///   - classLevel: The level to resolve `className` at
  ///     - **Omitted**: the first level declaring it wins, searching `subKey`, `account`, then `global`
  ///     - **Provided**: only that level is searched
  ///   - id: The unique identifier to create the channel with, or `nil` to let the service assign one
  ///   - status: An arbitrary status to store with the channel
  ///   - payload: The channel fields
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The created ``PubNubDataSyncChannel``
  ///     - **Failure**: An `Error` describing the failure
  func createChannel(
    classVersion: Int,
    className: String? = nil,
    classLevel: PubNubDataSyncClassLevel? = nil,
    id: String? = nil,
    status: String? = nil,
    payload: JSONCodable? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncChannel, Error>) -> Void)?
  ) {
    log(
      operation: "createChannel",
      details: "Create DataSync channel",
      arguments: [
        ("classVersion", classVersion),
        ("className", className),
        ("classLevel", classLevel?.stringValue),
        ("id", id),
        ("status", status),
        ("payload", payload),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncChannelRouter(
      .create(
        body: .init(
          id: id,
          status: status,
          entityClass: className,
          entityClassVersion: classVersion,
          entityClassLevel: classLevel?.stringValue,
          payload: payload?.codableValue
        )
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncChannel>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Replaces a channel in full.
  ///
  /// Every mutable field is overwritten. Omitting `status` or `payload` clears the stored value rather than preserving it, so a read-modify-write
  /// must send back every field it wants to keep. Use ``updateChannel(_:operations:ifMatchesEtag:custom:completion:)`` to change
  /// part of a channel.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the channel
  ///   - classVersion: The version of the `Channel` class the payload conforms to
  ///   - status: An arbitrary status to store with the channel
  ///   - payload: The replacement channel fields
  ///   - ifMatchesEtag: The ``PubNubDataSyncChannel/eTag`` last read, to fail the request when the channel changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The replaced ``PubNubDataSyncChannel``
  ///     - **Failure**: An `Error` describing the failure
  func setChannel(
    _ id: String,
    classVersion: Int,
    status: String? = nil,
    payload: JSONCodable? = nil,
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncChannel, Error>) -> Void)?
  ) {
    log(
      operation: "setChannel",
      details: "Replace DataSync channel",
      arguments: [
        ("id", id),
        ("classVersion", classVersion),
        ("status", status),
        ("payload", payload),
        ("ifMatchesEtag", ifMatchesEtag),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncChannelRouter(
      .replace(
        id: id,
        body: .init(status: status, entityClassVersion: classVersion, payload: payload?.codableValue),
        ifMatch: ifMatchesEtag
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncChannel>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Applies a set of JSON Patch operations to a channel.
  ///
  /// The operations are applied atomically: if any one of them fails, the channel is left unchanged.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the channel
  ///   - operations: The RFC 6902 operations to apply, which must not be empty
  ///   - ifMatchesEtag: The ``PubNubDataSyncChannel/eTag`` last read, to fail the request when the channel changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The patched ``PubNubDataSyncChannel``
  ///     - **Failure**: An `Error` describing the failure
  func updateChannel(
    _ id: String,
    operations: [PubNubDataSyncPatchOperation],
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncChannel, Error>) -> Void)?
  ) {
    log(
      operation: "updateChannel",
      details: "Patch DataSync channel",
      arguments: [
        ("id", id),
        ("operations", operations),
        ("ifMatchesEtag", ifMatchesEtag),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncChannelRouter(
      .patch(id: id, operations: operations.map { $0.patchOperation }, ifMatch: ifMatchesEtag),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncChannel>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Removes a channel.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the channel
  ///   - ifMatchesEtag: The ``PubNubDataSyncChannel/eTag`` last read, to fail the request when the channel changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An acknowledgement that the channel was removed
  ///     - **Failure**: An `Error` describing the failure
  func removeChannel(
    _ id: String,
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    log(
      operation: "removeChannel",
      details: "Remove DataSync channel",
      arguments: [("id", id), ("ifMatchesEtag", ifMatchesEtag), ("custom", requestConfig)]
    )

    let router = DataSyncChannelRouter(
      .remove(id: id, ifMatch: ifMatchesEtag),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncStatusResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in () })
    }
  }
}

// MARK: - Memberships

public extension PubNub.DataSyncAPI {
  /// Gets a page of memberships, optionally narrowed to a channel and/or a user.
  ///
  /// - Parameters:
  ///   - channelId: Restricts results to memberships of a single channel
  ///   - userId: Restricts results to memberships of a single user
  ///   - classVersion: Restricts results to a single version of the `Membership` class. If omitted, every version is returned
  ///   - cursor: The ``PubNubDataSyncPage/cursor`` of a previous page, or `nil` for the first page
  ///   - limit: The number of memberships to retrieve, between 1 and 100. Defaults to 20
  ///   - filter: Expression used to filter the results. Mutually exclusive with `filterAdvanced`
  ///   - filterAdvanced: Advanced expression used to filter the results. Mutually exclusive with `filter`
  ///   - sort: List of properties to sort the results by
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of ``PubNubDataSyncMembership``, and the next page (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func getMemberships(
    channelId: String? = nil,
    userId: String? = nil,
    classVersion: Int? = nil,
    cursor: String? = nil,
    limit: Int? = nil,
    filter: String? = nil,
    filterAdvanced: String? = nil,
    sort: [PubNub.DataSyncSortField] = [],
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<(memberships: [PubNubDataSyncMembership], next: PubNubDataSyncPage?), Error>) -> Void)?
  ) {
    log(
      operation: "getMemberships",
      details: "List DataSync memberships",
      arguments: [
        ("channelId", channelId),
        ("userId", userId),
        ("classVersion", classVersion),
        ("cursor", cursor),
        ("limit", limit),
        ("filter", filter),
        ("filterAdvanced", filterAdvanced),
        ("sort", sort),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncMembershipRouter(
      .all(
        userId: userId,
        channelId: channelId,
        relationshipClassVersion: classVersion,
        cursor: cursor,
        limit: limit,
        filter: filter,
        filterAdvanced: filterAdvanced,
        sort: sort.urlValue
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncListValueResponseDecoder<PubNubDataSyncMembership>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { (
        memberships: $0.payload.data,
        next: PubNubDataSyncPage(from: $0.payload.meta, requestedLimit: limit)
      ) })
    }
  }

  /// Gets a single membership by identifier.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the membership
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The ``PubNubDataSyncMembership`` belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  func getMembership(
    _ id: String,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncMembership, Error>) -> Void)?
  ) {
    log(
      operation: "getMembership",
      details: "Fetch DataSync membership",
      arguments: [("id", id), ("custom", requestConfig)]
    )

    let router = DataSyncMembershipRouter(
      .fetch(id: id),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncMembership>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Creates a membership joining a user to a channel.
  ///
  /// - Parameters:
  ///   - channelId: The unique identifier of the channel to join
  ///   - userId: The unique identifier of the user to join
  ///   - classVersion: The version of the `Membership` class the payload conforms to
  ///   - id: The unique identifier to create the membership with, or `nil` to let the service assign one
  ///   - status: An arbitrary status to store with the membership
  ///   - payload: The membership fields
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The created ``PubNubDataSyncMembership``
  ///     - **Failure**: An `Error` describing the failure
  func createMembership(
    channelId: String,
    userId: String,
    classVersion: Int,
    id: String? = nil,
    status: String? = nil,
    payload: JSONCodable? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncMembership, Error>) -> Void)?
  ) {
    log(
      operation: "createMembership",
      details: "Create DataSync membership",
      arguments: [
        ("channelId", channelId),
        ("userId", userId),
        ("classVersion", classVersion),
        ("id", id),
        ("status", status),
        ("payload", payload),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncMembershipRouter(
      .create(
        body: .init(
          id: id,
          channelId: channelId,
          userId: userId,
          relationshipClassVersion: classVersion,
          status: status,
          payload: payload?.codableValue
        )
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncMembership>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Replaces a membership in full.
  ///
  /// Every mutable field is overwritten. Omitting `status` or `payload` clears the stored value rather than preserving it, so a read-modify-write
  /// must send back every field it wants to keep. Use ``updateMembership(_:operations:ifMatchesEtag:custom:completion:)`` to change part of a membership.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the membership
  ///   - classVersion: The version of the `Membership` class the payload conforms to
  ///   - status: An arbitrary status to store with the membership
  ///   - payload: The replacement membership fields
  ///   - ifMatchesEtag: The ``PubNubDataSyncMembership/eTag`` last read, to fail the request when the membership changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The replaced ``PubNubDataSyncMembership``
  ///     - **Failure**: An `Error` describing the failure
  func setMembership(
    _ id: String,
    classVersion: Int,
    status: String? = nil,
    payload: JSONCodable? = nil,
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncMembership, Error>) -> Void)?
  ) {
    log(
      operation: "setMembership",
      details: "Replace DataSync membership",
      arguments: [
        ("id", id),
        ("classVersion", classVersion),
        ("status", status),
        ("payload", payload),
        ("ifMatchesEtag", ifMatchesEtag),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncMembershipRouter(
      .replace(
        id: id,
        body: .init(status: status, relationshipClassVersion: classVersion, payload: payload?.codableValue),
        ifMatch: ifMatchesEtag
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncMembership>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Applies a set of JSON Patch operations to a membership.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the membership
  ///   - operations: The RFC 6902 operations to apply, which must not be empty
  ///   - ifMatchesEtag: The ``PubNubDataSyncMembership/eTag`` last read, to fail the request when the membership changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The patched ``PubNubDataSyncMembership``
  ///     - **Failure**: An `Error` describing the failure
  func updateMembership(
    _ id: String,
    operations: [PubNubDataSyncPatchOperation],
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncMembership, Error>) -> Void)?
  ) {
    log(
      operation: "updateMembership",
      details: "Patch DataSync membership",
      arguments: [
        ("id", id),
        ("operations", operations),
        ("ifMatchesEtag", ifMatchesEtag),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncMembershipRouter(
      .patch(id: id, operations: operations.map { $0.patchOperation }, ifMatch: ifMatchesEtag),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncMembership>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Removes a membership.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the membership
  ///   - ifMatchesEtag: The ``PubNubDataSyncMembership/eTag`` last read, to fail the request when the membership changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An acknowledgement that the membership was removed
  ///     - **Failure**: An `Error` describing the failure
  func removeMembership(
    _ id: String,
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    log(
      operation: "removeMembership",
      details: "Remove DataSync membership",
      arguments: [("id", id), ("ifMatchesEtag", ifMatchesEtag), ("custom", requestConfig)]
    )

    let router = DataSyncMembershipRouter(
      .remove(id: id, ifMatch: ifMatchesEtag),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncStatusResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in () })
    }
  }
}

// MARK: - Relationships

public extension PubNub.DataSyncAPI {
  /// Gets a page of relationships of a given class.
  ///
  /// - Parameters:
  ///   - relationshipClass: The name of the class to list relationships of
  ///   - entityAId: Restricts results to relationships whose side A is this entity
  ///   - entityBId: Restricts results to relationships whose side B is this entity
  ///   - relationshipClassVersion: Restricts results to a single version of the class. If omitted, every version is returned
  ///   - cursor: The ``PubNubDataSyncPage/cursor`` of a previous page, or `nil` for the first page
  ///   - limit: The number of relationships to retrieve, between 1 and 100. Defaults to 20
  ///   - filter: Expression used to filter the results. Mutually exclusive with `filterAdvanced`
  ///   - filterAdvanced: Advanced expression used to filter the results. Mutually exclusive with `filter`
  ///   - sort: List of properties to sort the results by
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: A `Tuple` containing an `Array` of ``PubNubDataSyncRelationship``, and the next page (if one exists)
  ///     - **Failure**: An `Error` describing the failure
  func getRelationships(
    relationshipClass: String,
    entityAId: String? = nil,
    entityBId: String? = nil,
    relationshipClassVersion: Int? = nil,
    cursor: String? = nil,
    limit: Int? = nil,
    filter: String? = nil,
    filterAdvanced: String? = nil,
    sort: [PubNub.DataSyncSortField] = [],
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<(relationships: [PubNubDataSyncRelationship], next: PubNubDataSyncPage?), Error>) -> Void)?
  ) {
    log(
      operation: "getRelationships",
      details: "List DataSync relationships",
      arguments: [
        ("relationshipClass", relationshipClass),
        ("entityAId", entityAId),
        ("entityBId", entityBId),
        ("relationshipClassVersion", relationshipClassVersion),
        ("cursor", cursor),
        ("limit", limit),
        ("filter", filter),
        ("filterAdvanced", filterAdvanced),
        ("sort", sort),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncRelationshipRouter(
      .all(
        relationshipClass: relationshipClass,
        entityAId: entityAId,
        entityBId: entityBId,
        relationshipClassVersion: relationshipClassVersion,
        cursor: cursor,
        limit: limit,
        filter: filter,
        filterAdvanced: filterAdvanced,
        sort: sort.urlValue
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncListValueResponseDecoder<PubNubDataSyncRelationship>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { (
        relationships: $0.payload.data,
        next: PubNubDataSyncPage(from: $0.payload.meta, requestedLimit: limit)
      ) })
    }
  }

  /// Gets a single relationship by identifier.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the relationship
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The ``PubNubDataSyncRelationship`` belonging to the identifier
  ///     - **Failure**: An `Error` describing the failure
  func getRelationship(
    _ id: String,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncRelationship, Error>) -> Void)?
  ) {
    log(
      operation: "getRelationship",
      details: "Fetch DataSync relationship",
      arguments: [("id", id), ("custom", requestConfig)]
    )

    let router = DataSyncRelationshipRouter(
      .fetch(id: id),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncRelationship>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Creates a relationship connecting two entities.
  ///
  /// - Parameters:
  ///   - relationshipClass: The name of the class to create the relationship in
  ///   - entityAId: The unique identifier of the entity on side A
  ///   - entityBId: The unique identifier of the entity on side B
  ///   - relationshipClassVersion: The version of the class the payload conforms to
  ///   - id: The unique identifier to create the relationship with, or `nil` to let the service assign one
  ///   - status: An arbitrary status to store with the relationship
  ///   - payload: The relationship fields
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The created ``PubNubDataSyncRelationship``
  ///     - **Failure**: An `Error` describing the failure
  func createRelationship(
    relationshipClass: String,
    entityAId: String,
    entityBId: String,
    relationshipClassVersion: Int,
    id: String? = nil,
    status: String? = nil,
    payload: JSONCodable? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncRelationship, Error>) -> Void)?
  ) {
    log(
      operation: "createRelationship",
      details: "Create DataSync relationship",
      arguments: [
        ("relationshipClass", relationshipClass),
        ("entityAId", entityAId),
        ("entityBId", entityBId),
        ("relationshipClassVersion", relationshipClassVersion),
        ("id", id),
        ("status", status),
        ("payload", payload),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncRelationshipRouter(
      .create(
        body: .init(
          id: id,
          entityAId: entityAId,
          entityBId: entityBId,
          relationshipClass: relationshipClass,
          relationshipClassVersion: relationshipClassVersion,
          status: status,
          payload: payload?.codableValue
        )
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncRelationship>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Replaces a relationship in full.
  ///
  /// Every mutable field is overwritten. Omitting `status` or `payload` clears the stored value rather than preserving it, so a read-modify-write
  /// must send back every field it wants to keep. Use ``updateRelationship(_:operations:ifMatchesEtag:custom:completion:)`` to change
  /// part of a relationship.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the relationship
  ///   - relationshipClassVersion: The version of the class the payload conforms to
  ///   - status: An arbitrary status to store with the relationship
  ///   - payload: The replacement relationship fields
  ///   - ifMatchesEtag: The ``PubNubDataSyncRelationship/eTag`` last read, to fail the request when it changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The replaced ``PubNubDataSyncRelationship``
  ///     - **Failure**: An `Error` describing the failure
  func setRelationship(
    _ id: String,
    relationshipClassVersion: Int,
    status: String? = nil,
    payload: JSONCodable? = nil,
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncRelationship, Error>) -> Void)?
  ) {
    log(
      operation: "setRelationship",
      details: "Replace DataSync relationship",
      arguments: [
        ("id", id),
        ("relationshipClassVersion", relationshipClassVersion),
        ("status", status),
        ("payload", payload),
        ("ifMatchesEtag", ifMatchesEtag),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncRelationshipRouter(
      .replace(
        id: id,
        body: .init(
          status: status,
          relationshipClassVersion: relationshipClassVersion,
          payload: payload?.codableValue
        ),
        ifMatch: ifMatchesEtag
      ),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncRelationship>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Applies a set of JSON Patch operations to a relationship.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the relationship
  ///   - operations: The RFC 6902 operations to apply, which must not be empty
  ///   - ifMatchesEtag: The ``PubNubDataSyncRelationship/eTag`` last read, to fail the request when it changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The patched ``PubNubDataSyncRelationship``
  ///     - **Failure**: An `Error` describing the failure
  func updateRelationship(
    _ id: String,
    operations: [PubNubDataSyncPatchOperation],
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<PubNubDataSyncRelationship, Error>) -> Void)?
  ) {
    log(
      operation: "updateRelationship",
      details: "Patch DataSync relationship",
      arguments: [
        ("id", id),
        ("operations", operations),
        ("ifMatchesEtag", ifMatchesEtag),
        ("custom", requestConfig)
      ]
    )

    let router = DataSyncRelationshipRouter(
      .patch(id: id, operations: operations.map { $0.patchOperation }, ifMatch: ifMatchesEtag),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncSingleValueResponseDecoder<PubNubDataSyncRelationship>(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.data })
    }
  }

  /// Removes a relationship.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the relationship
  ///   - ifMatchesEtag: The ``PubNubDataSyncRelationship/eTag`` last read, to fail the request when it changed since
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: An acknowledgement that the relationship was removed
  ///     - **Failure**: An `Error` describing the failure
  func removeRelationship(
    _ id: String,
    ifMatchesEtag: String? = nil,
    custom requestConfig: PubNub.RequestConfiguration = PubNub.RequestConfiguration(),
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    log(
      operation: "removeRelationship",
      details: "Remove DataSync relationship",
      arguments: [("id", id), ("ifMatchesEtag", ifMatchesEtag), ("custom", requestConfig)]
    )

    let router = DataSyncRelationshipRouter(
      .remove(id: id, ifMatch: ifMatchesEtag),
      configuration: configuration(from: requestConfig)
    )

    route(
      router,
      responseDecoder: DataSyncStatusResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { _ in () })
    }
  }
}

// MARK: - Shared

extension PubNub.DataSyncAPI {
  func configuration(from requestConfig: PubNub.RequestConfiguration) -> RouterConfiguration {
    requestConfig.customConfiguration ?? pubnub.configuration
  }

  func log(operation: String, details: String, arguments: [(String, Any?)]) {
    pubnub.logger.debug(
      .customObject(.init(operation: operation, details: details, arguments: arguments)),
      category: .pubNub
    )
  }

  func route<Decoder: ResponseDecoder>(
    _ router: HTTPRouter,
    responseDecoder: Decoder,
    custom requestConfig: PubNub.RequestConfiguration,
    completion: @escaping (Result<EndpointResponse<Decoder.Payload>, Error>) -> Void
  ) {
    pubnub.route(
      router,
      responseDecoder: responseDecoder,
      custom: requestConfig,
      completion: completion
    )
  }
}

// swiftlint:disable:this file_length
