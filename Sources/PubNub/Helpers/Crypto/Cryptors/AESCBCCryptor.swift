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
  
  public init(key: String) {
    self.key = CryptorUtils.SHA256.hash(from: key.data(using: .utf8) ?? Data())
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
        .decryptionFailure,
        underlying: error
      ))
    }
  }
  
  public func decrypt(data: EncryptedData) -> Result<Data, Error> {
    do {
      if data.data.isEmpty {
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
          initializationVector: data.metadata,
          messageData: data.data
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
        with: dataForCryptoInputStream
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
      if let stream = InputStream(url: outputPath) {
        return .success(stream)
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
