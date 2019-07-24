//
//  EndpointErrorPayload.swift
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
// swiftlint:disable discouraged_optional_boolean

import Foundation

public struct EndpointErrorPayload: Codable {
  public enum Message: RawRepresentable, Codable {
    case couldNotParseRequest
    case invalidSubscribeKey
    case invalidPublishKey
    case notFound(resource: String)
    case requestURITooLong
    case unknown(message: String)

    public init(rawValue: String) {
      switch rawValue {
      case "Could Not Parse Request":
        self = .couldNotParseRequest
      case "Invalid Subscribe Key":
        self = .invalidSubscribeKey
      case "Invalid Key":
        self = .invalidPublishKey
      case "Request URI Too Long":
        self = .requestURITooLong
      default:
        if rawValue.starts(with: "Not Found "),
          let range = rawValue.range(of: "Not Found ") {
          self = .notFound(resource: String(rawValue[range.upperBound...]))
        }

        self = .unknown(message: rawValue)
      }
    }

    public var rawValue: String {
      switch self {
      case .couldNotParseRequest:
        return "Could Not Parse Request"
      case .invalidSubscribeKey:
        return "Invalid Subscribe Key"
      case .invalidPublishKey:
        return "Invalid Publish Key"
      case let .notFound(resource):
        return "Resource Not Found: \(resource)"
      case .requestURITooLong:
        return "Request URI Too Long"
      case let .unknown(message):
        return "Unknown: \(message)"
      }
    }
  }

  public enum Service: RawRepresentable, Codable {
    case accessManager
    case balancer
    case presence
    case unknown(message: String)

    public init(rawValue: String) {
      switch rawValue {
      case "Access Manager":
        self = .accessManager
      case "Balancer":
        self = .balancer
      case "Presence":
        self = .presence
      default:
        self = .unknown(message: rawValue)
      }
    }

    public var rawValue: String {
      switch self {
      case .accessManager:
        return "Access Manager"
      case .balancer:
        return "Balancer"
      case .presence:
        return "Presence"
      case let .unknown(message):
        return "Unknown: \(message)"
      }
    }
  }

  public enum Code: RawRepresentable, Codable {
    case badRequest
    case forbidden
    case notFound
    case uriTooLong
    case unknown(code: Int)

    public init(rawValue: Int) {
      switch rawValue {
      case 400:
        self = .badRequest
      case 403:
        self = .forbidden
      case 404:
        self = .notFound
      case 414:
        self = .uriTooLong
      default:
        self = .unknown(code: rawValue)
      }
    }

    public var rawValue: Int {
      switch self {
      case .badRequest:
        return 400
      case .forbidden:
        return 403
      case .notFound:
        return 404
      case .uriTooLong:
        return 414
      case let .unknown(code):
        return code
      }
    }
  }

  public let message: Message
  public let service: Service
  public let status: Code?
  public let error: Bool?
}

// swiftlint:enable discouraged_optional_boolean
