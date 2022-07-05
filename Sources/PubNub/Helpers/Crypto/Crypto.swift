//
//  Crypto.swift
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

import CommonCrypto
import Foundation

/// Object capable of encryption/decryption
public struct Crypto: Hashable {
  /// The key used when encrypting/decrypting
  public let key: Data
  /// The algorithm that will be used when encrypting/decrypting
  public let cipher: Cipher
  /// The String Encoding strategy to be used by default
  public let defaultStringEncoding: String.Encoding
  /// Whether random initialization vector should be used
  public internal(set) var randomizeIV: Bool

  public static let paddingLength = CCOptions(kCCOptionPKCS7Padding)

  public enum Operation: CCOperation {
    case encrypt
    case decrypt

    var ccValue: CCOperation {
      switch self {
      case .encrypt:
        return CCOperation(kCCEncrypt)
      case .decrypt:
        return CCOperation(kCCDecrypt)
      }
    }
  }

  public init(key data: Data, cipher: Cipher = .aes, withRandomIV: Bool = true, encoding: String.Encoding = .utf8) {
    key = data
    self.cipher = cipher
    defaultStringEncoding = encoding
    randomizeIV = withRandomIV
  }

//  public init(
//    key: String,
//    cipher: Cipher = .aes,
//    encoding: String.Encoding = .utf8
//  ) throws {
//    guard let data = key.data(using: encoding), let keyData = SHA256.hash(data: data) else {
//      throw CryptoError.invalidKey
//    }
//
//    try cipher.validate(keySize: keyData.count)
//
//    self.init(key: keyData, cipher: cipher, withRandomIV: true, encoding: encoding)
//  }

  public init?(
    key: String,
    cipher: Cipher = .aes,
    withRandomIV: Bool = true,
    encoding: String.Encoding = .utf8
  ) {
    guard let data = key.data(using: encoding), let keyData = SHA256.hash(data: data) else {
      PubNub.log.error("Crypto failed to `init` while converting `String` key to `Data`")
      return nil
    }

    do {
      try cipher.validate(keySize: keyData.count)
    } catch {
      PubNub.log.error("Crypto failed to `init` due to \(error)")
    }

    self.init(key: keyData, cipher: cipher, withRandomIV: withRandomIV, encoding: encoding)
  }

  /// An algorithm that can be used to encrypt/decrypt data
  public enum Cipher: RawRepresentable, Hashable {
    case aes

    public init?(rawValue: CCAlgorithm) {
      switch Int(rawValue) {
      case kCCAlgorithmAES128:
        self = .aes
      default:
        return nil
      }
    }

    public var rawValue: CCAlgorithm {
      switch self {
      case .aes:
        return UInt32(kCCAlgorithmAES128)
      }
    }

    /// Block size for the algorithm
    public var blockSize: Int {
      switch self {
      case .aes:
        return kCCBlockSizeAES128
      }
    }

    public var keySize: Int {
      switch self {
      case .aes:
        return kCCKeySizeAES128
      }
    }

    /// Key size for the algorithm
    public var keySizeRange: ClosedRange<Int> {
      switch self {
      case .aes:
        return kCCKeySizeAES128 ... kCCKeySizeAES256
      }
    }

    public func outputSize(from inputBytes: Int) -> Int {
      switch self {
      case .aes:
        return inputBytes + (blockSize - (inputBytes % blockSize))
      }
    }

    /// Determines if a provided key size is valid for this algorithm
    public func validate(keySize: Int) throws {
      if !keySizeRange.contains(keySize) {
        PubNub.log.error("Key size not valid for algorithm: \(keySize) not in \(keySizeRange)")
        throw CryptoError.keySizeError
      }
    }
  }

  /// An implementation of the SHA-256 hash algorithm
  public enum SHA256 {
    /// Perform a hash operation on provided `Data`
    public static func hash(data: Data) -> Data? {
      var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
      data.withUnsafeBytes {
        _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
      }
      return hexFrom(Data(hash)).lowercased(with: .current).data(using: .utf8)
    }

    static func hexFrom(_ data: Data) -> String {
      let midpoint = data.count / 2
      return data[..<midpoint].map { String(format: "%02lX", UInt($0)) }.joined()
    }
  }

  // MARK: - Initialization Vector

  static func staticInitializationVector() throws -> Data {
    guard let initializationVector = "0123456789012345".data(using: .utf8) else {
      throw CryptoError.rngFailure
    }
    return initializationVector
  }

  static func randomInitializationVector(byteCount: Int) throws -> [UInt8] {
    guard byteCount > 0 else { throw CryptoError.rngFailure }

    var bytes: [UInt8] = Array(repeating: UInt8(0), count: byteCount)
    let status = CCRandomGenerateBytes(&bytes, byteCount)

    guard status == kCCSuccess else { throw CryptoError(from: status) }

    return bytes
  }

  // MARK: - Encrypt

  public func encrypt(plaintext stringIn: String, encoding override: String.Encoding? = nil) -> Result<String, Error> {
    guard let messageData = stringIn.data(using: override ?? defaultStringEncoding) else {
      return .failure(CryptoError.illegalParameter)
    }

    return encrypt(encoded: messageData).map { $0.base64EncodedString() }
  }

  public func encrypt(encoded dataIn: Data) -> Result<Data, Error> {
    do {
      return .success(try dataIn.encrypt(using: self))
    } catch {
      return .failure(error)
    }
  }

  // MARK: - Decrypt

  public func decrypt(
    base64Encoded stringIn: String,
    encoding override: String.Encoding? = nil
  ) -> Result<String, Error> {
    guard let messageData = Data(base64Encoded: stringIn) else {
      return .failure(CryptoError.illegalParameter)
    }

    return decrypt(encrypted: messageData).flatMap { data in
      guard let decodedString = String(bytes: data, encoding: override ?? defaultStringEncoding) else {
        return .failure(CryptoError.decodeError)
      }
      return .success(decodedString)
    }
  }

  public func decrypt(encrypted dataIn: Data, dataMovedOut _: Int = 0) -> Result<Data, Error> {
    do {
      return .success(try dataIn.decrypt(using: self))
    } catch {
      return .failure(error)
    }
  }
}

/// An Error returned from a `Crypto` function
public enum CryptoError: CCCryptorStatus, Error, LocalizedError {
  /// Insufficent buffer provided for specified operation.
  case bufferTooSmall
  /// Input size was not aligned properly.
  case alignmentError
  /// Input data did not decode or decrypt  properly.
  case decodeError
  /// Illegal parameter value.
  case illegalParameter
  /// Memory allocation failure.
  case memoryFailure
  /// Buffer overflow occurred
  case overflow
  /// Failed to generate RNG
  case rngFailure
  /// Unspecified status
  case unspecifiedError
  /// Called `CCCrytor` sequence out of order
  case callSequenceError
  /// /Key is not a valid size for the specified cipher
  case keySizeError
  /// Key is not valid.
  case invalidKey
  /// Function not implemented for the current algorithm.
  case unimplemented
  /// Unknown error
  case unknown

  public init?(rawValue: CCCryptorStatus) {
    switch Int(rawValue) {
    case kCCSuccess:
      return nil
    default:
      self.init(from: rawValue)
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  public init(from nonSuccess: CCCryptorStatus) {
    switch Int(nonSuccess) {
    case kCCParamError:
      self = .illegalParameter
    case kCCBufferTooSmall:
      self = .bufferTooSmall
    case kCCMemoryFailure:
      self = .memoryFailure
    case kCCAlignmentError:
      self = .alignmentError
    case kCCDecodeError:
      self = .decodeError
    case kCCOverflow:
      self = .overflow
    case kCCRNGFailure:
      self = .rngFailure
    case kCCCallSequenceError:
      self = .callSequenceError
    case kCCKeySizeError:
      self = .keySizeError
    case kCCUnimplemented:
      self = .unimplemented
    case kCCUnspecifiedError:
      self = .unspecifiedError
    default:
      self = .unknown
    }
  }
}

extension Data {
  init(randomBytes count: Int) throws {
    self.init(bytes: try Crypto.randomInitializationVector(byteCount: count), count: count)
  }

  func encrypt(using crypto: Crypto) throws -> Data {
    do {
      let ivData: Data
      if crypto.randomizeIV {
        ivData = try Data(randomBytes: crypto.cipher.blockSize)
      } else {
        ivData = try Crypto.staticInitializationVector()
      }

      let encrypted = try crypt(
        operation: CCOperation(kCCEncrypt),
        algorithm: crypto.cipher.rawValue,
        options: CCOptions(kCCOptionPKCS7Padding),
        blockSize: crypto.cipher.blockSize,
        key: crypto.key,
        initializationVector: ivData,
        messageData: self
      )

      // Join IV and Encrypted when using a random IV
      return crypto.randomizeIV ? ivData + encrypted : encrypted
    } catch {
      throw error
    }
  }

  func decrypt(using crypto: Crypto) throws -> Data {
    let iv: Data
    let ciphertext: Data

    if crypto.randomizeIV {
      iv = prefix(kCCBlockSizeAES128)
      ciphertext = suffix(from: kCCBlockSizeAES128)
    } else {
      iv = try Crypto.staticInitializationVector()
      ciphertext = self
    }

    return try crypt(
      operation: CCOperation(kCCDecrypt),
      algorithm: crypto.cipher.rawValue,
      options: CCOptions(kCCOptionPKCS7Padding),
      blockSize: crypto.cipher.blockSize,
      key: crypto.key,
      initializationVector: iv,
      messageData: ciphertext
    )
  }

  func crypt(
    operation: CCOperation, algorithm: CCAlgorithm, options: CCOptions, blockSize: Int,
    key: Data, initializationVector: Data, messageData dataIn: Data, dataMovedOut _: Int = 0
  ) throws -> Data {
    return try key.withUnsafeBytes { keyUnsafeRawBufferPointer in
      try dataIn.withUnsafeBytes { dataInUnsafeRawBufferPointer in
        try initializationVector.withUnsafeBytes { ivUnsafeRawBufferPointer in

          let paddingSize = operation == kCCEncrypt ? blockSize : 0

          let dataOutSize: Int = dataIn.count + paddingSize
          let dataOut = UnsafeMutableRawPointer.allocate(byteCount: dataOutSize, alignment: 1)
          defer { dataOut.deallocate() }
          var dataOutMoved: Int = 0
          let status = CCCrypt(operation, algorithm, options,
                               keyUnsafeRawBufferPointer.baseAddress, key.count,
                               ivUnsafeRawBufferPointer.baseAddress,
                               dataInUnsafeRawBufferPointer.baseAddress, dataIn.count,
                               dataOut, dataOutSize, &dataOutMoved)

          if let error = CryptoError(rawValue: status) {
            if error == .bufferTooSmall {
              return try crypt(
                operation: operation, algorithm: algorithm, options: options,
                blockSize: blockSize, key: key,
                initializationVector: initializationVector, messageData: dataIn,
                dataMovedOut: dataOutMoved
              )
            }
            throw error
          }

          return Data(bytes: dataOut, count: dataOutMoved)
        }
      }
    }
  }
}
