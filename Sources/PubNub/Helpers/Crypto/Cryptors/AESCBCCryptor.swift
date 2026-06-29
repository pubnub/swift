//
//  AESCBCCryptor.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import CommonCrypto

/// Provides PubNub's **recommended** ``Cryptor`` for encryption/decryption
public struct AESCBCCryptor: Cryptor {
  private let key: Data
  private let logger: PubNubLogger?

  /// Creates an ``AESCBCCryptor`` from the given cipher key.
  ///
  /// Use a long, random, high-entropy key; short or guessable keys remain weak.
  ///
  /// - Parameter key: Secret used to derive the AES key.
  public init(key: String) {
    self.key = CryptorUtils.SHA256.hash(from: key.data(using: .utf8) ?? Data())
    self.logger = nil
  }

  init(key: Data, logger: PubNubLogger?) {
    self.key = key
    self.logger = logger
  }

  public var id: CryptorId {
    [0x41, 0x43, 0x52, 0x48]
  }

  public func encrypt(data: Data) -> Result<EncryptedData, Error> {
    do {
      let ivGenerator = CryptorVector.random(bytesCount: kCCBlockSizeAES128)
      let ivData = try ivGenerator.data()

      let encrypted = try data.crypt(
        operation: CCOperation(kCCEncrypt),
        algorithm: CCAlgorithm(kCCAlgorithmAES128),
        options: CCOptions(kCCOptionPKCS7Padding),
        blockSize: kCCBlockSizeAES128,
        key: key,
        initializationVector: ivData,
        messageData: data
      )

      return .success(EncryptedData(
        metadata: ivData,
        data: encrypted
      ))
    } catch {
      return .failure(PubNubError(
        .encryptionFailure,
        underlying: error
      ))
    }
  }

  public func decrypt(data: EncryptedData) -> Result<Data, Error> {
    guard CBCDecrypt.isValidInput(
      iv: data.metadata,
      cipherText: data.data,
      blockSize: kCCBlockSizeAES128
    ) else {
      return .failure(CBCDecrypt.failure)
    }
    do {
      return .success(
        try data.data.crypt(
          operation: CCOperation(kCCDecrypt),
          algorithm: CCAlgorithm(kCCAlgorithmAES128),
          options: CCOptions(kCCOptionPKCS7Padding),
          blockSize: kCCBlockSizeAES128,
          key: key,
          initializationVector: data.metadata,
          messageData: data.data
        )
      )
    } catch {
      return .failure(CBCDecrypt.failure)
    }
  }

  public func encrypt(stream: InputStream, contentLength: Int) -> Result<EncryptedStreamData, Error> {
    do {
      let ivGenerator = CryptorVector.random(bytesCount: kCCBlockSizeAES128)
      let ivData = try ivGenerator.data()

      let cryptoInputStreamCipher = CryptoInputStream.Cipher(
        algorithm: CCAlgorithm(kCCAlgorithmAES128),
        blockSize: kCCBlockSizeAES128
      )
      let dataForCryptoInputStream = CryptoInputStream.DataSource(
        key: key,
        iv: ivData,
        options: CCOptions(kCCOptionPKCS7Padding),
        cipher: cryptoInputStreamCipher
      )
      let cryptoInputStream = CryptoInputStream(
        operation: .encrypt,
        input: stream,
        contentLength: contentLength,
        with: dataForCryptoInputStream,
        logger: logger
      )
      return .success(EncryptedStreamData(
        stream: cryptoInputStream,
        contentLength: cryptoInputStream.estimatedCryptoCount,
        metadata: ivData
      ))
    } catch {
      return .failure(PubNubError(
        .encryptionFailure,
        underlying: error
      ))
    }
  }

  public func decrypt(data: EncryptedStreamData, outputPath: URL) -> Result<InputStream, Error> {
    // The IV lives in `metadata` and the stream carries only ciphertext, so the same length and
    // alignment checks as the in-memory path apply (CWE-20, CWE-208).
    guard
      data.metadata.count == kCCBlockSizeAES128,
      data.contentLength > 0,
      data.contentLength % kCCBlockSizeAES128 == 0
    else {
      return .failure(CBCDecrypt.failure)
    }
    do {
      let cryptoInputStreamCipher = CryptoInputStream.Cipher(
        algorithm: CCAlgorithm(kCCAlgorithmAES128),
        blockSize: kCCBlockSizeAES128
      )
      let dataForCryptoInputStream = CryptoInputStream.DataSource(
        key: key,
        iv: data.metadata,
        options: CCOptions(kCCOptionPKCS7Padding),
        cipher: cryptoInputStreamCipher
      )
      let cryptoInputStream = CryptoInputStream(
        operation: .decrypt,
        input: data.stream,
        contentLength: data.contentLength,
        with: dataForCryptoInputStream
      )
      try cryptoInputStream.writeEncodedData(
        to: outputPath
      )
      guard let stream = InputStream(url: outputPath) else {
        return .failure(CBCDecrypt.failure)
      }
      return .success(stream)
    } catch {
      return .failure(CBCDecrypt.failure)
    }
  }

  public func clone(with logger: PubNubLogger) -> AESCBCCryptor {
    AESCBCCryptor(key: key, logger: logger)
  }
}

extension AESCBCCryptor: Hashable {
  public static func == (lhs: AESCBCCryptor, rhs: AESCBCCryptor) -> Bool {
    lhs.id == rhs.id && lhs.key == rhs.key
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(id)
  }
}
