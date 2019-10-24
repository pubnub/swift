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
public struct IdentifierEvent: Codable, Hashable {
  /// The unique identifier for the event
  public let id: String
}

// MARK: - User Events

/// An event that made changes to a User object
public typealias UserEvent = UpdatableUser

/// All the changes that can be received for User objects
public enum UserEvents {
  /// A User object has been updated
  case updated(UserEvent)
  /// The ID of the User object that was deleted
  case deleted(IdentifierEvent)
}

// MARK: - Space Events

/// An event that made changes to a Space object
public typealias SpaceEvent = UpdatableSpace

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

/// A way to uniquely identify a Membership between a User and a Space
public protocol MembershipIdentifiable {
  /// The unique identifier of the User object
  var userId: String { get }
  /// The unique identifier of the Space object
  var spaceId: String { get }
}

/// An event to alert the changes made to a Membership between a User and a Space
public struct MembershipEvent: MembershipIdentifiable, Codable, Hashable {
  /// Unique identifier of the User object
  public let userId: String
  /// Unique identifier of the Space object
  public let spaceId: String
  /// Custom data contained in the Membership
  public let custom: [String: JSONCodableScalarType]
  /// Date the Membership was last updated
  public let updated: Date
  /// The unique cache key used to evaluate if a change has occurred with this object
  public let eTag: String

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    userId = try container.decode(String.self, forKey: .userId)
    spaceId = try container.decode(String.self, forKey: .spaceId)
    custom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom) ?? [:]
    updated = try container.decodeIfPresent(Date.self, forKey: .updated) ?? Date.distantPast
    eTag = try container.decodeIfPresent(String.self, forKey: .eTag) ?? ""
  }
}
