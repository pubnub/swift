//
//  CryptoAlgorithm.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2023 PubNub Inc.
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
