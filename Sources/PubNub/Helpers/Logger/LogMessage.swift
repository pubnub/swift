//
//  LogMessage.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Log Message

/// A protocol that defines a log message reported by the PubNub SDK
public protocol LogMessage: JSONCodable, CustomStringConvertible {
  /// The timestamp of the log message
  var timestamp: TimeInterval { get }
  /// The unique identifier of the PubNub instance that generated the log message
  var pubNubId: String { get }
  /// The log level of the log message
  var logLevel: LogLevel { get }
  /// Additional information about the log message
  var location: String? { get }
  /// The type of the log message
  var type: String { get }
  /// The category of the log message
  var category: LogCategory { get }
  /// The message of the log message
  var message: LogMessageContent { get }
  /// Additional details about the log message
  var details: String? { get }
}

// MARK: - LogMessageContent

/// An enum representing different types of log message content
public enum LogMessageContent: JSONCodable, CustomStringConvertible {
  /// A simple text message
  case text(String)
  /// A network request
  case networkRequest(NetworkRequest)
  /// A network response
  case networkResponse(NetworkResponse)
  /// A method call
  case customObject(CustomObject)

  public var description: String {
    switch self {
    case let .text(textValue):
      textValue
    case let .networkRequest(networkRequestContent):
      networkRequestContent.description
    case let .networkResponse(networkResponseContent):
      networkResponseContent.description
    case let .customObject(customObjectContent):
      customObjectContent.description
    }
  }
}

// MARK: - BaseLogMessage

/// A base implementation of the `LogMessage` protocol that all log messages inherit from
class BaseLogMessage: LogMessage {
  public let timestamp: TimeInterval
  public let pubNubId: String
  public let logLevel: LogLevel
  public let location: String?
  public let type: String
  public let category: LogCategory
  public let message: LogMessageContent
  public let details: String?
  public let additionalFields: [String: AnyJSON]

  enum DynamicCodingKeys: CodingKey {
    case timestamp
    case pubNubId
    case logLevel
    case category
    case location
    case type
    case message
    case details
    case dynamic(String)

    var stringValue: String {
      switch self {
      case .timestamp: return "timestamp"
      case .pubNubId: return "pubNubId"
      case .logLevel: return "logLevel"
      case .category: return "category"
      case .location: return "location"
      case .type: return "type"
      case .message: return "message"
      case .details: return "details"
      case .dynamic(let key): return key
      }
    }

    init?(stringValue: String) {
      switch stringValue {
      case "timestamp": self = .timestamp
      case "pubNubId": self = .pubNubId
      case "logLevel": self = .logLevel
      case "category": self = .category
      case "location": self = .location
      case "type": self = .type
      case "message": self = .message
      case "details": self = .details
      default: self = .dynamic(stringValue)
      }
    }

    var intValue: Int? { nil }
    init?(intValue: Int) { nil }
  }

  init(
    timestamp: TimeInterval = Date().timeIntervalSince1970,
    pubNubId: String,
    logLevel: LogLevel,
    category: LogCategory,
    location: String?,
    type: String,
    message: LogMessageContent,
    details: String?,
    additionalFields: [String: AnyJSON]
  ) {
    self.timestamp = timestamp
    self.pubNubId = pubNubId
    self.logLevel = logLevel
    self.category = category
    self.location = location
    self.type = type
    self.message = message
    self.details = details
    self.additionalFields = additionalFields
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: DynamicCodingKeys.self)

    try container.encode(timestamp, forKey: .timestamp)
    try container.encode(pubNubId, forKey: .pubNubId)
    try container.encode(logLevel, forKey: .logLevel)
    try container.encode(category, forKey: .category)
    try container.encode(location, forKey: .location)
    try container.encode(type, forKey: .type)
    try container.encode(message, forKey: .message)
    try container.encodeIfPresent(details, forKey: .details)

    // Encode additional fields using dynamic keys
    for (key, value) in additionalFields {
      try container.encode(value, forKey: .dynamic(key))
    }
  }

  public var description: String {
    [timestamp.description, "PubNub-\(pubNubId)", logLevel.description, location ?? "", message.description].joined(separator: " ")
  }
}

// MARK: - NetworkRequest

extension LogMessageContent {
  /// A struct representing a network request
  public struct NetworkRequest: JSONCodable, CustomStringConvertible, LogMessageConvertible {
    /// The unique identifier of the network request
    var id: String
    /// The origin of the network request
    var origin: String
    /// The path of the network request
    var path: String
    /// The query parameters of the network request
    var query: [String: String]
    /// The method of the network request
    var method: String
    /// The headers of the network request
    var headers: [String: String]
    /// The body of the network request
    var body: String?
    /// Additional details about the network request
    var details: String?
    /// Whether the network request was cancelled
    var isCancelled: Bool
    /// Whether the network request failed
    var isFailed: Bool

    init(
      id: String,
      origin: String,
      path: String,
      query: [String: String],
      method: String,
      headers: [String: String],
      body: Data?,
      details: String?,
      isCancelled: Bool,
      isFailed: Bool
    ) {
      self.id = id
      self.origin = origin
      self.path = path
      self.query = query
      self.method = method
      self.headers = headers
      self.details = details
      self.isCancelled = isCancelled
      self.isFailed = isFailed
      self.body = if let body {
        String(data: body, encoding: .utf8) ?? "Invalid UTF-8 encoded data"
      } else {
        "nil"
      }
    }

    public var description: String {
      let prefix = if isCancelled {
        "Cancelled network request"
      } else if isFailed {
        "Failed network request"
      } else {
        "Executing network request"
      }

      return String.formattedDescription(
        prefix,
        arguments: [
          ("id", id),
          ("origin", origin),
          ("path", path),
          ("method", method),
          ("headers", headers),
          ("body", body ?? "nil"),
          ("details", details ?? "nil"),
          ("isCancelled", isCancelled),
          ("isFailed", isFailed)
        ]
      )
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)

      try container.encode(self.id, forKey: .id)
      try container.encode(self.origin, forKey: .origin)
      try container.encode(self.path, forKey: .path)
      try container.encode(self.query, forKey: .query)
      try container.encode(self.method, forKey: .method)
      try container.encode(self.headers, forKey: .headers)
      try container.encode(self.body, forKey: .body)
    }

    public func toLogMessage(pubNubId: String, logLevel: LogLevel, category: LogCategory, location: String?) -> LogMessage {
      BaseLogMessage(
        pubNubId: pubNubId,
        logLevel: logLevel,
        category: category,
        location: location,
        type: "network-request",
        message: .networkRequest(self),
        details: nil,
        additionalFields: ["cancelled": AnyJSON(isCancelled), "failed": AnyJSON(isFailed)]
      )
    }
  }
}

// MARK: - NetworkResponse

extension LogMessageContent {
  /// A struct representing a network response
  public struct NetworkResponse: JSONCodable, CustomStringConvertible, LogMessageConvertible {
    /// The id of the network request that this response is associated with
    var id: String
    /// The URL of the network response
    var url: String
    /// The status code of the network response
    var status: Int
    /// The headers of the network response
    var headers: [String: String]
    /// The body of the network response
    var body: String?
    /// Additional details about the network response
    var details: String?

    init(id: String, url: URL?, status: Int, headers: [String: String], body: Data?, details: String?) {
      self.id = id
      self.url = url?.absoluteString ?? "Unknown URL"
      self.status = status
      self.headers = headers
      self.body = String(data: body ?? Data(), encoding: .utf8)
      self.details = details
    }

    public var description: String {
      String.formattedDescription(
        "Network response",
        arguments: [
          ("id", id),
          ("url", url),
          ("status", status),
          ("headers", headers),
          ("body", body ?? "nil"),
          ("details", details ?? "nil")
        ]
      )
    }

    public func toLogMessage(pubNubId: String, logLevel: LogLevel, category: LogCategory, location: String?) -> LogMessage {
      BaseLogMessage(
        pubNubId: pubNubId,
        logLevel: logLevel,
        category: category,
        location: location,
        type: "network-response",
        message: .networkResponse(self),
        details: details,
        additionalFields: [:]
      )
    }
  }
}

// MARK: - CustomObject

extension LogMessageContent {
  /// A struct representing a method call
  public struct CustomObject: JSONCodable, CustomStringConvertible, LogMessageConvertible {
    /// The name of the operation
    var operation: String
    /// The arguments of the operation
    var arguments: [(String, String)]
    /// Additional details about the operation
    var details: String?

    enum CodingKeys: String, CodingKey {
      case operation
      case arguments
      case details
    }

    init(operation: String = "", arguments: [(String, Any)] = [], details: String? = nil) {
      self.operation = operation
      self.arguments = arguments.map { ($0.0, String(describing: $0.1)) }
      self.details = details
    }

    public var description: String {
      if let details {
        return String.formattedDescription(details, arguments: arguments)
      } else {
        return String.formattedDescription("Custom object", arguments: arguments)
      }
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(operation, forKey: .operation)
      try container.encode(arguments.reduce(into: [String: String]()) { $0[$1.0] = $1.1 }, forKey: .arguments)
      try container.encode(details, forKey: .details)
    }

    public func toLogMessage(pubNubId: String, logLevel: LogLevel, category: LogCategory, location: String?) -> LogMessage {
      BaseLogMessage(
        pubNubId: pubNubId,
        logLevel: logLevel,
        category: category,
        location: location,
        type: "object",
        message: .customObject(self),
        details: details,
        additionalFields: [:]
      )
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      operation = try container.decode(String.self, forKey: .operation)
      arguments = try container.decode([String: String].self, forKey: .arguments).map { ($0.key, $0.value) }
      details = try container.decodeIfPresent(String.self, forKey: .details)
    }
  }
}
