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
  public let key: Data?
  /// The algorithm that will be used when encrypting/decrypting
  public let cipher: Cipher
  /// The String Encoding strategy to be used by default
  public let defaultStringEncoding: String.Encoding

  public init?(key: String, cipher: Cipher = .aes, encoding: String.Encoding = .utf8) {
    guard let data = key.data(using: encoding) else {
      return nil
    }

    self.init(key: data, cipher: cipher, encoding: encoding)
  }

  public init(key data: Data, cipher: Cipher = .aes, encoding: String.Encoding = .utf8) {
    key = SHA256.hash(data: data)
    self.cipher = cipher
    defaultStringEncoding = encoding
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

    /// Key size for the algorithm
    public var keySizeRange: ClosedRange<Int> {
      switch self {
      case .aes:
        return kCCKeySizeAES128 ... kCCKeySizeAES256
      }
    }

    /// Determines if a provided key size is valid for this algorithm
    public func validate(keySize: Int) -> CryptoError? {
      return keySizeRange.contains(keySize) ? nil : .keySizeError
    }
  }

  /// An implementation of the SHA-256 hash algorithm
  public struct SHA256 {
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

  static var initializationVector: Result<Data, Error> {
    guard let initializationVector = "0123456789012345".data(using: .utf8) else {
      return .failure(CryptoError.rngFailure)
    }
    return .success(initializationVector)
  }

  // MARK: - Encrypt

  public func encrypt(plaintext stringIn: String, encoding override: String.Encoding? = nil) -> Result<String, Error> {
    guard let messageData = stringIn.data(using: override ?? defaultStringEncoding) else {
      return .failure(CryptoError.illegalParameter)
    }

    return encrypt(encoded: messageData).map { $0.base64EncodedString() }
  }

  public func encrypt(encoded dataIn: Data, dataMovedOut _: Int = 0) -> Result<Data, Error> {
    guard let key = key else {
      return .failure(CryptoError.keySizeError)
    }

    if let error = cipher.validate(keySize: key.count) {
      PubNub.log.error("Key size not valid for algorithm: \(key.count) not in \(cipher.keySizeRange)")
      return .failure(error)
    }

    let messageData = dataIn

    return Crypto.initializationVector.flatMap { ivData in
      crypt(operation: CCOperation(kCCEncrypt), key: key, messageData: messageData, ivData: ivData)
    }
  }

  // MARK: - Decrypt

  public func decrypt(
    base64Encoded stringIn: String,
    encoding override: String.Encoding? = nil,
    dataMovedOut _: Int = 0
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
    guard let key = key else {
      return .failure(CryptoError.keySizeError)
    }

    if let error = cipher.validate(keySize: key.count) {
      PubNub.log.error("Key size not valid for algorithm: \(key.count) not in \(cipher.keySizeRange)")
      return .failure(error)
    }

    let messageData = dataIn

    return Crypto.initializationVector.flatMap { ivData in
      crypt(operation: CCOperation(kCCDecrypt), key: key, messageData: messageData, ivData: ivData)
    }
  }

  func crypt(
    operation: CCOperation,
    key: Data,
    messageData dataIn: Data,
    ivData: Data,
    dataMovedOut: Int = 0
  ) -> Result<Data, Error> {
    let paddingSize = operation == kCCEncrypt ? cipher.blockSize : 0

    let dataOutAvailable = dataIn.count + paddingSize
    var dataOut = Data(count: dataOutAvailable)
    var dataOutMoved = dataMovedOut

    let status = key.withUnsafeBytes { keyUnsafeRawBufferPointer in
      dataIn.withUnsafeBytes { dataInUnsafeRawBufferPointer in
        ivData.withUnsafeBytes { ivUnsafeRawBufferPointer in
          dataOut.withUnsafeMutableBytes { dataOutPointer in
            CCCrypt(operation, cipher.rawValue, CCOptions(kCCOptionPKCS7Padding),
                    keyUnsafeRawBufferPointer.baseAddress, key.count,
                    ivUnsafeRawBufferPointer.baseAddress,
                    dataInUnsafeRawBufferPointer.baseAddress, dataIn.count,
                    dataOutPointer.baseAddress, dataOutAvailable,
                    &dataOutMoved)
          }
        }
      }
    }
    if let error = CryptoError(rawValue: status) {
      if error == .bufferTooSmall {
        return crypt(operation: operation,
                     key: key,
                     messageData: dataIn,
                     ivData: ivData,
                     dataMovedOut: dataOutMoved)
      }
      return .failure(error)
    }

    // Resize to dataOutMoved
    dataOut.count = dataOutMoved

    return .success(dataOut)
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

  // swiftlint:disable:next cyclomatic_complexity
  public init?(rawValue: CCCryptorStatus) {
    switch Int(rawValue) {
    case kCCSuccess:
      return nil
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
