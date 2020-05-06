//
//  FileManager+PubNub.swift
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

extension FileManager {
  /// Finds the URL for the newest file in a directory
  /// - Parameter directory: The URL of the directory to search in
  /// - Returns: The URL of the newest file, or `nil` if the directory was empty or not found
  public func newestFile(_ directory: URL) -> URL? {
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
  public func oldestFile(_ directory: URL) -> URL? {
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
  public func files(in directory: URL) -> [URL] {
    if let fileURLs = try? contentsOfDirectory(at: directory,
                                               includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey],
                                               options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) {
      return fileURLs
    }
    return []
  }
}
