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
public struct LogType: OptionSet, Equatable, Hashable {
  public let rawValue: UInt32

  // Reserverd Log Types
  public static let none = LogType([])
  public static let debug = LogType(rawValue: 1 << 0)
  public static let info = LogType(rawValue: 1 << 1)
  public static let event = LogType(rawValue: 1 << 2)
  public static let warn = LogType(rawValue: 1 << 3)
  public static let error = LogType(rawValue: 1 << 4)
  public static let log = LogType(rawValue: 1 << 31)
  public static let all = LogType(rawValue: UInt32.max)

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }
}

extension LogType: CustomStringConvertible {
  public var description: String {
    switch self {
    case LogType.debug:
      return "Debug"
    case LogType.info:
      return "Info"
    case LogType.event:
      return "Event"
    case LogType.warn:
      return "Warn"
    case LogType.error:
      return "Error"
    case LogType.log:
      return "Logger Event"
    case LogType.all:
      return "All"
    default:
      return "Custom"
    }
  }
}

// MARK: - PubNub Logger

/// Provides a custom logger for handling log messages from the PubNub SDK.
public struct PubNubLogger {
  let loggingQueue = DispatchQueue(label: "com.pubnub.logger", qos: .default)
  /// An array of `LogWriter` instances responsible for processing log messages.
  public var writers: [LogWriter]
  /// The current log level, determining the severity of messages to be logged.
  public var levels: LogType

  init(levels: LogType = .all, writers: [LogWriter]) {
    self.writers = writers
    self.levels = levels
  }

  public func debug(
    _ message: @autoclosure () -> Any,
    category: String? = nil,
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
    _ message: @autoclosure () -> Any,
    category: String? = nil,
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
    _ message: @autoclosure () -> Any,
    category: String? = nil,
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
    _ message: @autoclosure () -> Any,
    category: String? = nil,
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
    _ message: @autoclosure () -> Any,
    category: String? = nil,
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
    _ level: LogType,
    _ message: @autoclosure () -> Any,
    category: String? = nil,
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

  // swiftlint:disable:next function_parameter_count
  public func send(
    _ level: LogType,
    category: String? = nil,
    message: @autoclosure () -> Any,
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
      let prefix = writer.format(
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

      let fullMessage = prefix.isEmpty ? "\(message())" : "\(prefix)\(message())"

      writer.executor.execute {
        writer.send(
          message: fullMessage,
          with: level,
          and: category
        )
      }
    }
  }

  public var enabled: Bool {
    levels != .none
  }
}
