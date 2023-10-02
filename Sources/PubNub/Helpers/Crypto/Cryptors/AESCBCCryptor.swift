//
//  ImprovedCryptoAlgorithm.swift
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
        .decryptionError,
        underlying: error
      ))
    }
  }
  
  public func decrypt(data: EncryptedData) -> Result<Data, Error> {
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
      return .failure(PubNubError(
        .decryptionError,
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
        .encryptionError,
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
        .decryptionError,
        additional: ["Cannot create resulting InputStream at \(outputPath)"]
      ))
    } catch {
      return .failure(PubNubError(
        .decryptionError,
        underlying: error
      ))
    }
  }
}
