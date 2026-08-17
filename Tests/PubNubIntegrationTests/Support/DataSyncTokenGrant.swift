//
//  DataSyncTokenGrant.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import CommonCrypto
import Foundation
import PubNubSDK
import XCTest

// MARK: - Errors

enum DataSyncTokenGrantError: Error {
  case missingSecretKey
  case missingKeys
  case invalidRequestBody(Error)
  case bodyNotUTF8
  case invalidRequestURL
  case requestFailed(Error)
  case unexpectedStatusCode(Int, body: String)
  case malformedResponse(body: String)
  case timedOut
}

// MARK: - Token grant

enum DataSyncTokenGrant {
  private static let secretKeyEnvironmentKey = "PUBNUB_SECRET_KEY"
  private static let secretKeyInfoDictionaryKey = "PubNubSecretKey"
  private static let lock = NSLock()
  private static var cachedTokens: [String: String] = [:]

  fileprivate static let session = URLSession(configuration: .ephemeral)

  /// Returns the token authorizing `grant`, minting it on first use.
  static func token(
    for grant: DataSyncGrant,
    bundle: Bundle,
    timeout: TimeInterval = 10.0
  ) throws -> String {
    let keys = PubNubConfiguration(bundle: bundle)

    guard let publishKey = keys.publishKey, !publishKey.isEmpty, !keys.subscribeKey.isEmpty else {
      throw DataSyncTokenGrantError.missingKeys
    }
    guard let secretKey = secretKey(from: bundle) else {
      throw DataSyncTokenGrantError.missingSecretKey
    }

    let body = try grant.requestBody()
    let cacheKey = "\(keys.subscribeKey)|\(body)"

    lock.lock()
    defer { lock.unlock() }

    if let cached = cachedTokens[cacheKey] {
      return cached
    }

    let token = try requestToken(
      publishKey: publishKey,
      subscribeKey: keys.subscribeKey,
      secretKey: secretKey,
      origin: keys.origin,
      body: body,
      timeout: timeout
    )

    cachedTokens[cacheKey] = token

    return token
  }

  /// The secret key to sign grants with, or `nil` when none was supplied.
  static func secretKey(from bundle: Bundle) -> String? {
    if let key = ProcessInfo.processInfo.environment[secretKeyEnvironmentKey], !key.isEmpty {
      return key
    }
    guard let key = bundle.object(forInfoDictionaryKey: secretKeyInfoDictionaryKey) as? String, !key.isEmpty else {
      return nil
    }

    return key
  }
}

// MARK: - Request

private struct DataSyncGrantResponse: Decodable {
  struct Payload: Decodable {
    let token: String
  }

  let data: Payload
}

private extension DataSyncTokenGrant {
  static func requestToken(
    publishKey: String,
    subscribeKey: String,
    secretKey: String,
    origin: String,
    body: String,
    timeout: TimeInterval
  ) throws -> String {
    let query = encodedQuery(from: [
      ("timestamp", String(Int(Date().timeIntervalSince1970))),
      ("uuid", "\(Constants.prefix)token-grant")]
    )
    let signature = self.signature(
      publishKey: publishKey,
      secretKey: secretKey,
      path: "/v3/pam/\(subscribeKey)/grant",
      query: query,
      body: body
    )

    var components = URLComponents()
    components.scheme = "https"
    components.host = origin
    components.path = "/v3/pam/\(subscribeKey)/grant"
    components.percentEncodedQuery = "\(query)&signature=\(encoded(signature))"

    guard let url = components.url else {
      throw DataSyncTokenGrantError.invalidRequestURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = Data(body.utf8)

    return try send(request, timeout: timeout)
  }

  /// Sends `request` and blocks until it completes, returning the granted token.
  static func send(_ request: URLRequest, timeout: TimeInterval) throws -> String {
    let expect = XCTestExpectation(description: "Grant a DataSync PAM token")
    var outcome: Result<String, Error>?

    let task = session.dataTask(with: request) { data, response, error in
      outcome = Result { try token(data: data, response: response, error: error) }
      expect.fulfill()
    }
    task.resume()

    guard XCTWaiter.wait(for: [expect], timeout: timeout) == .completed, let outcome = outcome else {
      task.cancel(); throw DataSyncTokenGrantError.timedOut
    }

    return try outcome.get()
  }

  /// The token carried by a completed `dataTask` callback, or the reason there isn't one.
  static func token(data: Data?, response: URLResponse?, error: Error?) throws -> String {
    if let error = error {
      throw DataSyncTokenGrantError.requestFailed(error)
    }

    let data = data ?? Data()
    let bodyText = String(data: data, encoding: .utf8) ?? ""
    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

    guard 200 ..< 300 ~= statusCode else {
      throw DataSyncTokenGrantError.unexpectedStatusCode(statusCode, body: bodyText)
    }
    guard let grant = try? JSONDecoder().decode(DataSyncGrantResponse.self, from: data) else {
      throw DataSyncTokenGrantError.malformedResponse(body: bodyText)
    }

    return grant.data.token
  }
}

// MARK: - Signing

private extension DataSyncTokenGrant {
  /// The characters PAM leaves unescaped when canonicalizing a query value for a signature.
  static let unreservedCharacters: CharacterSet = {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-_.")
    return allowed
  }()

  /// The `v2` request signature: `v2.` followed by base64url-encoded HMAC-SHA256 of the request.
  static func signature(
    publishKey: String,
    secretKey: String,
    path: String,
    query: String,
    body: String
  ) -> String {
    let input = "POST\n\(publishKey)\n\(path)\n\(query)\n\(body)"
    let encodedDigest = hmacSHA256(message: Data(input.utf8), key: Data(secretKey.utf8))
      .base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")

    return "v2.\(encodedDigest)"
  }

  static func hmacSHA256(message: Data, key: Data) -> Data {
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

    key.withUnsafeBytes { keyBytes in
      message.withUnsafeBytes { messageBytes in
        CCHmac(
          CCHmacAlgorithm(kCCHmacAlgSHA256),
          keyBytes.baseAddress,
          key.count,
          messageBytes.baseAddress,
          message.count,
          &digest
        )
      }
    }

    return Data(digest)
  }

  /// Query parameters sorted by name and percent-encoded, as PAM expects them when signing.
  static func encodedQuery(from items: [(name: String, value: String)]) -> String {
    items
      .sorted { $0.name < $1.name }
      .map { "\($0.name)=\(encoded($0.value))" }
      .joined(separator: "&")
  }

  static func encoded(_ value: String) -> String {
    value.addingPercentEncoding(withAllowedCharacters: unreservedCharacters) ?? value
  }
}
