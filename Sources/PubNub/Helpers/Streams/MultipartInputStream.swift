//
//  MultipartInputStream.swift
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

/// An `InputStream` that can combine multiple streams into a single stream
class MultipartInputStream: InputStream {
  let inputStreams: [InputStream]

  private var currentIndex: Int
  private var _streamStatus: Stream.Status
  private var _streamError: Error?
  private weak var _delegate: StreamDelegate?

  init(inputStreams: [InputStream]) {
    self.inputStreams = inputStreams
    currentIndex = 0
    _streamStatus = .notOpen
    _streamError = nil

    // required because `init()` is not marked as a designated initializer
    super.init(data: Data())
  }

  // Subclass
  override var streamStatus: Stream.Status {
    return _streamStatus
  }

  override var streamError: Error? {
    return _streamError
  }

  override var delegate: StreamDelegate? {
    get {
      return _delegate
    }
    set {
      _delegate = newValue
    }
  }

  override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
    if _streamStatus == .closed {
      return 0
    }

    var totalNumberOfBytesRead = 0

    while totalNumberOfBytesRead < maxLength {
      // Close stream at the end of index
      if currentIndex == inputStreams.count {
        close()
        break
      }

      let currentInputStream = inputStreams[currentIndex]

      // Ensure stream is marked open
      if currentInputStream.streamStatus != .open {
        currentInputStream.open()
      }

      // If at the end, then go to the next stream index
      if !currentInputStream.hasBytesAvailable {
        currentIndex += 1
        continue
      }

      let remainingLength = maxLength - totalNumberOfBytesRead

      // Read buffer from current input stream
      switch currentInputStream.read(&buffer[totalNumberOfBytesRead], maxLength: remainingLength) {
      case let bytesRead where bytesRead < 0:
        // -1 means that the operation failed; more information about the error can be obtained with `streamError`.
        _streamError = currentInputStream.streamError
        _streamStatus = .error
        return bytesRead
      case let bytesRead where bytesRead > 0:
        // A positive number indicates the number of bytes read.
        totalNumberOfBytesRead += bytesRead
      default:
        // 0 represents end of the current buffer
        currentIndex += 1
      }
    }

    return totalNumberOfBytesRead
  }

  override func getBuffer(
    _: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>,
    length _: UnsafeMutablePointer<Int>
  ) -> Bool {
    return false
  }

  override var hasBytesAvailable: Bool {
    return true
  }

  override func open() {
    guard _streamStatus == .open else {
      return
    }
    _streamStatus = .open
  }

  override func close() {
    _streamStatus = .closed
  }

  override func property(forKey _: Stream.PropertyKey) -> Any? {
    return nil
  }

  override func setProperty(_: Any?, forKey _: Stream.PropertyKey) -> Bool {
    return false
  }

  override func schedule(in _: RunLoop, forMode _: RunLoop.Mode) { /* no-op */ }
  override func remove(from _: RunLoop, forMode _: RunLoop.Mode) { /* no-op */ }
}
