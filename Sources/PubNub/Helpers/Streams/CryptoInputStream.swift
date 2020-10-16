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

  private var cipherStream: InputStream
  private var rawContentLength: Int

  private var cryptoStream: CryptoStream?
  private var operation: Crypto.Operation
  private var crypto: Crypto

  private var ivStream: InputStream?

  private var cryptedBytes: Int = 0
  private var totalCrypted: Int = 0

  // Crypto Finalize Buffer Management
  private var finalBufferOverlow: [UInt8] = []
  private var finalBufferBytesRemaining = 0
  private var currentFinalBufferIndex = 0

  // Super helperss
  private weak var _delegate: StreamDelegate?
  private var _streamStatus: Stream.Status = .notOpen
  private var _streamError: Error?

  public init(_ operation: Crypto.Operation, input: InputStream, contentLength: Int, with crypto: Crypto) {
    self.operation = operation
    self.crypto = crypto
    // We should always be using a random IV
    self.crypto.randomizeIV = true

    rawContentLength = contentLength
    // The estimated content length is the IV length plus the crypted length
    estimatedCryptoCount = crypto.cipher.blockSize + crypto.cipher.outputSize(from: rawContentLength)
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
    ivStream?.close()
    cipherStream.close()
  }

  // MARK: - Helpers

  func readInitializationVectorBuffer(
    _ buffer: UnsafeMutablePointer<UInt8>,
    maxLength: Int,
    inputStream: InputStream
  ) -> Int {
    var totalNumberOfBytesRead = 0

    while totalNumberOfBytesRead < maxLength {
      let remainingLength = maxLength - totalNumberOfBytesRead

      if inputStream.streamStatus != .open {
        inputStream.open()
      }

      // If the IV Stream has nothing more available then we move on
      if !inputStream.hasBytesAvailable {
        continue
      }

      // Read from the IV stream to prepend this to the encrypted payload
      switch inputStream.read(&buffer[totalNumberOfBytesRead], maxLength: remainingLength) {
      case let bytesRead where bytesRead < 0:
        // -1 means that the operation failed; more information about the error can be obtained with `streamError`.
        _streamStatus = .error
        _streamError = inputStream.streamError
        return bytesRead

      case let bytesRead where bytesRead > 0:
        // A positive number indicates the number of bytes read.
        totalNumberOfBytesRead += bytesRead

      default:
        // 0 represents end of the current buffer
        continue
      }
    }

    return totalNumberOfBytesRead
  }

  func write(
    _ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int, inputBuffer: [UInt8],
    inputBufferRemaining: inout Int, inputBufferCurrent: inout Int
  ) -> Int {
    // If the final buffer is larger than the ouput buffer
    if finalBufferBytesRemaining > maxLength {
      // Assign from the overflow buffer up to the max length
      inputBuffer[inputBufferCurrent...].withUnsafeBufferPointer {
        guard let baseAddress = $0.baseAddress else { return }
        buffer.assign(from: baseAddress, count: maxLength)
      }

      // Update the remaining final buffer
      inputBufferCurrent += maxLength
      inputBufferRemaining -= maxLength

      // Return the number of bytes written to the output buffer
      return maxLength
    } else {
      // Assign from the overflow buffer up to the remaining length
      inputBuffer[inputBufferCurrent...].withUnsafeBufferPointer {
        guard let baseAddress = $0.baseAddress else { return }
        buffer.assign(from: baseAddress, count: inputBufferRemaining)
      }

      // Cache the final bytes written to return
      let bytesWritten = inputBufferRemaining

      // Set the final buffer value to 0 to ensure that we're not doing any additional assignments
      inputBufferRemaining = 0

      // Return the number of bytes written to the output buffer
      return bytesWritten
    }
  }

  // Returns- The number of bytes written to output
  func finalizeCryptedBuffer(
    _ buffer: UnsafeMutablePointer<UInt8>,
    maxLength: Int,
    cryptoStream: CryptoStream
  ) -> Int {
    // We have remaining bytes, so we should read from here
    if !finalBufferOverlow.isEmpty {
      // Write to buffer from the stored overflow buffer
      return write(
        buffer, maxLength: maxLength,
        inputBuffer: finalBufferOverlow,
        inputBufferRemaining: &finalBufferBytesRemaining,
        inputBufferCurrent: &currentFinalBufferIndex
      )
    } else {
      // Determine the output length of the final crypto block
      let finalBufferLength = cryptoStream.getOutputLength()

      // Return early if there is no more crypted bytes to write
      if finalBufferLength == 0 {
        return finalBufferLength
      }

      // The amount of bytes written from the `final` step
      var finalCryptedBytes = 0

      // If the final cyrpted buffer is larger than maxLength
      // we will write the final crypted buffer to a temporary buffer
      // and then continue reading from that until it's empty
      if finalBufferLength > maxLength {
        // Set the final buffer to equal the length of bytes remaining
        finalBufferOverlow = [UInt8](repeating: 0, count: finalBufferLength)

        do {
          // Write the final cyrpted bytes to the overflow buffer
          try cryptoStream.final(
            &finalBufferOverlow,
            maxLength: finalBufferLength,
            cryptedBytes: &finalCryptedBytes
          )
        } catch {
          _streamError = error
          _streamStatus = .error
          return -1
        }

        // Set the initial final buffer count to be the amount of bytes written
        finalBufferBytesRemaining = finalBufferOverlow.count

        // Write to buffer from the stored overflow buffer
        return write(
          buffer, maxLength: maxLength,
          inputBuffer: finalBufferOverlow,
          inputBufferRemaining: &finalBufferBytesRemaining,
          inputBufferCurrent: &currentFinalBufferIndex
        )
      } else {
        // We can write directly to the output buffer as there is space available
        do {
          // There might be some reamining bytes in the crypto buffer that we need to process
          try cryptoStream.final(
            buffer,
            maxLength: maxLength,
            cryptedBytes: &finalCryptedBytes
          )
        } catch {
          _streamError = error
          _streamStatus = .error
          return -1
        }

        // This might not be an error if the plaintext content length equals the cipher block size
        // Otherwise something when wrong, but it's unclear what
        if finalCryptedBytes == 0 && (rawContentLength % crypto.cipher.blockSize) != 0 {
          PubNub.log.warn("The final crypto step failed to write data when it's possible it should have")
        }

        // Return the number of bytes written to the output buffer
        return finalCryptedBytes
      }
    }
  }

  func crypt(
    outputBuffer: UnsafeMutablePointer<UInt8>,
    maxLength: Int,
    inputStream: InputStream,
    readByteOffset: Int = 0,
    cryptoStream: CryptoStream
  ) -> Int {
    var inputBuffer = [UInt8](repeating: 0, count: maxLength)
    var totalNumberOfBytesRead = readByteOffset

    while totalNumberOfBytesRead < maxLength {
      let remainingLength = maxLength - totalNumberOfBytesRead

      // Ensure that the plaintext stream is open
      if inputStream.streamStatus != .open {
        inputStream.open()
      }

      // We have reached the end of the underlying stream
      if !inputStream.hasBytesAvailable {
        // Write the final padded block
        let bytesWritten = finalizeCryptedBuffer(
          &outputBuffer[totalNumberOfBytesRead],
          maxLength: remainingLength,
          cryptoStream: cryptoStream
        )

        // Update the amount of bytes written this loop
        totalNumberOfBytesRead += bytesWritten

        // Close the stream only if we didn't fill the output buffer
        if totalNumberOfBytesRead != maxLength {
          close()
        }

        break
      }

      // Read up to the remaining buffer length from the underlying stream from the current pointer
      switch inputStream.read(&inputBuffer[totalNumberOfBytesRead], maxLength: remainingLength) {
      case let bytesRead where bytesRead < 0:
        // -1 means that the operation failed; more information about the error can be obtained with `streamError`.
        _streamError = inputStream.streamError
        _streamStatus = .error
        return -1

      case let bytesRead where bytesRead > 0:
        // A positive number indicates the number of bytes read.

        do {
          // We need to get the raw buffer pointer from the start of the current bytes read
          // then we can perfrom the crypter operation
          try inputBuffer[totalNumberOfBytesRead...].withUnsafeBytes {
            if let baseAddress = $0.baseAddress {
              try cryptoStream.update(
                bufferIn: baseAddress, byteCountIn: bytesRead,
                bufferOut: &outputBuffer[totalNumberOfBytesRead], byteCapacityOut: remainingLength,
                byteCountOut: &cryptedBytes
              )
            }
          }
        } catch {
          _streamError = error
          _streamStatus = .error
          return -1
        }

        // A positive number indicates the number of bytes read.
        totalNumberOfBytesRead += cryptedBytes

      default:
        // 0 represents end of the current buffer; We finalize the crypto process
        continue
      }
    }

    return totalNumberOfBytesRead
  }

  func encrypt(_ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
    // Temp variables
    var totalNumberOfBytesRead = 0

    // Create Crypto if it does not exist
    let encryptStream: CryptoStream
    if let cryptoStream = self.cryptoStream {
      encryptStream = cryptoStream
    } else {
      // Init the Crypto Stream
      do {
        // Create a randomized buffer of data the length of the cipher block size
        let initializationVectorBuffer = try Crypto.randomInitializationVector(byteCount: crypto.cipher.blockSize)
        ivStream = InputStream(data: Data(bytes: initializationVectorBuffer, count: crypto.cipher.blockSize))

        let bytesRead = readInitializationVectorBuffer(
          buffer,
          maxLength: crypto.cipher.blockSize,
          inputStream: InputStream(data: Data(bytes: initializationVectorBuffer, count: crypto.cipher.blockSize))
        )

        // We need to add the bytes read to our total
        totalNumberOfBytesRead += bytesRead

        encryptStream = try CryptoStream(
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
      cryptoStream = encryptStream
    }

    return crypt(
      outputBuffer: buffer,
      maxLength: maxLength,
      inputStream: cipherStream,
      readByteOffset: totalNumberOfBytesRead,
      cryptoStream: encryptStream
    )
  }

  // MARK: - Decrypt

  func decrypt(_ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
    // Create Crypto if it does not exist
    let decryptStream: CryptoStream
    if let cryptoStream = self.cryptoStream {
      decryptStream = cryptoStream
    } else {
      // Create a buffer to store the IV in that matches the cipher block size
      var initializationVectorBuffer = [UInt8](repeating: 0, count: crypto.cipher.blockSize)

      _ = readInitializationVectorBuffer(
        &initializationVectorBuffer,
        maxLength: crypto.cipher.blockSize,
        inputStream: cipherStream
      )

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

  // MARK: Input Stream Subclass overrides

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
    guard _streamStatus == .open else {
      return
    }
    _streamStatus = .open
  }

  override public func close() {
    ivStream?.close()
    cipherStream.close()

    _streamStatus = .closed
  }

  override public func property(forKey _: Stream.PropertyKey) -> Any? {
    return nil
  }

  override public func setProperty(_: Any?, forKey _: Stream.PropertyKey) -> Bool {
    return false
  }

  override public func schedule(in _: RunLoop, forMode _: RunLoop.Mode) { /* no-op */ }
  override public func remove(from _: RunLoop, forMode _: RunLoop.Mode) { /* no-op */ }
  // swiftlint:disable:next file_length
}
