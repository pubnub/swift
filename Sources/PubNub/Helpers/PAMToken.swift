//
//  PAMToken.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - PAM Token

public struct PAMToken: Codable, Equatable, Hashable {
  public let version: Int
  public let timestamp: Int
  public let ttl: Int
  public let authorizedUUID: String?
  public let resources: PAMTokenResource
  public let patterns: PAMTokenResource
  /// Permissions granted on a whole resource type rather than on named resources.
  ///
  /// Empty when the token carries no category permissions.
  public let categories: PAMTokenCategory
  public let meta: [String: AnyJSON]
  public let signature: String

  public fileprivate(set) var rawValue: String = ""

  enum CodingKeys: String, CodingKey {
    case version = "v"
    case timestamp = "t"
    case ttl
    case authorizedUUID = "uuid"
    case resources = "res"
    case patterns = "pat"
    case categories = "cat"
    case meta
    case signature = "sig"
  }

  // Decodes each optional section through `decodeIfPresent` so that a token omitting any of them still
  // parses. Tokens only carry the sections that were granted, and new sections may be added over time,
  // so a missing key must not fail the whole token and cost the caller the permissions it does carry.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    version = try container.decode(Int.self, forKey: .version)
    timestamp = try container.decode(Int.self, forKey: .timestamp)
    ttl = try container.decode(Int.self, forKey: .ttl)
    signature = try container.decode(String.self, forKey: .signature)
    authorizedUUID = try container.decodeIfPresent(String.self, forKey: .authorizedUUID)
    resources = try container.decodeIfPresent(PAMTokenResource.self, forKey: .resources) ?? PAMTokenResource()
    patterns = try container.decodeIfPresent(PAMTokenResource.self, forKey: .patterns) ?? PAMTokenResource()
    categories = try container.decodeIfPresent(PAMTokenCategory.self, forKey: .categories) ?? PAMTokenCategory()
    meta = try container.decodeIfPresent([String: AnyJSON].self, forKey: .meta) ?? [:]
  }

  enum PAMTokenError: Error {
    case invalidEscapedToken
    case invalidBase64EncodedToken
    case invalidCBOR(Error)
  }

  static func token(from token: String) throws -> PAMToken {
    guard let unescapedToken = token.unescapedPAMToken else {
      throw PAMTokenError.invalidEscapedToken
    }
    guard let tokenData = Data(base64Encoded: unescapedToken) else {
      throw PAMTokenError.invalidBase64EncodedToken
    }

    do {
      return try CBORDecoder().decode(PAMToken.self, from: tokenData)
    } catch {
      throw PAMTokenError.invalidCBOR(error)
    }
  }
}

public struct PAMTokenResource: Codable, Equatable, Hashable {
  public let channels: [String: PAMPermission]
  public let groups: [String: PAMPermission]
  public let uuids: [String: PAMPermission]
  public let dataSyncEntities: [String: PAMPermission]
  public let dataSyncMemberships: [String: PAMPermission]
  public let dataSyncRelationships: [String: PAMPermission]

  enum CodingKeys: String, CodingKey {
    case channels = "chan"
    case groups = "grp"
    case uuids = "uuid"
    case dataSyncEntities = "datasync:entities"
    case dataSyncMemberships = "datasync:memberships"
    case dataSyncRelationships = "datasync:relationships"
  }

  init(
    channels: [String: PAMPermission] = [:],
    groups: [String: PAMPermission] = [:],
    uuids: [String: PAMPermission] = [:],
    dataSyncEntities: [String: PAMPermission] = [:],
    dataSyncMemberships: [String: PAMPermission] = [:],
    dataSyncRelationships: [String: PAMPermission] = [:]
  ) {
    self.channels = channels
    self.groups = groups
    self.uuids = uuids
    self.dataSyncEntities = dataSyncEntities
    self.dataSyncMemberships = dataSyncMemberships
    self.dataSyncRelationships = dataSyncRelationships
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    channels = try container.decodeIfPresent([String: PAMPermission].self, forKey: .channels) ?? [:]
    groups = try container.decodeIfPresent([String: PAMPermission].self, forKey: .groups) ?? [:]
    uuids = try container.decodeIfPresent([String: PAMPermission].self, forKey: .uuids) ?? [:]
    dataSyncEntities = try container.decodeIfPresent([String: PAMPermission].self, forKey: .dataSyncEntities) ?? [:]
    dataSyncMemberships = try container.decodeIfPresent([String: PAMPermission].self, forKey: .dataSyncMemberships) ?? [:]
    dataSyncRelationships = try container.decodeIfPresent([String: PAMPermission].self, forKey: .dataSyncRelationships) ?? [:]
  }
}

/// Permissions granted on an entire resource type, independent of the permissions granted on named
/// resources and patterns.
///
/// A category permission is not implied by, and does not imply, a permission on an individual resource
/// of the same type.
public struct PAMTokenCategory: Codable, Equatable, Hashable {
  /// Permissions granted on the channel type as a whole.
  public let channels: PAMPermission
  /// Permissions granted on the uuid type as a whole.
  public let uuids: PAMPermission

  enum CodingKeys: String, CodingKey {
    case channels = "chan"
    case uuids = "uuid"
  }

  init(channels: PAMPermission = .none, uuids: PAMPermission = .none) {
    self.channels = channels
    self.uuids = uuids
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    channels = try container.decodeIfPresent(PAMPermission.self, forKey: .channels) ?? .none
    uuids = try container.decodeIfPresent(PAMPermission.self, forKey: .uuids) ?? .none
  }
}

public struct PAMPermission: OptionSet, Codable, Equatable, Hashable {
  public let rawValue: UInt32

  // Reserved Prefix Types
  public static let none = PAMPermission(rawValue: 0 << 0)

  public static let read = PAMPermission(rawValue: 1 << 0) // 1
  public static let write = PAMPermission(rawValue: 1 << 1) // 2
  public static let manage = PAMPermission(rawValue: 1 << 2) // 4
  public static let delete = PAMPermission(rawValue: 1 << 3) // 8
  public static let create = PAMPermission(rawValue: 1 << 4) // 16
  public static let get = PAMPermission(rawValue: 1 << 5) // 32
  public static let update = PAMPermission(rawValue: 1 << 6) // 64
  public static let join = PAMPermission(rawValue: 1 << 7) // 128

  public static let crud: PAMPermission = [
    PAMPermission.read, PAMPermission.write, PAMPermission.create, PAMPermission.update, PAMPermission.delete
  ]
  public static let all: PAMPermission = [
    PAMPermission.get, PAMPermission.join, PAMPermission.crud, PAMPermission.manage
  ]

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }
}

extension PAMPermission: CustomStringConvertible {
  public var description: String {
    var perm = [String]()

    if self == .none {
      return "[none]"
    }
    if contains(.all) {
      return "[all]"
    }

    if contains(.read) {
      perm.append("read")
    }
    if contains(.write) {
      perm.append("write")
    }
    if contains(.manage) {
      perm.append("manage")
    }
    if contains(.delete) {
      perm.append("delete")
    }
    if contains(.create) {
      perm.append("create")
    }
    if contains(.get) {
      perm.append("get")
    }
    if contains(.update) {
      perm.append("update")
    }
    if contains(.join) {
      perm.append("join")
    }

    return perm.joined(separator: "|")
  }
}

extension String {
  var unescapedPAMToken: String? {
    return removingPercentEncoding?.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
  }
}

extension Data {
  var pamToken: PAMToken? {
    return nil
  }
}
