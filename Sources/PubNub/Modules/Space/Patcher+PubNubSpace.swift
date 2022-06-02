//
//  Patcher+PubNubSpace.swift
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

public extension PubNubSpace {
  struct Patcher {
    /// The unique identifier of the object that was changed
    public let id: String

    /// The name of the Space
    public var name: OptionalChange<String>
    /// The classification of Space
    public var type: OptionalChange<String>
    /// The current state of the Space
    public var status: OptionalChange<String>
    /// Text describing the purpose of the Space
    public var spaceDescription: OptionalChange<String>
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

    public func shouldUpdate(id: String, eTag: String?, lastUpdated: Date?) -> Bool {
      return self.id == id &&
        self.eTag != eTag &&
        updated.timeIntervalSince(lastUpdated ?? Date.distantPast) > 0
    }

    public func applyTo(_ space: PubNubSpace) -> PubNubSpace {
      guard shouldUpdate(id: space.id, eTag: space.eTag, lastUpdated: space.updated) else {
        return space
      }

      // Create mutable copy
      var patchedSpace = space
      // Update common fields
      patchedSpace.updated = updated
      patchedSpace.eTag = eTag

      name.apply(&patchedSpace.name)
      type.apply(&patchedSpace.type)
      status.apply(&patchedSpace.status)
      spaceDescription.apply(&patchedSpace.spaceDescription)
      custom.apply(&patchedSpace.custom)

      return patchedSpace
    }

    public func apply(
      name: ((String?) -> Void) = { _ in },
      type: ((String?) -> Void) = { _ in },
      status: ((String?) -> Void) = { _ in },
      description: ((String?) -> Void) = { _ in },
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
  func apply(_ patch: PubNubSpace.Patcher) -> PubNubSpace {
    guard patch.shouldUpdate(id: id, eTag: eTag, lastUpdated: updated) else {
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

extension PubNubSpace.Patcher: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: PubNubSpace.CodingKeys.self)
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

    if container.contains(.spaceDescription) {
      spaceDescription = try container.decode(OptionalChange<String>.self, forKey: .spaceDescription)
    } else {
      spaceDescription = .noChange
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
    var container = encoder.container(keyedBy: PubNubSpace.CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(updated, forKey: .updated)
    try container.encode(eTag, forKey: .eTag)

    try container.encode(name, forKey: .name)
    try container.encode(type, forKey: .type)
    try container.encode(status, forKey: .status)
    try container.encode(spaceDescription, forKey: .spaceDescription)

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
