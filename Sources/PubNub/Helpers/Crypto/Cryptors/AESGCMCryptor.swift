//
//  AESGCMCryptor.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import CryptoKit
import Foundation

/// A ``Cryptor`` that decrypts AES-256-GCM payloads.
///
/// The cryptor-defined metadata is 28 bytes: the 12-byte nonce followed by the 16-byte authentication tag.
struct AESGCMCryptor: Cryptor {
  static let ID: CryptorId = [0x41, 0x43, 0x47, 0x4D]

  /// Length (in bytes) of the AES-256 key
  static let keyLength = 32
  /// Length (in bytes) of the nonce stored first in the cryptor-defined metadata
  static let nonceLength = 12
  /// Length (in bytes) of the authentication tag stored after the nonce in the cryptor-defined metadata
  static let tagLength = 16
  /// Length (in bytes) of the cryptor-defined metadata: the nonce followed by the tag
  static let metadataLength = nonceLength + tagLength

  private let key: Data

  /// Creates an ``AESGCMCryptor`` from the given cipher key.
  ///
  /// Use a long, random, high-entropy key; short or guessable keys remain weak.
  ///
  /// - Parameter key: Secret used to derive the AES key.
  init(key: String) {
    self.init(rawKey: CryptorUtils.SHA256.hash(from: key.data(using: .utf8) ?? Data()))
  }

  /// Creates an ``AESGCMCryptor`` from raw AES-256 key bytes, used as is.
  ///
  /// - Parameter rawKey: 32-byte AES key. Any other length makes every decryption fail.
  init(rawKey: Data) {
    self.key = rawKey
  }

  var id: CryptorId {
    Self.ID
  }

  func encrypt(data: Data) -> Result<EncryptedData, Error> {
    .failure(Self.encryptionNotSupported)
  }

  func encrypt(stream: InputStream, contentLength: Int) -> Result<EncryptedStreamData, Error> {
    .failure(Self.encryptionNotSupported)
  }

  func decrypt(data: EncryptedData) -> Result<Data, Error> {
    guard let plaintext = open(metadata: data.metadata, ciphertext: data.data) else {
      return .failure(Self.decryptionFailure)
    }
    return .success(plaintext)
  }

  func decrypt(data: EncryptedStreamData, outputPath: URL) -> Result<InputStream, Error> {
    guard
      data.metadata.count == Self.metadataLength,
      let ciphertext = Self.readAll(from: data.stream, contentLength: data.contentLength),
      let plaintext = open(metadata: data.metadata, ciphertext: ciphertext)
    else {
      return .failure(Self.decryptionFailure)
    }
    do {
      try plaintext.write(to: outputPath, options: .atomic)
    } catch {
      return .failure(Self.decryptionFailure)
    }
    guard let stream = InputStream(url: outputPath) else {
      return .failure(Self.decryptionFailure)
    }
    return .success(stream)
  }
}

// MARK: - Private

private extension AESGCMCryptor {
  /// A single, uniform decryption failure that never exposes an underlying decryption error.
  static var decryptionFailure: PubNubError {
    PubNubError(.decryptionFailure, additional: ["Decryption failed"])
  }

  static var encryptionNotSupported: PubNubError {
    PubNubError(.encryptionFailure, additional: ["AES-GCM encryption is not implemented yet"])
  }
}

private extension AESGCMCryptor {
  func open(metadata: Data, ciphertext: Data) -> Data? {
    guard key.count == Self.keyLength, metadata.count == Self.metadataLength else {
      return nil
    }

    let tagStart = metadata.startIndex + Self.nonceLength

    guard
      let nonce = try? AES.GCM.Nonce(data: metadata[metadata.startIndex..<tagStart]),
      let sealedBox = try? AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: metadata[tagStart...])
    else {
      return nil
    }
    return try? AES.GCM.open(sealedBox, using: SymmetricKey(data: key))
  }

  static func readAll(from stream: InputStream, contentLength: Int) -> Data? {
    if stream.streamStatus == .notOpen {
      stream.open()
    }
    defer { stream.close() }

    guard contentLength >= 0 else {
      return nil
    }

    var content = Data()
    var buffer = [UInt8](repeating: 0, count: 64 * 1024)
    var remaining = contentLength

    while remaining > 0 {
      let bytesRead = stream.read(&buffer, maxLength: min(buffer.count, remaining))

      if bytesRead <= 0 {
        return nil
      }
      content.append(buffer, count: bytesRead)
      remaining -= bytesRead
    }
    return content
  }
}

extension AESGCMCryptor: Hashable {
  static func == (lhs: AESGCMCryptor, rhs: AESGCMCryptor) -> Bool {
    lhs.id == rhs.id && lhs.key == rhs.key
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(id)
  }
}
