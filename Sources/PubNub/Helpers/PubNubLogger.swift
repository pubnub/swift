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
  public static let all = LogPrefix(rawValue: UInt32.max)

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }
}

// MARK: - Level

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

public struct PubNubLogger {
  let loggingQueue = DispatchQueue(label: "com.pubnub.logger", qos: .default)

  public var writers: [LogWriter]
  public var levels: LogType

  init(levels: LogType = .all, writers: [LogWriter]) {
    self.writers = writers
    self.levels = levels
  }

  public func debug(
    _ message: @autoclosure () -> Any,
    date: Date = Date(),
    queue: String = DispatchQueue.currentLabel,
    thread: String = Thread.currentName,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    send(.debug, message: message(),
         date: date,
         queue: queue,
         thread: thread,
         file: file,
         function: function,
         line: line)
  }

  public func info(
    _ message: @autoclosure () -> Any,
    date: Date = Date(),
    queue: String = DispatchQueue.currentLabel,
    thread: String = Thread.currentName,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    send(.info, message: message(),
         date: date,
         queue: queue,
         thread: thread,
         file: file,
         function: function,
         line: line)
  }

  public func event(
    _ message: @autoclosure () -> Any,
    date: Date = Date(),
    queue: String = DispatchQueue.currentLabel,
    thread: String = Thread.currentName,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    send(.event, message: message(),
         date: date,
         queue: queue,
         thread: thread,
         file: file,
         function: function,
         line: line)
  }

  public func warn(
    _ message: @autoclosure () -> Any,
    date: Date = Date(),
    queue: String = DispatchQueue.currentLabel,
    thread: String = Thread.currentName,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    send(.warn, message: message(),
         date: date,
         queue: queue,
         thread: thread,
         file: file,
         function: function,
         line: line)
  }

  public func error(
    _ message: @autoclosure () -> Any,
    date: Date = Date(),
    queue: String = DispatchQueue.currentLabel,
    thread: String = Thread.currentName,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    send(.error, message: message(),
         date: date,
         queue: queue,
         thread: thread,
         file: file,
         function: function,
         line: line)
  }

  public func custom(
    _ level: LogType,
    _ message: @autoclosure () -> Any,
    date: Date = Date(),
    queue: String = DispatchQueue.currentLabel,
    thread: String = Thread.currentName,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    send(level, message: message(),
         date: date,
         queue: queue,
         thread: thread,
         file: file,
         function: function,
         line: line)
  }

  // swiftlint:disable:next function_parameter_count
  public func format(
    prefix: LogPrefix,
    level: LogType,
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
    if prefix.contains(.level) {
      prefixString = "\(level.description) "
    }
    if prefix.contains(.date) {
      prefixString = "\(prefixString)\(DateFormatter.iso8601.string(from: date)) "
    }
    if prefix.contains(.queue) || prefix.contains(.thread) {
      prefixString = "\(prefixString)(\(queue)#\(thread)) "
    }
    if prefix.contains(.file) || prefix.contains(.function) || prefix.contains(.line) {
      prefixString = "\(prefixString){\(file.absolutePathFilename).\(function)#\(line)} "
    }
    return "[\(prefixString.trimmingCharacters(in: CharacterSet(arrayLiteral: " ")))] "
  }

  // swiftlint:disable:next function_parameter_count
  public func send(
    _ level: LogType,
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
      let prefix = format(prefix: writer.prefix,
                          level: level,
                          date: date,
                          queue: queue,
                          thread: thread,
                          file: file,
                          function: function,
                          line: line)

      let fullMessage = "\(prefix)\(message())"

      writer.executor.execute {
        writer.send(message: fullMessage)
      }
    }
  }

  public var enabled: Bool {
    return levels != .none
  }
}
