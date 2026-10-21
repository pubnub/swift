//
//  AESGCMCryptor.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A ``Cryptor`` that decrypts AES-256-GCM payloads.
///
/// The cryptor-defined metadata is 28 bytes: the 12-byte nonce followed by the 16-byte authentication tag.
struct AESGCMCryptor: Cryptor {
  static let ID: CryptorId = [0x41, 0x43, 0x47, 0x4D]

  private let key: Data

  init(key: String) {
    self.key = CryptorUtils.SHA256.hash(from: key.data(using: .utf8) ?? Data())
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
      return .failure(GCMDecrypt.failure)
    }
    return .success(plaintext)
  }

  func decrypt(data: EncryptedStreamData, outputPath: URL) -> Result<InputStream, Error> {
    guard
      data.metadata.count == GCMDecrypt.metadataLength,
      let ciphertext = Self.readAll(from: data.stream),
      let plaintext = open(metadata: data.metadata, ciphertext: ciphertext)
    else {
      return .failure(GCMDecrypt.failure)
    }
    do {
      try plaintext.write(to: outputPath, options: .atomic)
    } catch {
      return .failure(GCMDecrypt.failure)
    }
    guard let stream = InputStream(url: outputPath) else {
      return .failure(GCMDecrypt.failure)
    }
    return .success(stream)
  }
}

// MARK: - Private

private extension AESGCMCryptor {
  static var encryptionNotSupported: PubNubError {
    PubNubError(.encryptionFailure, additional: ["AES-GCM encryption is not implemented yet"])
  }
}

private extension AESGCMCryptor {
  func open(metadata: Data, ciphertext: Data) -> Data? {
    guard metadata.count == GCMDecrypt.metadataLength else {
      return nil
    }

    let tagStart = metadata.startIndex + GCMDecrypt.nonceLength

    return GCMDecrypt.open(
      key: key,
      nonce: Data(metadata[metadata.startIndex..<tagStart]),
      ciphertext: ciphertext,
      tag: Data(metadata[tagStart...])
    )
  }

  static func readAll(from stream: InputStream) -> Data? {
    if stream.streamStatus == .notOpen {
      stream.open()
    }
    defer { stream.close() }

    var content = Data()
    var buffer = [UInt8](repeating: 0, count: 64 * 1024)

    while true {
      let bytesRead = stream.read(&buffer, maxLength: buffer.count)

      if bytesRead < 0 {
        return nil
      }
      if bytesRead == 0 {
        return content
      }
      content.append(buffer, count: bytesRead)
    }
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
