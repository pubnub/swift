//
//  PubNubLogger.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// Represents the various details that can be included in a log message
public struct LogPrefix: OptionSet, Equatable, Hashable {
  public let rawValue: UInt32

  // Reserverd Prefix Types
  public static let none = LogPrefix([])
  public static let level = LogPrefix(rawValue: 1 << 0)
  public static let date = LogPrefix(rawValue: 1 << 1)
  public static let queue = LogPrefix(rawValue: 1 << 2)
  public static let thread = LogPrefix(rawValue: 1 << 3)
  public static let file = LogPrefix(rawValue: 1 << 4)
  public static let function = LogPrefix(rawValue: 1 << 5)
  public static let line = LogPrefix(rawValue: 1 << 6)
  public static let category = LogPrefix(rawValue: 1 << 7)
  public static let all = LogPrefix(rawValue: UInt32.max)

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }
}

// MARK: - Level

/// Represents different levels of logging, such as debug, info, warning, etc.
public struct LogLevel: OptionSet, Equatable, Hashable, JSONCodable {
  public let rawValue: UInt32

  // Reserverd Log Types
  public static let none = LogLevel([])
  public static let debug = LogLevel(rawValue: 1 << 0)
  public static let info = LogLevel(rawValue: 1 << 1)
  public static let event = LogLevel(rawValue: 1 << 2)
  public static let warn = LogLevel(rawValue: 1 << 3)
  public static let error = LogLevel(rawValue: 1 << 4)
  public static let log = LogLevel(rawValue: 1 << 31)
  public static let all = LogLevel(rawValue: UInt32.max)

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }
}

extension LogLevel: CustomStringConvertible {
  public var description: String {
    switch self {
    case LogLevel.debug:
      return "Debug"
    case LogLevel.info:
      return "Info"
    case LogLevel.event:
      return "Event"
    case LogLevel.warn:
      return "Warn"
    case LogLevel.error:
      return "Error"
    case LogLevel.log:
      return "Logger Event"
    case LogLevel.all:
      return "All"
    default:
      return "Custom"
    }
  }
}

// MARK: - PubNub Logger

/// Provides a custom logger for handling log messages from the PubNub SDK.
public struct PubNubLogger {
  /// An array of `LogWriter` instances responsible for processing log messages.
  public var writers: [LogWriter]
  /// The current log level, determining the severity of messages to be logged.
  public var levels: LogLevel
  /// A unique identifier for the PubNub instance this logger is associated with
  private var pubNubInstanceId: UUID?

  public init(levels: LogLevel = .all, writers: [LogWriter]) {
    self.writers = writers
    self.levels = levels
  }

  init(levels: LogLevel = .all, writers: [LogWriter], pubNubInstanceId: UUID) {
    self.writers = writers
    self.levels = levels
    self.pubNubInstanceId = pubNubInstanceId
  }

  func clone(withPubNubInstanceId id: UUID) -> PubNubLogger {
    PubNubLogger(levels: levels, writers: writers, pubNubInstanceId: id)
  }

  /// Returns a default logger for the SDK
  public static func defaultLogger() -> PubNubLogger {
    if #available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *) {
      return PubNubLogger(levels: [.event, .warn, .error], writers: [OSLogWriter()])
    } else {
      return PubNubLogger(levels: [.event, .warn, .error], writers: [ConsoleLogWriter(), FileLogWriter()])
    }
  }

  /// Returns a default log writer for console output
  static func consoleOutputWriter() -> LogWriter {
    if #available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *) {
      return OSLogWriter()
    } else {
      return ConsoleLogWriter()
    }
  }

  public func debug(
    _ message: @escaping @autoclosure () -> LogMessageConvertible,
    category: LogCategory = .none,
    date: Date = Date(),
    queue: String = DispatchQueue.currentLabel,
    thread: String = Thread.currentName,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    send(
      .debug,
      category: category,
      message: message(),
      date: date,
      queue: queue,
      thread: thread,
      file: file,
      function: function,
      line: line
    )
  }

  public func info(
    _ message: @escaping @autoclosure () -> LogMessageConvertible,
    category: LogCategory = .none,
    date: Date = Date(),
    queue: String = DispatchQueue.currentLabel,
    thread: String = Thread.currentName,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    send(
      .info,
      category: category,
      message: message(),
      date: date,
      queue: queue,
      thread: thread,
      file: file,
      function: function,
      line: line
    )
  }

  public func event(
    _ message: @escaping @autoclosure () -> LogMessageConvertible,
    category: LogCategory = .none,
    date: Date = Date(),
    queue: String = DispatchQueue.currentLabel,
    thread: String = Thread.currentName,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    send(
      .event,
      category: category,
      message: message(),
      date: date,
      queue: queue,
      thread: thread,
      file: file,
      function: function,
      line: line
    )
  }

  public func warn(
    _ message: @escaping @autoclosure () -> LogMessageConvertible,
    category: LogCategory = .none,
    date: Date = Date(),
    queue: String = DispatchQueue.currentLabel,
    thread: String = Thread.currentName,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    send(
      .warn,
      message: message(),
      date: date,
      queue: queue,
      thread: thread,
      file: file,
      function: function,
      line: line
    )
  }

  public func error(
    _ message: @escaping @autoclosure () -> LogMessageConvertible,
    category: LogCategory = .none,
    date: Date = Date(),
    queue: String = DispatchQueue.currentLabel,
    thread: String = Thread.currentName,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    send(
      .error,
      category: category,
      message: message(),
      date: date,
      queue: queue,
      thread: thread,
      file: file,
      function: function,
      line: line
    )
  }

  public func custom(
    _ level: LogLevel,
    _ message: @escaping @autoclosure () -> LogMessageConvertible,
    category: LogCategory = .none,
    date: Date = Date(),
    queue: String = DispatchQueue.currentLabel,
    thread: String = Thread.currentName,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    send(
      level,
      category: category,
      message: message(),
      date: date,
      queue: queue,
      thread: thread,
      file: file,
      function: function,
      line: line
    )
  }

  public func format(
    prefix: LogPrefix,
    category: LogCategory,
    level: LogLevel,
    date: Date,
    queue: String,
    thread: String,
    file: String,
    function: String,
    line: Int
  ) -> String {
    var prefixString = ""

    if prefix == .none {
      return prefixString
    }
    if prefix.contains(.queue) || prefix.contains(.thread) {
      prefixString = "\(queue)#\(thread)"
    }
    if prefix.contains(.file) || prefix.contains(.function) || prefix.contains(.line) {
      prefixString = "\(prefixString + (prefixString.isEmpty ? "" : " "))\(file.fileNameWithExtension):\(line) \(function)"
    }

    return "\(prefixString.trimmingCharacters(in: CharacterSet(arrayLiteral: " ")))"
  }

  // swiftlint:disable:next function_parameter_count
  public func send(
    _ level: LogLevel,
    category: LogCategory = .none,
    message: @escaping @autoclosure () -> LogMessageConvertible,
    date: Date,
    queue: String,
    thread: String,
    file: String,
    function: String,
    line: Int
  ) {
    guard enabled, levels.contains(level) else {
      return
    }

    for writer in writers {
      var fullMessage = {
        let additionalDetails = format(
          prefix: writer.prefix,
          category: category,
          level: level,
          date: date,
          queue: queue,
          thread: thread,
          file: file,
          function: function,
          line: line
        )
        let finalMessage = message().toLogMessage(
          pubNubId: pubNubInstanceId?.uuidString ?? "",
          logLevel: level,
          category: category,
          location: additionalDetails
        )
        return finalMessage
      }

      writer.executor.execute {
        writer.send(
          message: fullMessage(),
          level: level,
          category: category
        )
      }

      fullMessage = {
        BaseLogMessage(
          pubNubId: "",
          logLevel: .debug,
          category: .none,
          type: "",
          message: ""
        )
      }
    }
  }

  public var enabled: Bool {
    levels != .none
  }
}
