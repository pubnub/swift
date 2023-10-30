//
//  Cryptor.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import CommonCrypto

/// Represents the result of encrypted `Data`
public struct EncryptedData {
  /// Metadata (if any) used while encrypting
  let metadata: Data
  /// Resulting encrypted `Data`
  let data: Data
}

/// Represents the result of encrypted `InputStream`
public struct EncryptedStreamData {
  /// Encrypted stream you can read from
  let stream: InputStream
  /// Content length of encrypted stream
  let contentLength: Int
  /// Metadata (if any) used while encrypting
  let metadata: Data
}

/// Typealias for uniquely identifying applied encryption
public typealias CryptorId = [UInt8]

/// Protocol for all types that encapsulate concrete encryption/decryption operations
public protocol Cryptor {
  /// Unique 4-byte identifier across all `Cryptor`
  ///
  /// - Important: `[0x41, 0x43, 0x52, 0x48]` and `[0x00, 0x00, 0x00, 0x00]` values are reserved
  var id: CryptorId { get }
  
  /// Encrypts the given `Data` object
  ///
  /// - Parameters:
  ///   - data: Data to encrypt
  /// - Returns: A success, storing an ``EncryptedData`` value if operation succeeds. Otherwise, a failure storing `PubNubError` is returned
  func encrypt(data: Data) -> Result<EncryptedData, Error>
  
  /// Decrypts the given `Data` object
  ///
  /// - Parameters:
  ///   - data: Data to encrypt
  /// - Returns: A success, storing decrypted `Data` if operation succeeds. Otherwise, a failure storing `PubNubError` is returned
  func decrypt(data: EncryptedData) -> Result<Data, Error>
  
  /// Encrypts the given `InputStream` object
  ///
  /// - Parameters:
  ///   - stream: Stream to encrypt
  ///   - contentLength: Content length of encoded stream
  /// - Returns: A success, storing an ``EncryptedStreamData`` value if operation succeeds. Otherwise, a failure storing `PubNubError` is returned
  func encrypt(stream: InputStream, contentLength: Int) -> Result<EncryptedStreamData, Error>
  
  /// Decrypts the given `InputStream` object
  /// 
  /// - Parameters:
  ///   - data: A value describing encrypted stream
  ///   - outputPath: URL where the stream should be decrypted to
  /// - Returns: A success, storing a decrypted `InputStream` value at the given path if operation succeeds. Otherwise, a failure storing `PubNubError` is returned
  func decrypt(data: EncryptedStreamData, outputPath: URL) -> Result<InputStream, Error>
}
