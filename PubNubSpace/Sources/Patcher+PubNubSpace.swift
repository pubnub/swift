//
//  Patcher+PubNubSpace.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

import PubNub

public extension PubNubSpace {
  /// Object that can be used to apply an update to another Space
  struct Patcher {
    /// The unique identifier of the object that was changed
    public let id: String
    /// The name of the Space
    public let name: OptionalChange<String>
    /// The classification of Space
    public let type: OptionalChange<String>
    /// The current state of the Space
    public let status: OptionalChange<String>
    /// Text describing the purpose of the Space
    public let spaceDescription: OptionalChange<String>
    /// All custom fields set on the User
    public let custom: OptionalChange<FlatJSONCodable>
    /// The timestamp of the change
    public let updated: Date
    /// The cache identifier of the change
    public let eTag: String

    public init(
      id: String,
      updated: Date,
      eTag: String,
      name: OptionalChange<String> = .noChange,
      type: OptionalChange<String> = .noChange,
      status: OptionalChange<String> = .noChange,
      spaceDescription: OptionalChange<String> = .noChange,
      custom: OptionalChange<FlatJSONCodable> = .noChange
    ) {
      self.id = id
      self.updated = updated
      self.eTag = eTag
      self.name = name
      self.type = type
      self.status = status
      self.spaceDescription = spaceDescription
      self.custom = custom
    }

    /// Should this patch update the target object.
    ///
    /// - Parameters:
    ///   - spaceId: The unique identifier of the target Space
    ///   - eTag: The caching value of the target Space.  This is set by the PubNub server
    ///   - lastUpdated: The updated `Date` for the target Space.  This is set by the PubNub server.
    ///  - Returns:Whether the target Space should be patched
    public func shouldUpdate(spaceId: String, eTag: String?, lastUpdated: Date?) -> Bool {
      // eTag and lastUpdated are optionals to allow for patching to still occur on local
      // objects that haven't been synced with the server
      guard id == spaceId,
            self.eTag != eTag,
            updated.timeIntervalSince(lastUpdated ?? .distantPast) > 0 else {
        return false
      }

      return true
    }

    /// Apply the patch to a target Space
    ///
    /// It's recommended to call ``shouldUpdate(spaceId:eTag:lastUpdated:)`` prior to using this method to ensure
    /// that the Patcher is valid for a given target Space.
    /// - Parameters:
    ///   - name: Closure that will be called if the `space.name` should be updated
    ///   - type: Closure that will be called if the `space.type` should be updated
    ///   - status: Closure that will be called if the `space.status` should be updated
    ///   - description: Closure that will be called if the `space.spaceDescription` should be updated
    ///   - custom: Closure that will be called if the `space.custom` should be updated
    ///   - updated: Closure that will be called if the `space.updated` should be updated
    ///   - eTag: Closure that will be called if the `space.eTag` should be updated
    public func apply(
      name: (String?) -> Void,
      type: (String?) -> Void,
      status: (String?) -> Void,
      description: (String?) -> Void,
      custom: (FlatJSONCodable?) -> Void,
      updated: (Date) -> Void,
      eTag: (String) -> Void
    ) {
      if self.name.hasChange {
        name(self.name.underlying)
      }
      if self.type.hasChange {
        type(self.type.underlying)
      }
      if self.status.hasChange {
        status(self.status.underlying)
      }
      if spaceDescription.hasChange {
        description(spaceDescription.underlying)
      }
      if self.custom.hasChange {
        custom(self.custom.underlying)
      }
      updated(self.updated)
      eTag(self.eTag)
    }
  }
}

public extension PubNubSpace {
  /// Attempt to apply the updates from a ``Patcher`` to this `PubNubSpace`
  ///
  /// This will also validate that the ``Patcher`` should be applied to this Space
  /// - Parameter patch: ``Patcher`` that will attempt to be applied
  /// - returns: An updated `PubNubSpace` with the patched values, or the same object if no patch was applied.
  func apply(_ patch: PubNubSpace.Patcher) -> PubNubSpace {
    guard patch.shouldUpdate(spaceId: id, eTag: eTag, lastUpdated: updated) else {
      return self
    }

    var mutableSelf = self

    patch.apply(
      name: { mutableSelf.name = $0 },
      type: { mutableSelf.type = $0 },
      status: { mutableSelf.status = $0 },
      description: { mutableSelf.spaceDescription = $0 },
      custom: { mutableSelf.custom = $0 },
      updated: { mutableSelf.updated = $0 },
      eTag: { mutableSelf.eTag = $0 }
    )

    return mutableSelf
  }
}

// MARK: Hashable

extension PubNubSpace.Patcher: Hashable {
  public static func == (lhs: PubNubSpace.Patcher, rhs: PubNubSpace.Patcher) -> Bool {
    return lhs.id == rhs.id &&
      lhs.name == rhs.name &&
      lhs.type == rhs.type &&
      lhs.status == rhs.status &&
      lhs.spaceDescription == rhs.spaceDescription &&
      lhs.custom.underlying?.codableValue == rhs.custom.underlying?.codableValue &&
      lhs.updated == rhs.updated &&
      lhs.eTag == rhs.eTag
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
    hasher.combine(type)
    hasher.combine(status)
    hasher.combine(spaceDescription)
    hasher.combine(custom.underlying?.codableValue)
    hasher.combine(updated)
    hasher.combine(eTag)
  }
}

// MARK: Codable

extension PubNubSpace.Patcher: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: PubNubSpace.CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)

    // Change Options
    name = try container.decode(OptionalChange<String>.self, forKey: .name)
    type = try container.decode(OptionalChange<String>.self, forKey: .type)
    status = try container.decode(OptionalChange<String>.self, forKey: .status)
    spaceDescription = try container
      .decode(OptionalChange<String>.self, forKey: .spaceDescription)

    custom = try container
      .decode(OptionalChange<[String: JSONCodableScalarType]>.self, forKey: .custom)
      .mapValue { FlatJSON(flatJSON: $0) }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: PubNubSpace.CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)

    try container.encode(name, forKey: .name)
    try container.encode(type, forKey: .type)
    try container.encode(status, forKey: .status)
    try container.encode(spaceDescription, forKey: .spaceDescription)

    try container.encode(
      custom.mapValue { $0.codableValue }, forKey: .custom
    )
  }
}
