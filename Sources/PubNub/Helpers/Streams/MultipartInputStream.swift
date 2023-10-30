//
//  MultipartInputStream.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// An `InputStream` that can combine multiple streams into a single stream
class MultipartInputStream: InputStream {
  let inputStreams: [InputStream]
  let length: Int
  
  private var currentIndex: Int
  private var _streamStatus: Stream.Status
  private var _streamError: Error?
  private weak var _delegate: StreamDelegate?

  init(inputStreams: [InputStream], length: Int = 0) {
    self.inputStreams = inputStreams
    self.length = length
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
    guard _streamStatus != .open else {
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
