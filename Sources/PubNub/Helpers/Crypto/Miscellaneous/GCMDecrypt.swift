//
//  GCMDecrypt.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import CommonCrypto
import Foundation

/// An AES-256-GCM implementation.
///
/// Implementations receive validated input (32-byte key, 12-byte nonce, 16-byte tag).
protocol AESGCMStrategy {
  /// Verifies the authentication tag and decrypts the ciphertext.
  ///
  /// No plaintext is produced unless the tag is valid.
  ///
  /// - Returns: The plaintext, or `nil` if authentication fails
  func open(key: Data, nonce: Data, ciphertext: Data, tag: Data) -> Data?

  /// Encrypts the plaintext and produces the authentication tag.
  ///
  /// - Returns: The ciphertext (without the tag) and the 16-byte tag
  func seal(key: Data, nonce: Data, plaintext: Data) throws -> (ciphertext: Data, tag: Data)
}

extension AESGCMStrategy {
  func seal(key: Data, nonce: Data, plaintext: Data) throws -> (ciphertext: Data, tag: Data) {
    throw PubNubError(.encryptionFailure, additional: ["AES-GCM encryption is not implemented yet"])
  }
}

extension AESGCMStrategy where Self == CommonCryptoGCMStrategy {
  /// Implementation built on top of CommonCrypto, available on every supported OS version
  static var commonCrypto: Self {
    CommonCryptoGCMStrategy()
  }
}

extension AESGCMStrategy where Self == CryptoKitGCMStrategy {
  /// Implementation built on top of CryptoKit, available from iOS 13, macOS 10.15, tvOS 13 and watchOS 6
  static var cryptoKit: Self {
    CryptoKitGCMStrategy()
  }
}

/// Helpers shared by the AES-256-GCM decrypt paths
enum GCMDecrypt {
  /// Length (in bytes) of the nonce carried in the cryptor-defined metadata
  static let nonceLength = 12
  /// Length (in bytes) of the authentication tag appended to the ciphertext
  static let tagLength = 16

  /// CryptoKit when the OS provides it, the CommonCrypto implementation otherwise
  static var automatic: AESGCMStrategy {
    if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
      return .cryptoKit
    } else {
      return .commonCrypto
    }
  }

  /// A single, uniform decryption failure that never exposes an underlying decryption error.
  static var failure: PubNubError {
    PubNubError(.decryptionFailure, additional: ["Decryption failed"])
  }

  /// Validates the input sizes and delegates decryption to the given strategy.
  ///
  /// - Parameters:
  ///   - key: 32-byte AES key
  ///   - nonce: 12-byte nonce
  ///   - ciphertext: Encrypted bytes, without the tag. May be empty.
  ///   - tag: 16-byte authentication tag
  ///   - strategy: Implementation to use
  /// - Returns: The plaintext, or `nil` if the input is malformed or authentication fails
  static func open(
    key: Data,
    nonce: Data,
    ciphertext: Data,
    tag: Data,
    strategy: AESGCMStrategy = GCMDecrypt.automatic
  ) -> Data? {
    guard key.count == kCCKeySizeAES256, nonce.count == nonceLength, tag.count == tagLength else {
      return nil
    }
    return strategy.open(key: key, nonce: nonce, ciphertext: ciphertext, tag: tag)
  }
}
