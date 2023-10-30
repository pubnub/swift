//
//  InputStream+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

extension InputStream {
  public func writeEncodedData(to fileURL: URL) throws {
    if FileManager.default.fileExists(atPath: fileURL.path) {
      throw PubNubError(.fileMissingAtPath, additional: [fileURL.path])
    }

    guard let outputStream = OutputStream(url: fileURL, append: false) else {
      throw PubNubError(.streamCouldNotBeInitialized, additional: [fileURL.absoluteString])
    }

    outputStream.open()
    defer { outputStream.close() }

    open()
    defer { self.close() }

    while hasBytesAvailable {
      var buffer = [UInt8](repeating: 0, count: 1024)
      let bytesRead = read(&buffer, maxLength: 1024)

      if let streamError = streamError {
        throw PubNubError(.inputStreamFailure, underlying: streamError)
      }

      if bytesRead > 0 {
        if buffer.count != bytesRead {
          buffer = Array(buffer[0 ..< bytesRead])
        }

        try write(&buffer, to: outputStream)
      } else {
        break
      }
    }
  }

  @discardableResult
  private func write(_ buffer: inout [UInt8], totalBytes: Int? = nil, to outputStream: OutputStream) throws -> Int {
    var bytesToWrite = totalBytes ?? buffer.count

    while bytesToWrite > 0, outputStream.hasSpaceAvailable {
      let bytesWritten = outputStream.write(buffer, maxLength: bytesToWrite)

      if let error = outputStream.streamError {
        throw PubNubError(.outputStreamFailure, underlying: error)
      }

      bytesToWrite -= bytesWritten

      if bytesToWrite > 0 {
        buffer = Array(buffer[bytesWritten ..< buffer.count])
      }
    }

    if bytesToWrite > 0 {
      // There are still bytes left to be written, but the OutputStream is full
      throw PubNubError(.unknown)
    }

    return totalBytes ?? buffer.count
  }
}
