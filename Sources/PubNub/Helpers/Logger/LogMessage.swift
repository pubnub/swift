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

// MARK: - Log Message Content

/// An enum representing different types of log message content
public enum LogMessageContent: JSONCodable, CustomStringConvertible {
  /// A simple text message
  case text(String)
  /// A network request
  case networkRequest(NetworkRequestContent)
  /// A network response
  case networkResponse(NetworkResponseContent)
  /// A method call
  case customObject(CustomObjectContent)

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
public class BaseLogMessage: LogMessage {
  public let timestamp: TimeInterval
  public let pubNubId: String
  public let logLevel: LogLevel
  public let location: String?
  public let type: String
  public let category: LogCategory
  public let message: LogMessageContent
  public let details: String?

  init(
    timestamp: TimeInterval = Date().timeIntervalSince1970,
    pubNubId: String,
    logLevel: LogLevel,
    category: LogCategory,
    location: String?,
    type: String,
    message: LogMessageContent,
    details: String? = nil
  ) {
    self.timestamp = timestamp
    self.pubNubId = pubNubId
    self.logLevel = logLevel
    self.category = category
    self.location = location
    self.type = type
    self.message = message
    self.details = details
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(timestamp, forKey: .timestamp)
    try container.encode(pubNubId, forKey: .pubNubId)
    try container.encode(logLevel, forKey: .logLevel)
    try container.encode(category, forKey: .category)
    try container.encode(location, forKey: .location)
    try container.encode(type, forKey: .type)
    try container.encode(message, forKey: .message)
    try container.encodeIfPresent(details, forKey: .details)
  }

  public var description: String {
    [timestamp.description, "PubNub-\(pubNubId)", logLevel.description, location ?? "", message.description].joined(separator: " ")
  }
}

// MARK: - NetworkRequestContent

/// A struct representing a network request
public struct NetworkRequestContent: JSONCodable, CustomStringConvertible, LogMessageConvertible {
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
  /// The form data of the network request
  var formData: [String: String]
  /// The body of the network request
  var body: String?
  /// The timeout of the network request
  var timeout: TimeInterval
  /// Additional details about the network request
  var details: String?
  /// Whether the network request was cancelled
  var isCancelled: Bool
  /// Whether the network request failed
  var isFailed: Bool

  init(
    origin: String,
    path: String,
    query: [String: String],
    method: String,
    headers: [String: String],
    formData: [String: String],
    body: Data?,
    timeout: TimeInterval,
    details: String?,
    isCancelled: Bool,
    isFailed: Bool
  ) {
    self.origin = origin
    self.path = path
    self.query = query
    self.method = method
    self.headers = headers
    self.formData = formData
    self.body = String(data: body ?? Data(), encoding: .utf8)
    self.timeout = timeout
    self.details = details
    self.isCancelled = isCancelled
    self.isFailed = isFailed
  }

  public var description: String {
    ""
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(self.origin, forKey: .origin)
    try container.encode(self.path, forKey: .path)
    try container.encode(self.query, forKey: .query)
    try container.encode(self.method, forKey: .method)
    try container.encode(self.headers, forKey: .headers)
    try container.encode(self.formData, forKey: .formData)
    try container.encode(self.body, forKey: .body)
    try container.encode(self.timeout, forKey: .timeout)
  }

  public func toLogMessage(pubNubId: String, logLevel: LogLevel, category: LogCategory, location: String?) -> LogMessage {
    NetworkLogMessage(
      pubNubId: pubNubId,
      logLevel: logLevel,
      category: category,
      location: location,
      type: "network-request",
      message: self,
      details: nil,
      isCancelled: isCancelled,
      isFailed: isFailed
    )
  }

  /// An internal class that extends the base log message class to add network request specific properties
  private class NetworkLogMessage: BaseLogMessage {
    let isCancelled: Bool
    let isFailed: Bool

    enum CodingKeys: String, CodingKey {
      case timestamp
      case pubNubId
      case logLevel
      case category
      case location
      case type
      case message
      case details
      case isCancelled = "cancelled"
      case isFailed = "failed"
    }

    init(
      timestamp: TimeInterval = Date().timeIntervalSince1970,
      pubNubId: String,
      logLevel: LogLevel,
      category: LogCategory,
      location: String?,
      type: String,
      message: NetworkRequestContent,
      details: String?,
      isCancelled: Bool,
      isFailed: Bool
    ) {
      self.isCancelled = isCancelled
      self.isFailed = isFailed

      super.init(
        timestamp: timestamp,
        pubNubId: pubNubId,
        logLevel: logLevel,
        category: category,
        location: location,
        type: type,
        message: .networkRequest(message),
        details: details
      )
    }

    public override func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)

      try container.encode(timestamp, forKey: .timestamp)
      try container.encode(pubNubId, forKey: .pubNubId)
      try container.encode(logLevel, forKey: .logLevel)
      try container.encode(category, forKey: .category)
      try container.encode(location, forKey: .location)
      try container.encode(type, forKey: .type)
      try container.encode(message, forKey: .message)
      try container.encodeIfPresent(details, forKey: .details)
      try container.encode(isCancelled, forKey: .isCancelled)
      try container.encode(isFailed, forKey: .isCancelled)
    }

    required init(from decoder: any Decoder) throws {
      fatalError("init(from:) has not been implemented")
    }
  }
}

// MARK: - NetworkResponseContent

/// A struct representing a network response
public struct NetworkResponseContent: JSONCodable, CustomStringConvertible, LogMessageConvertible {
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

  init(url: URL, status: Int, headers: [String: String], body: Data?, details: String?) {
    self.url = url.absoluteString
    self.status = status
    self.headers = headers
    self.body = String(data: body ?? Data(), encoding: .utf8)
    self.details = details
  }

  public var description: String {
    ""
  }

  public func toLogMessage(pubNubId: String, logLevel: LogLevel, category: LogCategory, location: String?) -> LogMessage {
    BaseLogMessage(
      pubNubId: pubNubId,
      logLevel: logLevel,
      category: category,
      location: location,
      type: "network-response",
      message: .networkResponse(self),
      details: details
    )
  }
}

// MARK: - MethodCallContent

/// A struct representing a method call
public struct CustomObjectContent: JSONCodable, CustomStringConvertible, LogMessageConvertible {
  /// The name of the operation
  var operation: String
  /// The arguments of the operation
  var arguments: [String: String]
  /// Additional details about the operation
  var details: String?

  init(operation: String, arguments: [String: Any], details: String?) {
    self.operation = operation
    self.arguments = arguments.mapValues { String(describing: $0) }
    self.details = details
  }

  public var description: String {
    ""
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(operation, forKey: .operation)
    try container.encode(arguments, forKey: .arguments)
  }

  public func toLogMessage(pubNubId: String, logLevel: LogLevel, category: LogCategory, location: String?) -> LogMessage {
    BaseLogMessage(
      pubNubId: pubNubId,
      logLevel: logLevel,
      category: category,
      location: location,
      type: "object",
      message: .customObject(self),
      details: details
    )
  }
}
