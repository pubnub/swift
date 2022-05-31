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

// MARK: - PAM Token

public struct PAMToken: Codable, Equatable, Hashable {
  public let version: Int
  public let timestamp: Int
  public let ttl: Int
  public let authorizedUUID: String?

  public let resources: PAMTokenResource
  public let patterns: PAMTokenResource

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
    case meta
    case signature = "sig"
  }

  static func token(from token: String) -> PAMToken? {
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

  internal static func process(_ token: Data) -> PAMToken? {
    do {
      return try CBORDecoder().decode(PAMToken.self, from: token)
    } catch {
      PubNub.log.error("PAM Token `\(token.hexEncodedString)` was not valid CBOR due to: \(error.localizedDescription)")
      return nil
    }
  }
}

public struct PAMTokenResource: Codable, Equatable, Hashable {
  public let channels: [String: PAMPermission]
  public let groups: [String: PAMPermission]
  public let uuids: [String: PAMPermission]

  enum CodingKeys: String, CodingKey {
    case channels = "chan"
    case groups = "grp"
    case uuids = "uuid"
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
  public static let get = PAMPermission(rawValue: 1 << 5) // 32
  public static let update = PAMPermission(rawValue: 1 << 6) // 64
  public static let join = PAMPermission(rawValue: 1 << 7) // 128

  public static let crud: PAMPermission = [
    PAMPermission.read, PAMPermission.write, PAMPermission.update, PAMPermission.delete
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
