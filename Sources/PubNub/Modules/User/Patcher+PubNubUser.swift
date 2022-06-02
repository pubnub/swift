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
  struct Patcher {
    /// The unique identifier of the object that was changed
    public let id: String
    /// The name of the User
    public var name: OptionalChange<String>
    /// The classification of User
    public var type: OptionalChange<String>
    /// The current state of the User
    public var status: OptionalChange<String>
    /// The external identifier for the User
    public var externalId: OptionalChange<String>
    /// The profile URL for the User
    public var profileURL: OptionalChange<URL>
    /// The email address of the User
    public var email: OptionalChange<String>
    /// All custom fields set on the User
    public var custom: OptionalChange<FlatJSONCodable>

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

    public func apply(
      name: ((String?) -> Void) = { _ in },
      type: ((String?) -> Void) = { _ in },
      status: ((String?) -> Void) = { _ in },
      externalId: ((String?) -> Void) = { _ in },
      profileURL: ((URL?) -> Void) = { _ in },
      email: ((String?) -> Void) = { _ in },
      custom: ((FlatJSONCodable?) -> Void) = { _ in },
      updated: ((Date) -> Void) = { _ in },
      eTag: ((String) -> Void) = { _ in }
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

    public func shouldUpdate(id: String, eTag: String?, lastUpdated: Date?) -> Bool {
      return self.id == id &&
        self.eTag != eTag &&
        updated.timeIntervalSince(lastUpdated ?? Date.distantPast) > 0
    }

    public func applyTo(_ user: PubNubUser) -> PubNubUser {
      guard shouldUpdate(id: user.id, eTag: user.eTag, lastUpdated: user.updated) else {
        return user
      }

      // Create mutable copy
      var patchedUser = user
      // Update common fields
      patchedUser.updated = updated
      patchedUser.eTag = eTag

      name.apply(&patchedUser.name)
      type.apply(&patchedUser.type)
      status.apply(&patchedUser.status)
      externalId.apply(&patchedUser.externalId)
      profileURL.apply(&patchedUser.profileURL)
      email.apply(&patchedUser.email)
      custom.apply(&patchedUser.custom)

      return patchedUser
    }
  }
}

public extension PubNubUser {
  func apply(_ patch: PubNubUser.Patcher) -> PubNubUser {
    guard patch.shouldUpdate(id: id, eTag: eTag, lastUpdated: updated) else {
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
