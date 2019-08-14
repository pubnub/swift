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

public struct Crypto: Hashable {
  public let key: Data
  public let cipher: Cipher

  public init?(key: String, cipher: Cipher = .aes) {
    guard let data = key.data(using: .utf8) else {
      return nil
    }

    self.init(key: data, cipher: cipher)
  }

  public init(key data: Data, cipher: Cipher = .aes) {
    key = SHA256.hash(data: data)
    self.cipher = cipher
  }

  public enum Cipher: RawRepresentable, Hashable {
    case aes

    public init?(rawValue: CCAlgorithm) {
      switch Int(rawValue) {
      case kCCAlgorithmAES:
        self = .aes
      default:
        return nil
      }
    }

    public var rawValue: CCAlgorithm {
      switch self {
      case .aes:
        return UInt32(kCCAlgorithmAES)
      }
    }

    public var blockSize: Int {
      switch self {
      case .aes:
        return kCCBlockSizeAES128
      }
    }

    public var keySizeRange: ClosedRange<Int> {
      switch self {
      case .aes:
        return kCCKeySizeAES128 ... kCCKeySizeAES256
      }
    }

    public func validate(keySize: Int) -> CryptoError? {
      return keySizeRange.contains(keySize) ? nil : .keySizeError
    }
  }

  public struct SHA256 {
    public static func hash(data: Data) -> Data {
      var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
      data.withUnsafeBytes {
        _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
      }
      return Data(hash)
    }
  }

  public static func randomGenerateBytes(count: Int) -> Result<Data, Error> {
    let bytes = UnsafeMutableRawPointer.allocate(byteCount: count, alignment: 1)
    defer { bytes.deallocate() }
    let status = CCRandomGenerateBytes(bytes, count)
    if let error = CryptoError(rawValue: status) {
      return .failure(error)
    }
    return .success(Data(bytes: bytes, count: count))
  }

  public func encrypt(plaintext stringIn: String, dataMovedOut _: Int = 0) -> Result<String, Error> {
    if let error = cipher.validate(keySize: key.count) {
      print("Key size not valid for algorithm: \(key.count) not in \(cipher.keySizeRange)")
      return .failure(error)
    }

    guard let dataIn = stringIn.data(using: .utf8) else {
      return .failure(CryptoError.decodeError)
    }

    let initializationVector = Crypto.randomGenerateBytes(count: cipher.blockSize)
    let messageData = dataIn

    return initializationVector.flatMap { ivData in
      crypt(operation: CCOperation(kCCEncrypt), key: key, messageData: messageData, ivData: ivData)
        .map { ivData + $0 }
        .flatMap { .success($0.base64EncodedString()) }
    }
  }

  public func encrypt(plaintext dataIn: Data, dataMovedOut _: Int = 0) -> Result<Data, Error> {
    if let error = cipher.validate(keySize: key.count) {
      print("Key size not valid for algorithm: \(key.count) not in \(cipher.keySizeRange)")
      return .failure(error)
    }

    let initializationVector = Crypto.randomGenerateBytes(count: cipher.blockSize)
    let messageData = dataIn

    return initializationVector.flatMap { ivData in
      crypt(operation: CCOperation(kCCEncrypt), key: key, messageData: messageData, ivData: ivData).map { ivData + $0 }
    }
  }

  public func decrypt(encrypted dataIn: Data, dataMovedOut _: Int = 0) -> Result<Data, Error> {
    if let error = cipher.validate(keySize: key.count) {
      print("Key size not valid for algorithm: \(key.count) not in \(cipher.keySizeRange)")
      return .failure(error)
    }

    let initializationVector = dataIn.prefix(cipher.blockSize)
    let messageData = dataIn.suffix(from: cipher.blockSize)

    return crypt(operation: CCOperation(kCCDecrypt), key: key, messageData: messageData, ivData: initializationVector)
  }

  public func decrypt(base64Encoded stringIn: String, dataMovedOut _: Int = 0) -> Result<String, Error> {
    if let error = cipher.validate(keySize: key.count) {
      print("Key size not valid for algorithm: \(key.count) not in \(cipher.keySizeRange)")
      return .failure(error)
    }

    guard let dataIn = Data(base64Encoded: stringIn, options: .ignoreUnknownCharacters) else {
      return .failure(CryptoError.decodeError)
    }

    let initializationVector = dataIn.prefix(cipher.blockSize)
    let messageData = dataIn.suffix(from: cipher.blockSize)

    return crypt(operation: CCOperation(kCCDecrypt),
                 key: key, messageData: messageData,
                 ivData: initializationVector)
      .flatMap { data in
        guard let decodedString = String(bytes: data, encoding: .utf8) else {
          return .failure(CryptoError.decodeError)
        }
        return .success(decodedString)
      }
  }

  func crypt(
    operation: CCOperation,
    key: Data,
    messageData: Data,
    ivData: Data,
    dataMovedOut: Int = 0
  ) -> Result<Data, Error> {
    return key.withUnsafeBytes { keyUnsafeRawBufferPointer in
      messageData.withUnsafeBytes { messageDataUnsafeRawBufferPointer in
        ivData.withUnsafeBytes { ivUnsafeRawBufferPointer in
          let dataOutBufferSize: Int = messageData.count + cipher.blockSize
          let dataOut = UnsafeMutableRawPointer.allocate(byteCount: dataOutBufferSize, alignment: 1)
          defer { dataOut.deallocate() }
          var dataMovedOutResult: Int = dataMovedOut
          let status = CCCrypt(operation, cipher.rawValue, CCOptions(kCCOptionPKCS7Padding),
                               keyUnsafeRawBufferPointer.baseAddress, key.count,
                               ivUnsafeRawBufferPointer.baseAddress,
                               messageDataUnsafeRawBufferPointer.baseAddress, messageData.count,
                               dataOut, dataOutBufferSize,
                               &dataMovedOutResult)
          if let error = CryptoError(rawValue: status) {
            if error == .bufferTooSmall {
              return crypt(operation: operation,
                           key: key,
                           messageData: messageData,
                           ivData: ivData,
                           dataMovedOut: dataMovedOut)
            }
            return .failure(error)
          }
          return .success(Data(bytes: dataOut, count: dataMovedOutResult))
        }
      }
    }
  }
}

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
