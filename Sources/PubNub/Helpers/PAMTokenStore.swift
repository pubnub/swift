//
//  PAMTokenStore.swift
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

public struct PAMTokenManagementSystem {
  public enum Resource {
    case uuid
    case channel
  }

  // Resource stores
  internal var channels: [String: PAMToken]
  internal var uuids: [String: PAMToken]

  public init(uuids: [String: PAMToken] = [:], channels: [String: PAMToken] = [:]) {
    self.uuids = uuids
    self.channels = channels
  }

  public init(store: PAMTokenManagementSystem) {
    uuids = store.uuids
    channels = store.channels
  }

  /// Perfoms a lookup and returns a token for the specified resource type and ID
  /// - Parameters:
  ///   - for: The resource ID for which the token is to be retrieved.
  ///   - with: The resource type
  /// - Returns: The assigned PAMToken if one exists; otherwise `nil`
  ///
  /// If no token is found for the supplied resource type and ID,
  /// the TMS checks the resource stores in the following order: `User`, `Space`
  public func getToken(for identifier: String, with type: Resource? = nil) -> PAMToken? {
    switch type {
    case .uuid?:
      return uuids[identifier]
    case .channel?:
      return channels[identifier]
    default:
      return uuids[identifier] ?? channels[identifier]
    }
  }

  /// Returns the token(s) for the specified resource type.
  /// - Returns: A dictionary of resource identifiers mapped to their PAM token
  public func getTokens(by resource: Resource) -> PAMTokenStore {
    switch resource {
    case .uuid:
      return uuids
    case .channel:
      return channels
    }
  }

  /// Returns a map of all tokens stored by the token management system
  /// - Returns: A dictionary of resource types mapped to resource identifier/token pairs
  public func getAllTokens() -> [Resource: PAMTokenStore] {
    return [.uuid: uuids, .channel: channels]
  }

  /// Stores a single token in the Token Management System for use in API calls.
  /// - Parameter token: The token to add to the Token Management System.
  public mutating func set(token tokenString: String) {
    guard var token = process(tokenString) else {
      return
    }
    // Attach the original auth string for reuse on APIs
    token.rawValue = tokenString

    for uuid in token.resources.uuidObjects.keys {
      uuids[uuid] = token
    }

    for channel in token.resources.channelObjects.keys {
      channels[channel] = token
    }
  }

  /// Stores multiple tokens in the Token Management System for use in API calls.
  /// - Parameters:
  ///   - tokens: The list of tokens to add to the Token Management System.
  public mutating func set(tokens: [String]) {
    for token in tokens {
      set(token: token)
    }
  }

  internal func process(_ token: String) -> PAMToken? {
    guard let unescapedToken = token.unescapedPAMToken else {
      PubNub.log.warn("PAM Token `\(token)` was not able to be properly escaped.")
      return nil
    }

    guard let tokenData = Data(base64Encoded: unescapedToken) else {
      PubNub.log.warn("PAM Token `\(token)` was not a valid base64 encoded string")
      return nil
    }

    return process(tokenData)
  }

  internal func process(_ token: Data) -> PAMToken? {
    do {
      return try CBORDecoder().decode(PAMToken.self, from: token)
    } catch {
      PubNub.log.error("PAM Token `\(token.hexEncodedString)` was not valid CBOR due to: \(error.localizedDescription)")
      return nil
    }
  }
}

// MARK: - PAM Token

public struct PAMToken: Codable, Equatable, Hashable {
  public let version: Int
  public let timestamp: Int
  public let ttl: Int

  public let resources: PAMTokenResource
  public let patterns: PAMTokenResource

  public let meta: [String: AnyJSON]

  public let signature: String

  public fileprivate(set) var rawValue: String = ""

  enum CodingKeys: String, CodingKey {
    case version = "v"
    case timestamp = "t"
    case ttl
    case resources = "res"
    case patterns = "pat"
    case meta
    case signature = "sig"
  }
}

public struct PAMTokenResource: Codable, Equatable, Hashable {
  public let channels: [String: PAMPermission]
  public let groups: [String: PAMPermission]

  public let uuidObjects: [String: PAMPermission]
  public let channelObjects: [String: PAMPermission]

  enum CodingKeys: String, CodingKey {
    case channels = "chan"
    case groups = "grp"
    case uuidObjects = "usr"
    case channelObjects = "spc"
  }
}

public struct PAMPermission: OptionSet, Codable, Equatable, Hashable {
  public let rawValue: UInt32

  // Reserverd Prefix Types
  public static let none = PAMPermission(rawValue: 0 << 0)

  public static let read = PAMPermission(rawValue: 1 << 0) // 1
  public static let write = PAMPermission(rawValue: 1 << 1) // 2
  public static let manage = PAMPermission(rawValue: 1 << 2) // 4
  public static let delete = PAMPermission(rawValue: 1 << 3) // 8
  public static let create = PAMPermission(rawValue: 1 << 4) // 16

  public static let update: PAMPermission = [PAMPermission.read, PAMPermission.write]
  public static let crud: PAMPermission = [PAMPermission.create, PAMPermission.update, PAMPermission.delete]

  public static let all: PAMPermission = [PAMPermission.crud, PAMPermission.manage]

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
