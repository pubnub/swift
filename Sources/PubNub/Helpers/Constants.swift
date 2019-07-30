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

public struct ErrorDescription {
  public struct AnyJSONError {
    public static let stringCreationFailure: String = {
      "`String(data:ecoding:)` returned nil when converting JSON Data to a `String`"
    }()
  }

  struct DecodingError {
    public static let invalidRootLevelErrorDescription: String = {
      "AnyJSON could not decode invalid root-level JSON object"
    }()

    public static let invalidKeyedContainerErrorDescription: String = {
      "AnyJSON could not decode value inside `KeyedDecodingContainer`"
    }()

    public static let invalidUnkeyedContainerErrorDescription: String = {
      "AnyJSON could not decode value inside `UnkeyedDecodingContainer`"
    }()
  }

  struct EncodingError {
    public static let invalidRootLevelErrorDescription: String = {
      "AnyJSON could not encode invalid root-level JSON object"
    }()

    public static let invalidKeyedContainerErrorDescription: String = {
      "AnyJSON could not encode value inside `KeyedEncodingContainer`"
    }()

    public static let invalidUnkeyedContainerErrorDescription: String = {
      "AnyJSON could not encode value inside `UnkeyedEncodingContainer`"
    }()
  }

  struct EndpointError {
    public static let publishResponseMessageParseFailure: String = {
      "Unable to parse publish payload message"
    }()

    public static let missingResponseData: String = {
      "Missing Response Data"
    }()
  }
}

struct Constant {
  public static let operatingSystemName: String = {
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

  public static let operatingSystemVersion: String = {
    let version = ProcessInfo.processInfo.operatingSystemVersion
    return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
  }()

  public static let pubnubSwiftSDKName: String = {
    "PubNubSwift"
  }()

  public static let pubnubSwiftSDKVersion: String = {
    guard let pubnubInfo = Bundle(for: Session.self).infoDictionary,
      let build = pubnubInfo["CFBundleShortVersionString"] else {
      return "?.?.?"
    }

    return "\(build)"
  }()

  public static let appBundleId: String = {
    if let info = Bundle.main.infoDictionary,
      let bundleId = info[kCFBundleIdentifierKey as String] as? String {
      return bundleId
    }

    return "<Uknown BundleID>"
  }()

  public static let appVersion: String = {
    if let info = Bundle.main.infoDictionary,
      let bundleVersion = info["CFBundleShortVersionString"] as? String {
      return bundleVersion
    }

    return "?.?.?"
  }()

  public static let pnSDKQueryParameterValue: String = {
    "\(pubnubSwiftSDKName)-\(operatingSystemName)/\(pubnubSwiftSDKVersion)"
  }()

  public static let defaultUserAgent: String = {
    let userAgent: String = {
      let appNameVersion: String = {
        "\(Constant.appBundleId)/\(Constant.appVersion)"
      }()

      let osNameVersion: String = {
        "\(Constant.operatingSystemName) \(Constant.operatingSystemVersion)"
      }()

      let pubnubVersion: String = {
        "\(Constant.pubnubSwiftSDKName)/\(Constant.pubnubSwiftSDKVersion)"
      }()

      return "\(appNameVersion) (\(osNameVersion)) \(pubnubVersion)"
    }()

    return userAgent
  }()

  static let minimumSubscribeRequestTimeout: TimeInterval = {
    280
  }()

  public static let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dataDecodingStrategy = .deferredToData
    decoder.dateDecodingStrategy = .deferredToDate
    return decoder
  }()

  public static let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .deferredToDate
    encoder.dataEncodingStrategy = .deferredToData
    return encoder
  }()
}
