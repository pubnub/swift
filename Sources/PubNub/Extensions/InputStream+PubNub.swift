//
//  InputStream+PubNub.swift
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
