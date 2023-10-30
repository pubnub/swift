//
//  CryptoInputStream.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import CommonCrypto

/// A stream that provides read-only stream functionality while performing crypto operations
public class CryptoInputStream: InputStream {
  // swiftlint:disable:previous type_body_length
  public struct DataSource {
    let key: Data
    let iv: Data
    let options: CCOptions
    let cipher: Cipher
  }
  
  public struct Cipher {
    let algorithm: CCAlgorithm
    let blockSize: Int
  }
  
  public enum Operation {
    case decrypt
    case encrypt
  }
  
  /// Estimated size of the final crypted output
  public var estimatedCryptoCount: Int = 0

  // Stream with data which should be passed through cryptor.
  private var cipherStream: InputStream
  private var rawDataBufferRead: Int = -1
  private var rawDataBuffer: [UInt8]?
  private var rawDataLength: Int = 0
  private var rawDataRead: Int = 0

  private var cryptoStream: CryptoStream?
  private var operation: Operation
  private var crypto: DataSource

  // Buffer for data which has been encrypted / decrypted from cipher stream.
  private var cryptedBuffer: [UInt8]?
  private var cryptedBufferRead: Int = -1
  private var cryptedDataFinalysed: Bool = false
  private var cryptedBytes: Int = 0
  private var totalCrypted: Int = 0

  // Super helpers
  private weak var _delegate: StreamDelegate?
  private var _streamStatus: Stream.Status = .notOpen
  private var _streamError: Error?
  
  // A flag describing whether an IV vector is included at the beginning of encoded/decoded content
  private let includeInitializationVectorInContent: Bool

  public init(
    operation: CryptoInputStream.Operation,
    input: InputStream,
    contentLength: Int,
    with crypto: CryptoInputStream.DataSource,
    includeInitializationVectorInContent: Bool = false
  ) {
    self.operation = operation
    self.crypto = crypto
    self.includeInitializationVectorInContent = includeInitializationVectorInContent
    
    if operation == .encrypt {
      do {
        cryptedBufferRead = 0
        let ivBuffer = crypto.iv.map { $0 }
        
        let cryptoStream = try CryptoStream(
          operation: CCOperation(operation == .decrypt ? kCCDecrypt : kCCEncrypt),
          algorithm: crypto.cipher.algorithm,
          options: crypto.options,
          keyBuffer: crypto.key.map { $0 },
          keyLength: crypto.key.count,
          ivBuffer: ivBuffer
        )
        if includeInitializationVectorInContent {
          cryptedBuffer = ivBuffer
          rawDataLength = contentLength
          estimatedCryptoCount = crypto.cipher.blockSize + cryptoStream.getOutputLength(inputLength: rawDataLength, isFinal: true)
        } else {
          rawDataLength = contentLength
          estimatedCryptoCount = cryptoStream.getOutputLength(inputLength: rawDataLength, isFinal: true)
        }
        self.cryptoStream = cryptoStream
        
      } catch {
        _streamError = error
        _streamStatus = .error
      }
    } else {
      
      // Create a buffer to store the IV in that matches the cipher block size
      var initializationVectorBuffer = [UInt8](repeating: 0, count: crypto.cipher.blockSize)
      
      if includeInitializationVectorInContent {
        switch input.read(&initializationVectorBuffer, maxLength: crypto.cipher.blockSize) {
        case let bytesRead where bytesRead < 0:
          // -1 means that the operation failed; more information about the error can be obtained with `streamError`.
          _streamStatus = .error
          _streamError = input.streamError
        default:
          // 0 represents end of the current buffer
          break
        }
      } else {
        initializationVectorBuffer = crypto.iv.map { $0 }
      }
      
      // Init the Crypto Stream
      do {
        let decryptStream = try CryptoStream(
          operation: CCOperation(operation == .decrypt ? kCCDecrypt : kCCEncrypt),
          algorithm: crypto.cipher.algorithm,
          options: crypto.options,
          keyBuffer: crypto.key.map { $0 },
          keyLength: crypto.key.count,
          ivBuffer: initializationVectorBuffer
        )
        
        if includeInitializationVectorInContent {
          rawDataLength = contentLength - crypto.cipher.blockSize
          // The estimated content length is the IV length plus the crypted length
          estimatedCryptoCount = crypto.cipher.blockSize + decryptStream.getOutputLength(inputLength: rawDataLength, isFinal: true)
        } else {
          rawDataLength = contentLength
          estimatedCryptoCount = decryptStream.getOutputLength(inputLength: rawDataLength, isFinal: true)
        }
        
        self.cryptoStream = decryptStream
      } catch {
        _streamError = error
        _streamStatus = .error
      }
    }
    
    cipherStream = input

    // required because `init()` is not marked as a designated initializer
    super.init(data: Data())
  }

  public convenience init?(
    operation: CryptoInputStream.Operation,
    url: URL,
    with crypto: CryptoInputStream.DataSource
  ) {
    // Create a stream from the content source
    guard let plaintextStream = InputStream(url: url) else {
      PubNub.log.error("Could not create `SecureInputStream` due to underlying InputStream(url:) failing for \(url)")
      return nil
    }

    self.init(operation: operation, input: plaintextStream, contentLength: url.sizeOf, with: crypto)
  }

  public convenience init(
    operation: CryptoInputStream.Operation,
    data: Data,
    with crypto: CryptoInputStream.DataSource
  ) {
    self.init(operation: operation, input: InputStream(data: data), contentLength: data.count, with: crypto)
  }

  public convenience init?(
    operation: CryptoInputStream.Operation,
    fileAtPath path: String,
    with crypto: DataSource
  ) {
    self.init(operation: operation, url: URL(fileURLWithPath: path), with: crypto)
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
      
      writeBuffer = Array(writeBuffer[..<cryptedBytesLength])
      
      if append {
        finalBuffer = [UInt8](repeating: 0, count: cryptorBufferSize)
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
    return crypt(
      outputBuffer: buffer,
      maxLength: maxLength,
      inputStream: cipherStream,
      readByteOffset: 0,
      cryptoStream: self.cryptoStream!
    )
  }

  // MARK: - Decrypt

  func decrypt(_ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
    return crypt(
      outputBuffer: buffer,
      maxLength: maxLength,
      inputStream: cipherStream,
      cryptoStream: self.cryptoStream!
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
