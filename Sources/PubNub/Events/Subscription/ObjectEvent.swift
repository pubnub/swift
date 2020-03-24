//
//  ObjectEvent.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

/// An event that contains a unique identifier
public typealias IdentifierEvent = SimpleIdentifiableObject

// MARK: - User Events

/// An event that made changes to a User object
public typealias UserEvent = UserPatch

public typealias UserPatch = ObjectPatch<UserChangeEvent>

public extension UserPatch {
  func update<T: PubNubUser>(_ user: T?) throws -> T? {
    if let pubnubUser = updatePatch(user) {
      return try T(from: pubnubUser)
    }

    return nil
  }
}

/// All the changes that can be received for User objects
public enum UserEvents {
  /// A User object has been updated
  case updated(UserEvent)
  /// The ID of the User object that was deleted
  case deleted(IdentifierEvent)
}

// MARK: - Space Events

/// An event that made changes to a Space object
public typealias SpaceEvent = SpacePatch

public typealias SpacePatch = ObjectPatch<SpaceChangeEvent>

public extension SpacePatch {
  func update<T: PubNubSpace>(_ space: T?) throws -> T? {
    if let pubnubSpace = updatePatch(space) {
      return try T(from: pubnubSpace)
    }

    return nil
  }
}

/// All the changes that can be received for Space objects
public enum SpaceEvents {
  /// A Space object has been updated
  case updated(SpaceEvent)
  /// The ID of the Space object that was deleted
  case deleted(IdentifierEvent)
}

// MARK: - Membership

/// All the changes that can be received for Membership objects
public enum MembershipEvents {
  /// The IDs of the User and Space whose membership was added
  case userAddedOnSpace(MembershipEvent)
  /// The IDs of the User and Space whose membership was updated
  case userUpdatedOnSpace(MembershipEvent)
  /// The IDs of the User and Space that have become separated
  case userDeletedFromSpace(MembershipIdentifiable)
}

/// Uniquely identifies a Membership between a User and a Space
public struct MembershipIdentifiable: Codable, Hashable {
  /// The unique identifier of the User object
  public let userId: String
  /// The unique identifier of the Space object
  public let spaceId: String

  public init(userId: String, spaceId: String) {
    self.userId = userId
    self.spaceId = spaceId
  }
}

/// An event to alert the changes made to a Membership between a User and a Space
public struct MembershipEvent: Codable, Equatable {
  /// Unique identifier of the User object
  public let userId: String
  /// Unique identifier of the Space object
  public let spaceId: String
  /// Custom data contained in the Membership
  public let custom: [String: JSONCodableScalar]?
  /// Date the Membership was created
  public let created: Date
  /// Date the Membership was last updated
  public let updated: Date
  /// The unique cache key used to evaluate if a change has occurred with this object
  public let eTag: String

  public init(
    userId: String,
    spaceId: String,
    custom: [String: JSONCodableScalar]?,
    created: Date = Date(),
    updated: Date? = nil,
    eTag: String
  ) {
    self.userId = userId
    self.spaceId = spaceId
    self.custom = custom
    self.created = created
    self.updated = updated ?? created
    self.eTag = eTag
  }

  enum CodingKeys: String, CodingKey {
    case userId
    case spaceId
    case custom
    case created
    case updated
    case eTag
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    userId = try container.decode(String.self, forKey: .userId)
    spaceId = try container.decode(String.self, forKey: .spaceId)
    custom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom)
    created = try container.decode(Date.self, forKey: .created)
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(userId, forKey: .userId)
    try container.encode(spaceId, forKey: .spaceId)
    try container.encodeIfPresent(custom?.mapValues { $0.codableValue }, forKey: .custom)
    try container.encode(created, forKey: .created)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)
  }

  public static func == (lhs: MembershipEvent, rhs: MembershipEvent) -> Bool {
    return lhs.userId == rhs.userId &&
      lhs.spaceId == rhs.spaceId &&
      lhs.created == lhs.created &&
      lhs.updated == rhs.updated &&
      lhs.eTag == rhs.eTag &&
      lhs.custom?.allSatisfy {
        rhs.custom?[$0]?.scalarValue == $1.scalarValue
      } ?? true
  }

  public var asMember: PubNubMember {
    return SpaceObjectMember(id: userId, custom: custom, user: nil,
                             created: created, updated: updated, eTag: eTag)
  }

  public var asMembership: PubNubMembership {
    return UserObjectMembership(id: spaceId, custom: custom, space: nil,
                                created: created, updated: updated, eTag: eTag)
  }
}
