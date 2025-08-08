//
//  01-logging.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

// snippet.import
import PubNubSDK
import Foundation

// snippet.end

// snippet.configure-logging
// Configure PubNub logging system
func configureLoggingExample() {
  // Set logging levels
  // Available options: .all, .debug, .info, .event, .warn, .error, .log
  // You can also combine them: [.event, .warn, .error]
  PubNub.log.levels = [.all]  // This enables all logging

  if #available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *) {
    // OSLogWriter integrates with Apple's native logging system
    PubNub.log.writers = [OSLogWriter()]
  } else {
    // Fallback on earlier versions
    PubNub.log.writers = [ConsoleLogWriter(), FileLogWriter()]
  }
}
// snippet.end

func osLogWriterExample() {
  if #available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *) {
    // snippet.os-log-writer
    PubNub.log.writers = [OSLogWriter()]
    // snippet.end
  }
}

// snippet.custom-log-writer
class CustomLogWriter: LogWriter {
  /// Required by LogWriter protocol. LogExecutable determines how log messages are processed.
  ///
  /// We recommend using our built-in LogExecutionType enum which provides three strategies:
  ///
  /// - .sync(lock: NSLocking): Processes logs synchronously with thread safety using a lock
  /// - .async(queue: DispatchQueue): Processes logs asynchronously in a background queue
  /// - .none: No special execution strategy; logs are processed directly (assuming your custom writer can send log messages thread-safely)
  ///
  /// Example: self.executor = LogExecutionType.sync(lock: NSRecursiveLock())
  public let executor: LogExecutable

  /// Required by LogWriter protocol. LogPrefix controls various details included in square brackets [] before the message:
  ///
  /// - .none: No prefixes
  /// - .level: Log level (e.g., [DEBUG], [INFO], [ERROR])
  /// - .date: Timestamp
  /// - .queue: Dispatch queue name
  /// - .thread: Thread name
  /// - .file: Source file name
  /// - .function: Function name
  /// - .line: Line number
  /// - .category: Log category (e.g., Networking, Crypto)
  /// - .all: Includes all prefixes
  ///
  /// We recommend using .all for better troubleshooting as it provides complete context for each log message.
  ///
  /// Example: self.prefix = [.date, .level, .category]
  public let prefix: LogPrefix

  init(prefix: LogPrefix = .all) {
    self.prefix = prefix
    self.executor = LogExecutionType.sync(lock: NSRecursiveLock())
  }

  // Required by LogWriter protocol. Put your custom logging logic here.
  public func send(
    message: @escaping @autoclosure () -> String,
    withType logType: LogType,
    withCategory category: LogCategory
  ) {
    // Custom logging logic here
  }
}
// snippet.end

// snippet.custom-log-writer-usage
PubNub.log.writers = [CustomLogWriter()]
// snippet.end

// snippet.log-levels-all
// Enable all logging levels - this captures everything including debug information
// Useful during development to see all SDK operations
PubNub.log.levels = [.all]
// snippet.end

// snippet.log-levels-error
// Enable only error logging - captures only critical errors
// Useful for production environments where you only want to know about serious issues
PubNub.log.levels = [.error]
// snippet.end

// snippet.log-levels-non-debug
// Enable all standard logging levels except debug information
// This gives good visibility without excessive detail
// - .log: Standard log messages
// - .error: Error messages
// - .warn: Warning messages
// - .event: Significant event notifications
// - .info: Informational messages
PubNub.log.levels = [.log, .error, .warn, .event, .info]
// snippet.end

// snippet.disable-logging
// Method 1: Set to .none explicitly
PubNub.log.levels = [.none]
// Method 2: Use an empty set to disable all logging
PubNub.log.levels = []
// snippet.end
