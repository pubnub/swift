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
let pubnub = PubNub(
  configuration: .init(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  ),
  logger: PubNubLogger(levels: [.all])
)
// snippet.end

func osLogWriterExample() {
  if #available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *) {
    // snippet.os-log-writer
    let pubnub = PubNub(
      configuration: .init(
        publishKey: "demo",
        subscribeKey: "demo",
        userId: "myUniqueUserId"
      ),
      logger: PubNubLogger(
        levels: [.all],
        writers: [OSLogWriter()]
      )
    )
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
  /// We recommend using .all for troubleshooting as it provides complete context for each log message.
  public let prefix: LogPrefix

  init(prefix: LogPrefix = .all) {
    self.prefix = prefix
    self.executor = LogExecutionType.sync(lock: NSRecursiveLock())
  }

  // Required by LogWriter protocol. Put your custom logging logic here.
  public func send(
    message: @escaping @autoclosure () -> LogMessage,
    metadata: LogMetadata
  ) {
    // Custom logging logic here
  }
}
// snippet.end

func customLogWriterUsageExample() {
  // snippet.custom-log-writer-usage
  let pubnub = PubNub(
    configuration: .init(
      publishKey: "demo",
      subscribeKey: "demo",
      userId: "myUniqueUserId"
    ),
    logger: PubNubLogger(
      levels: [.all],
      writers: [CustomLogWriter()]
    )
  )
  // snippet.end
}

func combinedLogWritersUsageExample() {
  if #available(iOS 14.0, macOS 11.0, watchOS 7.0, tvOS 14.0, *) {
    // snippet.combined-log-writers
    let pubnub = PubNub(
      configuration: .init(
        publishKey: "demo",
        subscribeKey: "demo",
        userId: "myUniqueUserId"
      ),
      logger: PubNubLogger(
        levels: [.all],
        writers: [
          OSLogWriter(),     // Apple's native logging
          CustomLogWriter()  // Your custom logger
        ]
      )
    )
    // snippet.end
  }
}

// snippet.log-levels-all
// Enable all logging levels - this captures everything including debug information
// Useful during development to see all SDK operations
PubNubLogger(levels: [.all])
// snippet.end

// snippet.log-levels-error
// Enable only error logging - captures only critical errors
// Useful for production environments where you only want to know about serious issues
PubNubLogger(levels: [.error])
// snippet.end

// snippet.log-levels-non-debug
// Enable all standard logging levels except debug information
// This gives good visibility without excessive detail
// - .log: Standard log messages
// - .error: Error messages
// - .warn: Warning messages
// - .event: Significant event notifications
// - .info: Informational messages
PubNubLogger(levels: [.error, .warn, .event, .info])
// snippet.end

// snippet.disable-logging
// Method 1: Set to .none explicitly
pubnub.logLevel = [.none]
// Method 2: Use an empty set to disable all logging
pubnub.logLevel = []
// snippet.end
