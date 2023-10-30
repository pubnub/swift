//
//  Crypto.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import CommonCrypto
import Foundation

/// Object capable of encryption/decryption
///
/// - Warning: This struct is deprecated. Use ``CryptoModule`` instead.
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
