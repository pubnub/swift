//
//  LocalFileExample.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

import PubNub

enum FileError: Error {
  case fileNameError
  case missingLocalFile
}

struct LocalFileExample: PubNubLocalFile, Hashable {
  var fileURL: URL
  var channel: String

  var fileId: String
  var filename: String

  var size: Int64 {
    return localSize
  }

  var contentType: String?

  var createdDate: Date?

  var existsLocally: Bool {
    return FileManager.default.fileExists(atPath: fileURL.path)
  }

  var existsRemotely: Bool {
    return fileId != "LOCALONLY"
  }

  init(from url: URL, for channel: String) throws {
    fileURL = url
    self.channel = channel

    let filenameSplit = url.lastPathComponent.split(separator: ":")

    guard let fileIdSubstring = filenameSplit.first,
          let filenameSubstring = filenameSplit.last else {
      throw FileError.fileNameError
    }

    if fileIdSubstring == filenameSubstring {
      fileId = "LOCALONLY"
    } else {
      fileId = String(fileIdSubstring)
    }

    filename = String(filenameSubstring)
  }

  init(from other: PubNubLocalFile) throws {
    if !other.fileURL.pathComponents.allSatisfy({ $0 != "tmp" }) {
      let newURL = try FileManager.default.url(
        for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
      ).appendingPathComponent(other.channel).appendingPathComponent("\(other.fileId):\(other.remoteFilename)")

      try FileManager.default.copyItem(at: other.fileURL, to: newURL)

      try self.init(from: newURL, for: other.channel)
    } else {
      try self.init(from: other.fileURL, for: other.channel)
    }
  }

  init(from other: PubNubFile) throws {
    let manager = FileManager.default

    let remoteURL = try manager
      .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      .appendingPathComponent(other.channel)
      .appendingPathComponent("\(other.fileId):\(other.filename)")

    print("Created file at \(remoteURL)")

    try self.init(from: remoteURL, for: other.channel)
  }
}

public struct FilePublishMessage: JSONCodable {
  enum Operation: Int, Codable {
    case upload
    case modify
    case remove
  }

  var operation: Operation
}
