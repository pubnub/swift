//
//  LegacyCryptor.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import CommonCrypto

/// A `Cryptor` implementing PubNub's older encryption format.
///
/// - Important: Kept for backward compatibility only. Do not use it to encrypt new payloads. Use ``AESCBCCryptor`` instead.
public struct LegacyCryptor: Cryptor {
  private let key: Data
  private let withRandomIV: Bool
  private let logger: PubNubLogger?

  static let ID: CryptorId = [0x00, 0x00, 0x00, 0x00]

  /// Creates a cryptor that encrypts and decrypts in PubNub's older format.
  ///
  /// - Parameters:
  ///   - key: Cipher key.
  ///   - withRandomIV: Whether a random initialization vector is used. When decrypting, this must match the value used at encryption time.
  ///
  /// - Important: For new encryption, use ``AESCBCCryptor`` instead.
  public init(key: String, withRandomIV: Bool = true) {
    let hash = CryptorUtils.SHA256.hash(from: key.data(using: .utf8) ?? Data())
    let hexStrData = CryptorUtils.hexFrom(hash).lowercased(with: .current).data(using: .utf8) ?? Data()
    self.key = hexStrData
    self.withRandomIV = withRandomIV
    self.logger = nil
  }

  init(key: Data, withRandomIV: Bool, logger: PubNubLogger?) {
    self.key = key
    self.withRandomIV = withRandomIV
    self.logger = logger
  }

  public var id: CryptorId {
    Self.ID
  }

  public func encrypt(data: Data) -> Result<EncryptedData, Error> {
    do {
      let vectorGen = withRandomIV ? CryptorVector.random(bytesCount: kCCBlockSizeAES128) : CryptorVector.fixed
      let ivData = try vectorGen.data()

      let encrypted = try data.crypt(
        operation: CCOperation(kCCEncrypt),
        algorithm: CCAlgorithm(kCCAlgorithmAES128),
        options: CCOptions(kCCOptionPKCS7Padding),
        blockSize: kCCBlockSizeAES128,
        key: key,
        initializationVector: ivData,
        messageData: data
      )

      // Join IV and encrypted content when using a random IV
      return .success(EncryptedData(
        metadata: Data(),
        data: vectorGen.isRandom() ? ivData + encrypted : encrypted
      ))
    } catch {
      return .failure(PubNubError(
        .decryptionFailure,
        underlying: error
      ))
    }
  }

  public func decrypt(data: EncryptedData) -> Result<Data, Error> {
    let iv: Data
    let cipherText: Data

    do {
      if withRandomIV {
        // A random-IV payload must carry at least one block of IV before any ciphertext.
        guard data.data.count >= kCCBlockSizeAES128 else {
          return .failure(CBCDecrypt.failure)
        }
        iv = data.data.prefix(kCCBlockSizeAES128)
        cipherText = data.data.suffix(from: kCCBlockSizeAES128)
      } else {
        iv = try CryptorVector.fixed.data()
        cipherText = data.data
      }

      guard CBCDecrypt.isValidInput(iv: iv, cipherText: cipherText, blockSize: kCCBlockSizeAES128) else {
        return .failure(CBCDecrypt.failure)
      }

      return .success(
        try cipherText.crypt(
          operation: CCOperation(kCCDecrypt),
          algorithm: CCAlgorithm(kCCAlgorithmAES128),
          options: CCOptions(kCCOptionPKCS7Padding),
          blockSize: kCCBlockSizeAES128,
          key: key,
          initializationVector: iv,
          messageData: cipherText
        )
      )
    } catch {
      return .failure(CBCDecrypt.failure)
    }
  }

  public func encrypt(stream: InputStream, contentLength: Int) -> Result<EncryptedStreamData, Error> {
    do {
      // Always uses random IV for InputStream processing
      let ivGenerator = CryptorVector.random(bytesCount: kCCBlockSizeAES128)
      let iv = try ivGenerator.data()

      let cryptoInputStreamCipher = CryptoInputStream.Cipher(
        algorithm: CCAlgorithm(kCCAlgorithmAES128),
        blockSize: kCCBlockSizeAES128
      )
      let dataForCryptoInputStream = CryptoInputStream.DataSource(
        key: key,
        iv: iv,
        options: CCOptions(kCCOptionPKCS7Padding),
        cipher: cryptoInputStreamCipher
      )
      let cryptoInputStream = CryptoInputStream(
        operation: .encrypt,
        input: stream,
        contentLength: contentLength,
        with: dataForCryptoInputStream,
        includeInitializationVectorInContent: true
      )
      return .success(EncryptedStreamData(
        stream: cryptoInputStream,
        contentLength: cryptoInputStream.estimatedCryptoCount,
        metadata: iv
      ))
    } catch {
      return .failure(PubNubError(
        .encryptionFailure,
        underlying: error
      ))
    }
  }

  public func decrypt(data: EncryptedStreamData, outputPath: URL) -> Result<InputStream, Error> {
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
        with: dataForCryptoInputStream,
        includeInitializationVectorInContent: true
      )
      try cryptoInputStream.writeEncodedData(
        to: outputPath
      )
      guard let inputStream = InputStream(url: outputPath) else {
        return .failure(CBCDecrypt.failure)
      }
      return .success(inputStream)
    } catch {
      return .failure(CBCDecrypt.failure)
    }
  }

  public func clone(with logger: PubNubLogger) -> LegacyCryptor {
    LegacyCryptor(key: key, withRandomIV: withRandomIV, logger: logger)
  }
}

extension LegacyCryptor: Hashable {
  public static func == (lhs: LegacyCryptor, rhs: LegacyCryptor) -> Bool {
    lhs.id == rhs.id && lhs.withRandomIV == rhs.withRandomIV && lhs.key == rhs.key
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(withRandomIV)
    hasher.combine(id)
  }
}
