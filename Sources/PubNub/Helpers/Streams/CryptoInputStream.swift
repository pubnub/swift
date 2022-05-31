//
//  CryptoInputStream.swift
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

/// A stream that provides read-only stream functionality while performing crypto operations
public class CryptoInputStream: InputStream {
  // swiftlint:disable:previous type_body_length

  /// Estimated size of the final crypted output
  public var estimatedCryptoCount: Int = 0

  // Stream with data which should be passed through cryptor.
  private var cipherStream: InputStream
  private var rawDataBufferRead: Int = -1
  private var rawDataBuffer: [UInt8]?
  private var rawDataLength: Int
  private var rawDataRead: Int = 0

  private var cryptoStream: CryptoStream?
  private var operation: Crypto.Operation
  private var crypto: Crypto

  // Buffer for data which has been encrypted / decrypted from cipher stream.
  private var cryptedBuffer: [UInt8]?
  private var cryptedBufferRead: Int = -1
  private var cryptedDataLength: Int = -1
  private var cryptedDataFinalysed: Bool = false
  private var cryptedBytes: Int = 0
  private var totalCrypted: Int = 0

  // Super helpers
  private weak var _delegate: StreamDelegate?
  private var _streamStatus: Stream.Status = .notOpen
  private var _streamError: Error?

  public init(_ operation: Crypto.Operation, input: InputStream, contentLength: Int, with crypto: Crypto) {
    self.operation = operation
    self.crypto = crypto
    // We should always be using a random IV
    self.crypto.randomizeIV = true

    rawDataLength = contentLength - (operation == .decrypt ? crypto.cipher.blockSize : 0)
    // The estimated content length is the IV length plus the crypted length
    estimatedCryptoCount = crypto.cipher.blockSize + crypto.cipher.outputSize(from: rawDataLength)
    cipherStream = input

    // required because `init()` is not marked as a designated initializer
    super.init(data: Data())
  }

  public convenience init?(_ operation: Crypto.Operation, url: URL, with crypto: Crypto) {
    // Create a stream from the content source
    guard let plaintextStream = InputStream(url: url) else {
      PubNub.log.error("Could not create `SecureInputStream` due to underlying InputStream(url:) failing for \(url)")
      return nil
    }

    self.init(operation, input: plaintextStream, contentLength: url.sizeOf, with: crypto)
  }

  public convenience init(_ operation: Crypto.Operation, data: Data, with crypto: Crypto) {
    self.init(operation, input: InputStream(data: data), contentLength: data.count, with: crypto)
  }

  public convenience init?(_ operation: Crypto.Operation, fileAtPath path: String, with crypto: Crypto) {
    self.init(operation, url: URL(fileURLWithPath: path), with: crypto)
  }

  deinit {
    close()
  }

  private var remainingRawBufferLength: Int {
    guard let buffer = rawDataBuffer else {
      return 0
    }

    return rawDataBufferRead >= 0 ? buffer.count - rawDataBufferRead : 0
  }

  private var remainingCryptedBufferLength: Int {
    guard let buffer = cryptedBuffer else {
      return 0
    }

    return cryptedBufferRead >= 0 ? buffer.count - cryptedBufferRead : 0
  }

  // MARK: - Helpers

  private func fillRawDataBuffer(with bytes: Int) {
    guard _streamStatus == .open, cipherStream.streamStatus == .open else {
      return
    }

    var readBuffer = [UInt8](repeating: 0, count: bytes)
    var previousRawDataBuffer: [UInt8]?

    if let buffer = rawDataBuffer, remainingRawBufferLength > 0 {
      previousRawDataBuffer = Array(buffer[rawDataBufferRead...])
    }

    rawDataBufferRead = -1

    switch cipherStream.read(&readBuffer, maxLength: bytes) {
    case let bytesRead where bytesRead < 0:
      _streamError = cipherStream.streamError
      _streamStatus = .error
    case let bytesRead where bytesRead >= 0:
      rawDataBufferRead = 0
      rawDataRead += bytesRead

      if let previousBuffer = previousRawDataBuffer, !previousBuffer.isEmpty {
        rawDataBuffer = previousBuffer + readBuffer[..<bytesRead]
      } else {
        rawDataBuffer = Array(readBuffer[..<bytesRead])
      }
    default:
      break
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  private func fillCryptedDataBuffer() {
    guard let readBuffer = rawDataBuffer else { return }
    if _streamStatus == .error || _streamStatus == .closed || cryptedDataFinalysed {
      return
    }

    let finalyse = rawDataLength == rawDataRead
    let readBufferSize = remainingRawBufferLength
    let cryptorBufferSize = cryptoStream?.getOutputLength(inputLength: readBufferSize, isFinal: finalyse) ?? 0
    let bytesToRead = finalyse ? readBufferSize : min(readBufferSize, cryptorBufferSize)
    var previousCryptedDataBuffer: [UInt8]?

    if remainingCryptedBufferLength > 0, let buffer = cryptedBuffer {
      previousCryptedDataBuffer = Array(buffer[cryptedBufferRead...])
    }

    var writeBuffer = [UInt8](repeating: 0, count: cryptorBufferSize)
    cryptedBufferRead = -1
    var cryptedBytesLength = 0

    do {
      try readBuffer.withUnsafeBytes {
        if let baseAddress = $0.baseAddress {
          try cryptoStream?.update(
            bufferIn: baseAddress, byteCountIn: bytesToRead,
            bufferOut: &writeBuffer, byteCapacityOut: cryptorBufferSize,
            byteCountOut: &cryptedBytesLength
          )
        }
      }
    } catch {
      _streamError = error
      _streamStatus = .error
      return
    }

    if finalyse {
      var finalBuffer = writeBuffer
      let append = cryptedBytesLength > 0

      if append {
        finalBuffer = [UInt8](repeating: 0, count: cryptorBufferSize)
        writeBuffer = Array(writeBuffer[..<cryptedBytesLength])
      }

      do {
        var finalCryptedBytesLength = 0

        // Write the final crypted bytes
        try cryptoStream?.final(
          &finalBuffer,
          maxLength: cryptorBufferSize - cryptedBytesLength,
          cryptedBytes: &finalCryptedBytesLength
        )

        cryptedBytesLength += finalCryptedBytesLength

        if append {
          writeBuffer += finalBuffer[..<finalCryptedBytesLength]
        }
      } catch {
        _streamError = error
        _streamStatus = .error
        return
      }
    } else {
      writeBuffer = Array(writeBuffer[..<cryptedBytesLength])
    }

    if let previousBuffer = previousCryptedDataBuffer, !previousBuffer.isEmpty {
      cryptedBuffer = previousBuffer + writeBuffer
    } else {
      cryptedBuffer = writeBuffer
    }

    cryptedBufferRead = 0

    if remainingRawBufferLength > bytesToRead {
      rawDataBufferRead += bytesToRead
    } else {
      rawDataBufferRead = -1
    }

    if finalyse {
      cryptedDataFinalysed = true
      rawDataBuffer = []
    }
  }

  private func readCryptedToBuffer(_ buffer: UnsafeMutablePointer<UInt8>, length: Int) -> Int {
    if remainingCryptedBufferLength == 0 {
      return 0
    }

    guard let readBuffer = cryptedBuffer else { return -1 }
    let bytesToRead = min(length, remainingCryptedBufferLength)

    // Assign from the overflow buffer up to the max length
    readBuffer[cryptedBufferRead...].withUnsafeBufferPointer {
      guard let baseAddress = $0.baseAddress else { return }
      buffer.assign(from: baseAddress, count: bytesToRead)
    }

    if remainingCryptedBufferLength > bytesToRead {
      cryptedBufferRead += bytesToRead
    } else {
      cryptedBufferRead = -1
    }

    return bytesToRead
  }

  func crypt(
    outputBuffer: UnsafeMutablePointer<UInt8>,
    maxLength: Int,
    inputStream _: InputStream,
    readByteOffset _: Int = 0,
    cryptoStream _: CryptoStream
  ) -> Int {
    let rawBufferToRead = maxLength + crypto.cipher.blockSize - remainingCryptedBufferLength
    var cryptedBytesToRead = maxLength
    var bytesRead = 0

    if totalCrypted == 0 && remainingRawBufferLength > 0 {
      cryptedBytesToRead -= remainingRawBufferLength
    }

    fillRawDataBuffer(with: rawBufferToRead)
    fillCryptedDataBuffer()

    if _streamStatus == .closed || _streamStatus == .error {
      return _streamStatus == .error ? -1 : 0
    }

    while cryptedBytesToRead > 0, remainingCryptedBufferLength > 0 {
      switch readCryptedToBuffer(outputBuffer, length: cryptedBytesToRead) {
      case let cryptedBytesRead where cryptedBytesRead >= 0:
        cryptedBytesToRead -= cryptedBytesRead
        totalCrypted += cryptedBytesRead
        bytesRead += cryptedBytesRead
      default:
        bytesRead = -1
      }
    }

    return _streamStatus == .error ? -1 : bytesRead
  }

  // MARK: - Encrypt

  func encrypt(_ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
    // Create Crypto if it does not exist
    let encryptStream: CryptoStream
    if let cryptoStream = cryptoStream {
      encryptStream = cryptoStream
    } else {
      // Init the Crypto Stream
      do {
        // Create a randomized buffer of data the length of the cipher block size
        let ivBuffer = try Crypto.randomInitializationVector(byteCount: crypto.cipher.blockSize)
        cryptedBuffer = ivBuffer

        cryptedBufferRead = 0

        encryptStream = try CryptoStream(
          operation: operation, algorithm: crypto.cipher, options: Crypto.paddingLength,
          keyBuffer: crypto.key.map { $0 }, keyLength: crypto.key.count,
          ivBuffer: ivBuffer
        )

        cryptedDataLength = encryptStream.getOutputLength(
          inputLength: rawDataLength, isFinal: true
        ) + crypto.cipher.blockSize
      } catch {
        _streamError = error
        _streamStatus = .error
        return -1
      }

      // Assign the created stream to self so we retain it for future loops
      cryptoStream = encryptStream
    }

    return crypt(
      outputBuffer: buffer,
      maxLength: maxLength,
      inputStream: cipherStream,
      readByteOffset: 0,
      cryptoStream: encryptStream
    )
  }

  // MARK: - Decrypt

  func decrypt(_ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
    // Create Crypto if it does not exist
    let decryptStream: CryptoStream
    if let cryptoStream = cryptoStream {
      decryptStream = cryptoStream
    } else {
      // Create a buffer to store the IV in that matches the cipher block size
      var initializationVectorBuffer = [UInt8](repeating: 0, count: crypto.cipher.blockSize)

      switch cipherStream.read(&initializationVectorBuffer, maxLength: crypto.cipher.blockSize) {
      case let bytesRead where bytesRead < 0:
        // -1 means that the operation failed; more information about the error can be obtained with `streamError`.
        _streamStatus = .error
        _streamError = cipherStream.streamError
        return bytesRead
      default:
        // 0 represents end of the current buffer
        break
      }

      // Init the Crypto Stream
      do {
        decryptStream = try CryptoStream(
          operation: operation, algorithm: crypto.cipher, options: Crypto.paddingLength,
          keyBuffer: crypto.key.map { $0 }, keyLength: crypto.key.count,
          ivBuffer: initializationVectorBuffer
        )
      } catch {
        _streamError = error
        _streamStatus = .error
        return -1
      }

      // Assign the created stream to self so we retain it for future loops
      cryptoStream = decryptStream
    }

    return crypt(
      outputBuffer: buffer,
      maxLength: maxLength,
      inputStream: cipherStream,
      cryptoStream: decryptStream
    )
  }

  // MARK: - Input Stream Subclass overrides

  override public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
    // If the stream is closed the end here
    if _streamStatus == .closed {
      return 0
    }

    switch operation {
    case .encrypt:
      return encrypt(buffer, maxLength: maxLength)
    case .decrypt:
      return decrypt(buffer, maxLength: maxLength)
    }
  }

  override public var streamError: Error? {
    return _streamError
  }

  override public var delegate: StreamDelegate? {
    get { return _delegate }
    set { _delegate = newValue }
  }

  override public var streamStatus: Stream.Status {
    return _streamStatus
  }

  override public func getBuffer(
    _: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>,
    length _: UnsafeMutablePointer<Int>
  ) -> Bool {
    return false
  }

  override public var hasBytesAvailable: Bool {
    return true
  }

  override public func open() {
    guard _streamStatus != .open else {
      return
    }

    _streamStatus = .open

    if cipherStream.streamStatus == .notOpen {
      cipherStream.open()
    }
  }

  override public func close() {
    if _streamStatus != .error && _streamStatus != .closed {
      _streamStatus = .closed
    }

    if cipherStream.streamStatus != .error, cipherStream.streamStatus != .closed {
      cipherStream.close()
    }

    cryptedBuffer = nil
  }

  override public func property(forKey key: Stream.PropertyKey) -> Any? {
    return cipherStream.property(forKey: key)
  }

  override public func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool {
    return cipherStream.setProperty(property, forKey: key)
  }

  override public func schedule(in _: RunLoop, forMode _: RunLoop.Mode) { /* no-op */ }
  override public func remove(from _: RunLoop, forMode _: RunLoop.Mode) { /* no-op */ }
  // swiftlint:disable:next file_length
}
