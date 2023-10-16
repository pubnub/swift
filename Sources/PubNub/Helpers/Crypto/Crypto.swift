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
///
/// - Warning: This struct is deprecated. Use ``CryptorModule`` instead.
public struct Crypto: Hashable {
  /// Key initially provided by the user
  let key: String
  /// Whether random initialization vector should be used
  let randomizeIV: Bool
  
  public init(key: String, withRandomIV: Bool = true) {
    self.key = key
    self.randomizeIV = withRandomIV
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
