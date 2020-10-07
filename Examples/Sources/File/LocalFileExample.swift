//
//  LocalFileExample.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2020 PubNub Inc.
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

import PubNub

enum FileError: Error {
  case fileNameError
  case missingLocalFile
}

struct LocalFileExample: PubNubLocalFile {
  var localFileURL: URL
  var channel: String

  var fileId: String
  var filename: String

  var remoteFilename: String?

  var createdDate: Date?

  var existsLocally: Bool {
    return FileManager.default.fileExists(atPath: localFileURL.path)
  }

  var existsRemotely: Bool {
    return fileId != "LOCALONLY"
  }

  var custom: JSONCodable? {
    get { return nil }
    set { _ = newValue }
  }

  init(from url: URL, for channel: String) throws {
    localFileURL = url
    self.channel = channel

    let filenameSplit = url.lastPathComponent.split(separator: ":")

    guard let fileIdSubstring = filenameSplit.first,
      let filenameSubstring = filenameSplit.last else {
      throw FileError.fileNameError
    }

    fileId = String(fileIdSubstring)
    filename = String(filenameSubstring)
  }

  init(from other: PubNubLocalFile) throws {
    try self.init(from: other.localFileURL, for: other.channel)
  }

  init(from other: PubNubFile) throws {
    if let otherLocal = other as? PubNubLocalFile {
      try self.init(from: otherLocal)
    } else {
      let manager = FileManager.default

      let remoteURL = try manager
        .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        .appendingPathComponent(other.channel)
        .appendingPathComponent("\(other.fileId):\(other.filename)")

      print("Created file at \(remoteURL)")

      try self.init(from: remoteURL, for: other.channel)
    }
  }
}
