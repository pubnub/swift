//
//  Patcher+PubNubUser.swift
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

public extension PubNubUser {
  /// Object that can be used to apply an update to another User
  struct Patcher {
    /// The unique identifier of the object that was changed
    public let id: String
    /// The name of the User
    public let name: OptionalChange<String>
    /// The classification of User
    public let type: OptionalChange<String>
    /// The current state of the User
    public let status: OptionalChange<String>
    /// The external identifier for the User
    public let externalId: OptionalChange<String>
    /// The profile URL for the User
    public let profileURL: OptionalChange<URL>
    /// The email address of the User
    public let email: OptionalChange<String>
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
      externalId: OptionalChange<String> = .noChange,
      profileURL: OptionalChange<URL> = .noChange,
      email: OptionalChange<String> = .noChange,
      custom: OptionalChange<FlatJSONCodable> = .noChange
    ) {
      self.id = id
      self.updated = updated
      self.eTag = eTag
      self.name = name
      self.type = type
      self.status = status
      self.externalId = externalId
      self.profileURL = profileURL
      self.email = email
      self.custom = custom
    }

    /// Apply the patch to a target User
    ///
    /// It's recommended to call ``shouldUpdate(userId:eTag:lastUpdated:)`` prior to using this method to ensure
    /// that the Patcher is valid for a given target User.
    /// - Parameters:
    ///   - name: Closure that will be called if the ``PubNubUser/name`` property should be updated
    ///   - type: Closure that will be called if the ``PubNubUser/type`` property should be updated
    ///   - status: Closure that will be called if the ``PubNubUser/status`` property should be updated
    ///   - externalId: Closure that will be called if the ``PubNubUser/externalId`` property should be updated
    ///   - profileURL: Closure that will be called if the ``PubNubUser/profileURL`` property should be updated
    ///   - email: Closure that will be called if the ``PubNubUser/email`` property should be updated
    ///   - custom: Closure that will be called if the ``PubNubUser/custom`` property should be updated
    ///   - updated: Closure that will be called if the ``PubNubUser/updated`` property should be updated
    ///   - eTag: Closure that will be called if the ``PubNubUser/eTag`` property should be updated
    public func apply(
      name: ((String?) -> Void) = { _ in },
      type: ((String?) -> Void) = { _ in },
      status: ((String?) -> Void) = { _ in },
      externalId: ((String?) -> Void) = { _ in },
      profileURL: ((URL?) -> Void) = { _ in },
      email: ((String?) -> Void) = { _ in },
      custom: ((FlatJSONCodable?) -> Void) = { _ in },
      updated: ((Date) -> Void),
      eTag: ((String) -> Void)
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
      if self.externalId.hasChange {
        externalId(self.externalId.underlying)
      }
      if self.profileURL.hasChange {
        profileURL(self.profileURL.underlying)
      }
      if self.email.hasChange {
        email(self.email.underlying)
      }
      if self.custom.hasChange {
        custom(self.custom.underlying)
      }
      updated(self.updated)
      eTag(self.eTag)
    }

    /// Should this patch update the target object.
    ///
    /// - Parameters:
    ///   - userId: The unique identifier of the target User
    ///   - eTag: The caching value of the target User.  This is set by the PubNub server
    ///   - lastUpdated: The updated `Date` for the target User.  This is set by the PubNub server.
    ///  - Returns:Whether the target User should be patched
    public func shouldUpdate(userId: String, eTag: String?, lastUpdated: Date?) -> Bool {
      return self.id == userId &&
        self.eTag != eTag &&
        updated.timeIntervalSince(lastUpdated ?? Date.distantPast) > 0
    }
  }
}

public extension PubNubUser {
  /// Attempt to apply the updates from a ``Patcher`` to this `PubNubUser`
  ///
  /// This will also validate that the ``Patcher`` should be applied to this User
  /// - Parameter patch: ``Patcher`` that will attempt to be applied
  /// - returns: An updated `PubNubUser` with the patched values, or the same object if no patch was applied.
  func apply(_ patch: PubNubUser.Patcher) -> PubNubUser {
    guard patch.shouldUpdate(userId: id, eTag: eTag, lastUpdated: updated) else {
      return self
    }

    var mutableSelf = self

    patch.apply(
      name: { mutableSelf.name = $0 },
      type: { mutableSelf.type = $0 },
      status: { mutableSelf.status = $0 },
      externalId: { mutableSelf.externalId = $0 },
      profileURL: { mutableSelf.profileURL = $0 },
      email: { mutableSelf.email = $0 },
      custom: { mutableSelf.custom = $0 },
      updated: { mutableSelf.updated = $0 },
      eTag: { mutableSelf.eTag = $0 }
    )

    return mutableSelf
  }
}

// MARK: Codable

extension PubNubUser.Patcher: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: PubNubUser.CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    updated = try container.decode(Date.self, forKey: .updated)
    eTag = try container.decode(String.self, forKey: .eTag)

    // Change Options
    if container.contains(.name) {
      name = try container.decode(OptionalChange<String>.self, forKey: .name)
    } else {
      name = .noChange
    }

    if container.contains(.type) {
      type = try container.decode(OptionalChange<String>.self, forKey: .type)
    } else {
      type = .noChange
    }

    if container.contains(.status) {
      status = try container.decode(OptionalChange<String>.self, forKey: .status)
    } else {
      status = .noChange
    }

    if container.contains(.externalId) {
      externalId = try container.decode(OptionalChange<String>.self, forKey: .externalId)
    } else {
      externalId = .noChange
    }

    if container.contains(.profileUrl) {
      if let url = try container.decodeIfPresent(String.self, forKey: .profileUrl),
         let profileURL = URL(string: url) {
        self.profileURL = .some(profileURL)
      } else {
        profileURL = .none
      }
    } else {
      profileURL = .noChange
    }

    if container.contains(.email) {
      email = try container.decode(OptionalChange<String>.self, forKey: .email)
    } else {
      email = .noChange
    }

    if container.contains(.custom) {
      if let custom = try container.decodeIfPresent([String: JSONCodableScalarType].self, forKey: .custom) {
        self.custom = .some(FlatJSON(flatJSON: custom))
      } else {
        custom = .none
      }
    } else {
      custom = .noChange
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: PubNubUser.CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)

    try container.encode(name, forKey: .name)
    try container.encode(type, forKey: .type)
    try container.encode(status, forKey: .status)

    try container.encode(externalId, forKey: .externalId)
    try container.encode(email, forKey: .email)

    switch profileURL {
    case .noChange:
      // no-op
      break
    case .none:
      try container.encodeNil(forKey: .profileUrl)
    case let .some(value):
      try container.encode(value.absoluteString, forKey: .profileUrl)
    }

    switch custom {
    case .noChange:
      // no-op
      break
    case .none:
      try container.encodeNil(forKey: .custom)
    case let .some(value):
      try container.encode(value.codableValue, forKey: .custom)
    }
  }
}
