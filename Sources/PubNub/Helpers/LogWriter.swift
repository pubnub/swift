//
//  LogWriter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import os

// MARK: - Log Category

/// Reserverd category types
enum LogCategory: String {
  case none = "None"
  case eventEngine = "EventEngine"
  case networking = "Networking"
  case crypto = "Crypto"
  case pubNub = "PubNub"
}

// MARK: - Log Writer

/// A protocol that defines a log writer, which handles logging messages to a specific output
public protocol LogWriter {
  /// A protocol responsible for dispatching log messages. Return your custom instance or use of the built-in ``LogExecutionType`` cases
  var executor: LogExecutable { get }
  /// Returns the details included in a log message
  var prefix: LogPrefix { get }

  /// Logs a message with the specified log type and category.
  ///
  /// - Parameters:
  ///   - message: A closure that returns the log message. This uses `@autoclosure` to defer evaluation until needed.
  ///   - logType: The severity level of the log (e.g., debug, info, warning, error).
  ///   - category: An optional category to classify the log message
  func send(message: @escaping @autoclosure () -> String, with logType: LogType, and category: String?)
}

public extension LogWriter {
  /// Generates a log prefix based on the specified logging details.
  ///
  /// This method constructs a default log prefix by checking which metadata elements (e.g., file name, function name, line number, thread) are enabled
  /// in the provided `prefix:` parameter. If a detail is included in the mask, it is appended to the final log prefix.
  ///
  /// - Parameters:
  ///   - prefix: A bitmask specifying which details should be included in the prefix
  ///   - category: An optional category to classify the log message
  ///   - level: The severity level of the log
  ///   - date: A timestamp for when the log entry was created
  ///   - queue: The label of the current `DispatchQueue` or `"Unknown Queue"` if no label was found
  ///   - thread: A thread name
  ///   - file: The source file name where the log statement was executed
  ///   - function: The function name where the log statement was called
  ///   - line: The line number in the source file
  /// - Returns: A formatted string containing the selected log details
  func format(
    prefix: LogPrefix,
    category: String?,
    level: LogType,
    date: Date,
    queue: String,
    thread: String,
    file: String,
    function: String,
    line: Int
  ) -> String {
    var prefixString = ""

    let categoryStr = if let category, prefix.contains(.category) {
      "[\(category.description)]"
    } else {
      ""
    }

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

    return categoryStr + "[\(prefixString.trimmingCharacters(in: CharacterSet(arrayLiteral: " ")))] "
  }
}

/// A protocol responsible for dispatching a log message
public protocol LogExecutable {
  func execute(log job: @escaping () -> Void)
}

/// Conforms to ``LogExecutable`` and provides default built-in strategies for dispatching log messages that you can choose from
public enum LogExecutionType: LogExecutable {
  /// Executes logging using an `NSLocking` for synchronization
  case sync(lock: NSLocking)
  /// Executes logging using a dedicated `DispatchQueue` for concurrency control
  case async(queue: DispatchQueue)
  /// No special execution strategy is applied; logs are processed directly
  case none

  public func execute(log job: @escaping () -> Void) {
    switch self {
    case .none:
      job()
    case let .sync(lock):
      lock.synchronize(job)
    case let .async(queue):
      queue.async {
        job()
      }
    }
  }
}

// MARK: - Console Logger

/// The concrete ``LogWriter`` implementation responsible for writing log messages to the console
public struct ConsoleLogWriter: LogWriter {
  public var sendToNSLog: Bool
  public var executor: LogExecutable
  public var prefix: LogPrefix

  public init(
    sendToNSLog: Bool = false,
    prefix: LogPrefix = .all,
    executor: LogExecutionType = .sync(lock: NSRecursiveLock())
  ) {
    self.sendToNSLog = sendToNSLog
    self.prefix = prefix
    self.executor = executor
  }

  public func send(message: @escaping @autoclosure () -> String, with logType: LogType, and category: String? = nil) {
    if sendToNSLog {
      NSLog("%@", message())
    } else {
      print(message())
    }
  }
}

// MARK: - File Logger

/// The concrete ``LogWriter`` implementation responsible for writing log messages to a file
open class FileLogWriter: LogWriter {
  public var executor: LogExecutable
  public var prefix: LogPrefix

  /// The maximum size of each log file
  public var maxFileSize: Int64 = 1024 * 1024 * 20
  /// The maximum number of log files before files start to be replaced
  public var maxLogFiles = 5
  /// The directory URL where log files will be stored
  public var directoryURL: URL
  /// The current log file
  var currentFile: URL?

  public required init(
    logDirectory: URL,
    executor: LogExecutionType = .sync(lock: NSRecursiveLock()),
    prefix: LogPrefix = .all
  ) {
    directoryURL = logDirectory
    currentFile = FileManager.default.newestFile(logDirectory)
    self.executor = executor
    self.prefix = prefix
  }

  /// Attempts to create a `LogFileWriter` at the specified directory location
  ///
  /// - parameters:
  ///   - inside: The base location of the parent directory
  ///   - at: The file system location where logs will be stored
  ///   - name: The name of the directory inside the parent directory
  ///   - prefix: Prefix formatting options
  ///   - executor: The executor of this log writer
  public convenience init(
    inside domain: FileManager.SearchPathDomainMask = .userDomainMask,
    at directory: FileManager.SearchPathDirectory = .cachesDirectory,
    with name: String = "pubnub",
    executor: LogExecutionType = .sync(lock: NSRecursiveLock()),
    prefix: LogPrefix = .all
  ) {
    do {
      guard let parentDir = FileManager.default.urls(for: directory, in: domain).first else {
        PubNub.logLog.custom(.log, "Error: Nothing found at the intersection of the domain and parent directory")
        preconditionFailure("Nothing found at the intersection of the domain and parent directory")
      }
      let logDir = parentDir.appendingPathComponent(name, isDirectory: true)
      try FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true, attributes: nil)

      PubNub.logLog.custom(.log, "File log writer will output logs to: `\(logDir)`")
      self.init(logDirectory: logDir, executor: executor, prefix: prefix)
    } catch {
      PubNub.logLog.custom(.log, "Error: Could not create logging files at location provided due to \(error)")
      preconditionFailure("Could not create logging files at location provided due to \(error)")
    }
  }

  public func send(message: @escaping @autoclosure () -> String, with logType: LogType, and category: String? = nil) {
    // If we have a cached URL then we should use it otherwise create a new file
    currentFile = createOrUpdateFile(with: "\(message()))\n")

    // Ensure that the max number of log files hasn't been reached
    if FileManager.default.files(in: directoryURL).count > maxLogFiles {
      if let oldest = FileManager.default.oldestFile(directoryURL) {
        delete(oldest)
      }
    }
  }

  public func createOrUpdateFile(with contents: String) -> URL? {
    // Update a file if it exists
    // and if the file + message size is less than maxFileSize
    if let file = currentFile,
       FileManager.default.fileExists(atPath: file.path),
       file.sizeOf + contents.utf8.count < maxFileSize {
      update(file, message: contents)
      return file
    }

    // Create a new file
    let fileURL = directoryURL.appendingPathComponent(
      logFilename,
      isDirectory: false
    )

    if !create(fileURL, with: contents) {
      PubNub.logLog.custom(.log, "Error: Failed to create log file at \(fileURL.absoluteString)")
    } else {
      PubNub.logLog.custom(.log, "Created new log file at \(fileURL.absoluteString)")
    }

    return fileURL
  }

  func create(_ file: URL, with contents: String) -> Bool {
    FileManager.default.createFile(
      atPath: file.path,
      contents: contents.data(using: .utf8),
      attributes: nil
    )
  }

  public func update(_ file: URL, message: String) {
    if
      FileManager.default.fileExists(atPath: file.path),
      let stream = OutputStream(toFileAtPath: file.path, append: true),
      let messageData = message.data(using: .utf8) {
      let dataArray = [UInt8](messageData)
      stream.open()
      defer { stream.close() }
      // This might need to take a buffer pointer and not an array
      if stream.hasSpaceAvailable {
        let dataWritten = stream.write(dataArray, maxLength: dataArray.count)
        if dataWritten != dataArray.count {
          PubNub.logLog.custom(.log, "Error: Data remainig to be written")
        }
      }
    }
  }

  var logFilename: String {
    return "\(Date().timeIntervalSince1970)-pubnub.log"
  }

  public func delete(_ file: URL) {
    do {
      try FileManager.default.removeItem(at: file)
    } catch {
      PubNub.logLog.custom(.log, "Error: Could not delete file at \(file) due to: \(error)")
    }
  }
}

// MARK: - OSLogWriter

/// A concrete implementation that delegates all log messages to the `os` Logger
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public struct OSLogWriter: LogWriter {
  public let executor: LogExecutable = LogExecutionType.none
  public let prefix: LogPrefix

  public init(prefix: LogPrefix = .all) {
    self.prefix = prefix
  }

  // swiftlint:disable:next cyclomatic_complexity
  public func send(message: @escaping @autoclosure () -> String, with logType: LogType, and category: String? = nil) {
    let finalLoggerCategory = if let category {
      LogCategory(rawValue: category) ?? .none
    } else {
      LogCategory.none
    }

    let finalLogger = switch finalLoggerCategory {
    case .eventEngine:
      Logger.eventEngine
    case .networking:
      Logger.network
    case .pubNub:
      Logger.pubNub
    default:
      Logger.defaultLogger
    }

    switch logType {
    case .debug, .all:
      finalLogger.debug("\(message())")
    case .log, .info, .event:
      finalLogger.info("\(message())")
    case .warn:
      finalLogger.warning("\(message())")
    case .error:
      finalLogger.error("\(message())")
    default:
      finalLogger.debug("\(message())")
    }
  }
}
