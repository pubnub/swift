//
//  StringConstants.swift
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

public enum Constant {
  static let presenceChannelSuffix: String = "-pnpres"

  static let operatingSystemName: String = {
    let osName: String = {
      #if os(iOS)
        return "iOS"
      #elseif os(watchOS)
        return "watchOS"
      #elseif os(tvOS)
        return "tvOS"
      #elseif os(macOS)
        return "macOS"
      #elseif os(Linux)
        return "Linux"
      #else
        return "Unknown"
      #endif
    }()

    return osName
  }()

  static let operatingSystemVersion: String = {
    let version = ProcessInfo.processInfo.operatingSystemVersion
    return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
  }()

  static let pubnubSwiftSDKName: String = "PubNubSwift"

  static let pubnubSwiftSDKVersion: String = "6.1.0"

  static let appBundleId: String = {
    if let info = Bundle.main.infoDictionary,
       let bundleId = info[kCFBundleIdentifierKey as String] as? String {
      return bundleId
    }

    return "<Unknown BundleID>"
  }()

  static let appVersion: String = {
    if let info = Bundle.main.infoDictionary,
       let bundleVersion = info["CFBundleShortVersionString"] as? String {
      return bundleVersion
    }

    return "?.?.?"
  }()

  static let pnSDKQueryParameterValue: String = "\(pubnubSwiftSDKName)-\(operatingSystemName)/\(pubnubSwiftSDKVersion)"

  static let pnSDKURLQueryItem: URLQueryItem = .init(name: "pnsdk", value: pnSDKQueryParameterValue)

  static let minimumSubscribeRequestTimeout: TimeInterval = 280

  static let positiveInfinty = "Infinity"

  static let negativeInfinty = "-Infinity"

  static let notANumber = "NaN"

  static let jsonNull = "\"null\""

  static let jsonNullObject = NSNull()

  public static let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dataDecodingStrategy = .base64
    decoder.dateDecodingStrategy = .custom { decoder -> Date in
      let container = try decoder.singleValueContainer()
      let dateString = try container.decode(String.self)

      let date = DateFormatter.iso8601.date(
        from: dateString
      ) ?? DateFormatter.iso8601_noMilliseconds.date(from: dateString)

      guard let decodedDate = date else {
        throw DecodingError.typeMismatch(
          Date.self, DecodingError.Context(codingPath: [], debugDescription: "String is not a valid Date")
        )
      }

      return decodedDate
    }
    decoder.nonConformingFloatDecodingStrategy = .convertFromString(
      positiveInfinity: positiveInfinty,
      negativeInfinity: negativeInfinty,
      nan: notANumber
    )
    return decoder
  }()

  public static let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dataEncodingStrategy = .base64
    encoder.dateEncodingStrategy = .formatted(DateFormatter.iso8601)
    encoder.nonConformingFloatEncodingStrategy = .convertToString(
      positiveInfinity: positiveInfinty,
      negativeInfinity: negativeInfinty,
      nan: notANumber
    )
    return encoder
  }()
}

// MARK: - Header Key/Values

public extension Constant {
  /// Produces a `Accept-Encoding` header according to
  /// [RFC7231 section 5.3.4](https://tools.ietf.org/html/rfc7231#section-5.3.4)
  static let acceptEncodingHeaderKey = "Accept-Encoding"

  /// The default `Accept-Encoding` used for PubNub requests
  static let defaultAcceptEncodingHeader: String = {
    let encodings: [String]
    // Brotli (br) support added in iOS 11 https://9to5mac.com/2017/06/21/apple-ios-11-beta-2/
    if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
      encodings = ["br", "gzip", "deflate"]
    } else {
      encodings = ["gzip", "deflate"]
    }
    return encodings.headerQualityEncoded
  }()

  /// Produces a `Content-Type` header according to
  /// [RFC7231 section 3.1.1.5](https://tools.ietf.org/html/rfc7231#section-3.1.1.5)
  static let contentTypeHeaderKey = "Content-Type"

  /// The default `Content-Type` used for PubNub requests
  static let defaultContentTypeHeader = "application/json; charset=UTF-8"

  /// Produces a `User-Agent` header according to
  /// [RFC7231 section 5.5.3](https://tools.ietf.org/html/rfc7231#section-5.5.3)
  static let userAgentHeaderKey = "User-Agent"

  internal static let defaultUserAgentHeader: String = {
    let userAgent: String = {
      let appNameVersion = "\(Constant.appBundleId)/\(Constant.appVersion)"

      let osNameVersion = "\(Constant.operatingSystemName) \(Constant.operatingSystemVersion)"

      let pubnubVersion = "\(Constant.pubnubSwiftSDKName)/\(Constant.pubnubSwiftSDKVersion)"

      return "\(appNameVersion) (\(osNameVersion)) \(pubnubVersion)"
    }()

    return userAgent
  }()
}
