//
//  PubNubLogger.swift
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

// MARK: - Log Writer

public protocol LogWriter {
  var executor: LogExecutable { get }
  var prefix: LogPrefix { get }

  func send(message: String)
}

public protocol LogExecutable {
  func execute(log job: @escaping () -> Void)
}

public enum LogExecutionType: LogExecutable {
  case sync(lock: NSLocking)
  case async(queue: DispatchQueue)

  public func execute(log job: @escaping () -> Void) {
    switch self {
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

  public func send(message: String) {
    if sendToNSLog {
      NSLog("%@", message)
    } else {
      print(message)
    }
  }
}

// MARK: - File Logger

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

  public func send(message: String) {
    // If we have a cached URL then we should use it otherwise create a new file
    currentFile = createOrUpdateFile(with: "\(message)\n")

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
    let fileURL = directoryURL.appendingPathComponent(logFilename, isDirectory: false)
    if !create(fileURL, with: contents) {
      PubNub.logLog.custom(.log, "Error: Failed to create log file at \(fileURL.absoluteString)")
    } else {
      PubNub.logLog.custom(.log, "Created new log file at \(fileURL.absoluteString)")
    }

    return fileURL
  }

  func create(_ file: URL, with contents: String) -> Bool {
    return FileManager.default.createFile(atPath: file.path,
                                          contents: contents.data(using: .utf8),
                                          attributes: nil)
  }

  public func update(_ file: URL, message: String) {
    if FileManager.default.fileExists(atPath: file.path),
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
