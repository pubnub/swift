//
//  FileManager+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public extension FileManager {
  /// Finds the URL for the newest file in a directory
  /// - Parameter directory: The URL of the directory to search in
  /// - Returns: The URL of the newest file, or `nil` if the directory was empty or not found
  func newestFile(_ directory: URL) -> URL? {
    let logFiles = files(in: directory)

    if logFiles.isEmpty {
      return nil
    }

    var newestFile: URL?
    var newestDate = Date.distantPast

    for file in logFiles {
      if let creation = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate {
        if newestDate < creation {
          newestFile = file
          newestDate = creation
        }
      }
    }
    return newestFile
  }

  /// Finds the URL for the oldest file in a directory
  /// - Parameter directory: The URL of the directory to search in
  /// - Returns: The URL of the newest file, or `nil` if the directory was empty or not found
  func oldestFile(_ directory: URL) -> URL? {
    let logFiles = files(in: directory)

    if logFiles.isEmpty {
      return nil
    }

    var oldestFile: URL?
    var oldestDate = Date.distantFuture

    for file in logFiles {
      if let creation = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate {
        if oldestDate > creation {
          oldestFile = file
          oldestDate = creation
        }
      }
    }
    return oldestFile
  }

  /// A list of file URLs contained inside a directory
  /// - Parameter directory: The URL of the directory to search in
  /// - Returns: The URL of the newest file, or `nil` if the directory was empty or not found
  func files(in directory: URL) -> [URL] {
    if let fileURLs = try? contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey],
      options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
    ) {
      return fileURLs
    }
    return []
  }

  internal func makeUniqueFilename(_ url: URL) -> URL {
    let origPath = url.deletingLastPathComponent().path
    let origExtension = url.pathExtension
    let origFilename = url.filenameWithoutExtension()

    var duplicateCount = 0
    var tempFileURL = url

    while fileExists(atPath: tempFileURL.path) {
      duplicateCount += 1

      tempFileURL = URL(fileURLWithPath: origPath)
        .appendingPathComponent("\(origFilename)_\(duplicateCount).\(origExtension)")
    }

    return tempFileURL
  }

  /// Get a temporary directory for all support versions
  internal var tempDirectory: URL {
    if #available(iOS 10.0, macOS 10.12, macCatalyst 13.0, tvOS 10.0, watchOS 3.0, *) {
      return FileManager.default.temporaryDirectory
    } else {
      // Fallback on earlier versions
      return URL(fileURLWithPath: NSTemporaryDirectory())
    }
  }

  /// Writes the contents of the provided `InputStream` to a temporary file with the corresponding filename
  ///
  /// - Parameters:
  ///   - filename: The filename of the temporary file
  ///   - inputStream: The `InputStream` that will be written
  /// - Returns: The `URL` containing the contents of the `InputStream`
  /// - Throws: The error that occurred while writing to the File
  func temporaryFile(
    using filename: String = UUID().uuidString, writing inputStream: InputStream?, purgeExisting: Bool = false
  ) throws -> URL {
    // Background File
    let tempFileURL = tempDirectory.appendingPathComponent(filename)

    // Check if file exists for cache and return
    if fileExists(atPath: tempFileURL.path) {
      if purgeExisting {
        try removeItem(at: tempFileURL)
      } else {
        return tempFileURL
      }
    }

    guard let inputStream = inputStream else {
      throw PubNubError(.missingRequiredParameter)
    }

    try inputStream.writeEncodedData(to: tempFileURL)

    return tempFileURL
  }
}
