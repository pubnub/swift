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

/// Provides a backward-compatible way of encryption/decryption
///
/// - Important: Using this `Cryptor` for encoding is strongly discouraged. Use ``AESCBCCryptor`` instead.
public struct LegacyCryptor: Cryptor {
  private let key: Data
  private let withRandomIV: Bool
  
  static let ID: CryptorId = [0x00, 0x00, 0x00, 0x00]
  
  public init(key: String, withRandomIV: Bool = true) {
    let hash = CryptorUtils.SHA256.hash(from: key.data(using: .utf8) ?? Data())
    let hexStrData = CryptorUtils.hexFrom(hash).lowercased(with: .current).data(using: .utf8) ?? Data()
    self.key = hexStrData
    self.withRandomIV = withRandomIV
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
        iv = data.data.prefix(kCCBlockSizeAES128)
        cipherText = data.data.suffix(from: kCCBlockSizeAES128)
      } else {
        iv = try CryptorVector.fixed.data()
        cipherText = data.data
      }
      
      if cipherText.isEmpty {
        return .failure(PubNubError(
          .decryptionFailure,
          additional: ["Cannot decrypt empty Data in \(String(describing: self))"])
        )
      }
      
      return .success(
        try data.data.crypt(
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
      return .failure(PubNubError(
        .decryptionFailure,
        underlying: error
      ))
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
      if let inputStream = InputStream(url: outputPath) {
        return .success(inputStream)
      }
      return .failure(PubNubError(
        .decryptionFailure,
        additional: ["Cannot create resulting InputStream at \(outputPath)"]
      ))
    } catch {
      return .failure(PubNubError(
        .decryptionFailure,
        underlying: error
      ))
    }
  }
}
