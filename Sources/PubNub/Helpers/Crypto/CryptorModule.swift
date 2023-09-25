//
//  CryptorModule.swift
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

public struct EncryptedStreamResult {
  public let stream: InputStream
  public let contentLength: Int
}

public struct CryptorModule {
  private let defaultCryptor: Cryptor
  private let cryptors: [Cryptor]
  private let legacyCryptorId: CryptorId = []
  private let defaultStringEncoding: String.Encoding
  
  typealias Base64EncodedString = String
  
  public init(default cryptor: Cryptor, cryptors: [Cryptor] = [], encoding: String.Encoding = .utf8) {
    self.defaultCryptor = cryptor
    self.cryptors = cryptors
    self.defaultStringEncoding = encoding
  }
  
  public func encrypt(data: Data) -> Result<Data, PubNubError> {
    defaultCryptor.encrypt(data: data).map {
      CryptorHeader.v1(
        cryptorId: defaultCryptor.id,
        data: $0.metadata
      ).asData() + $0.data
    }.mapError {
      PubNubError(.encryptionError, underlying: $0)
    }
  }
  
  public func decrypt(data: Data) -> Result<Data, PubNubError> {
    do {
      let header = try CryptorHeader.from(data: data)
      
      guard let cryptor = cryptor(matching: header) else {
        return .failure(PubNubError(
          .unknownCryptorError,
          additional: ["Cannot find matching Cryptor for \(header.cryptorId())"]
        ))
      }
      return cryptor.decrypt(
        data: EncryptedData(
          metadata: header.metadataIfAny(),
          data: data.subdata(in: header.length()..<data.count)
        )
      ).mapError {
        PubNubError(.decryptionError, underlying: $0)
      }
    } catch let error as PubNubError {
      return .failure(error)
    } catch {
      return .failure(PubNubError(.unknownCryptorError, additional: ["Cannot decrypt InputStream"]))
    }
  }
  
  public func encrypt(stream: InputStream, contentLength: Int) -> Result<EncryptedStreamResult, PubNubError> {
    return defaultCryptor.encrypt(
      stream: stream,
      contentLength: contentLength
    ).map {
      let header = CryptorHeader.v1(
        cryptorId: defaultCryptor.id,
        data: $0.metadata
      )
      let multipartInputStream = MultipartInputStream(
        inputStreams: [InputStream(data: header.asData()), $0.stream]
      )
      return EncryptedStreamResult(
        stream: multipartInputStream,
        contentLength: $0.contentLength + header.length()
      )
    }.mapError {
      PubNubError(.encryptionError, underlying: $0)
    }
  }
  
  @discardableResult
  public func decrypt(
    stream: InputStream,
    contentLength: Int,
    to outputPath: URL
  ) -> Result<InputStream, PubNubError> {
    do {
      let finder = CryptorHeaderWithinStreamFinder(stream: stream)
      let readHeaderResponse = try finder.findHeader()
      
      guard let cryptor = cryptor(matching: readHeaderResponse.header) else {
        return .failure(PubNubError(
          .unknownCryptorError,
          additional: ["Cannot find matching Cryptor for \(readHeaderResponse.header.cryptorId())"]
        ))
      }
      return cryptor.decrypt(
        data: EncryptedStreamData(
          stream: readHeaderResponse.continuationStream,
          contentLength: contentLength - readHeaderResponse.header.length(),
          metadata: readHeaderResponse.header.metadataIfAny()
        ),
        outputPath: outputPath
      ).mapError {
        PubNubError(.decryptionError, underlying: $0)
      }
    } catch let error as PubNubError {
      return .failure(error)
    } catch {
      return .failure(PubNubError(.unknownCryptorError, additional: ["Cannot decrypt InputStream"]))
    }
  }
  
  private func cryptor(matching header: CryptorHeader) -> Cryptor? {
    header.cryptorId() == defaultCryptor.id ? defaultCryptor : cryptors.first(where: {
      $0.id == header.cryptorId()
    })
  }
}

public extension CryptorModule {
  static func aesCbcCryptoModule(with key: String, withRandomIV: Bool = true) -> CryptorModule {
    CryptorModule(default: AESCBCCryptor(key: key), cryptors: [LegacyCryptor(key: key, withRandomIV: withRandomIV)])
  }
  static func legacyCryptoModule(with key: String, withRandomIV: Bool = true) -> CryptorModule {
    CryptorModule(default: LegacyCryptor(key: key, withRandomIV: withRandomIV), cryptors: [AESCBCCryptor(key: key)])
  }
}

extension CryptorModule: Equatable {
  public static func ==(lhs: CryptorModule, rhs: CryptorModule) -> Bool {
    lhs.cryptors.map { $0.id } == rhs.cryptors.map { $0.id }
  }
}

extension CryptorModule: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(cryptors.map { $0.id })
  }
}

extension CryptorModule: CustomStringConvertible {
  public var description: String {
    "Default cryptor: \(defaultCryptor.id), other: \(cryptors.map { $0.id })"
  }
}

internal extension CryptorModule {
  func encrypt(string: String) -> Result<Base64EncodedString, PubNubError> {
    guard let data = string.data(using: defaultStringEncoding) else {
      return .failure(PubNubError(
        .encryptionError,
        additional: ["Cannot create Data from provided \(string)"]
      ))
    }
    return encrypt(data: data).map {
      $0.base64EncodedString()
    }
  }
  
  func decryptedString(from data: Data) -> Result<String, PubNubError> {
    decrypt(data: data).flatMap {
      if let stringValue = String(data: $0, encoding: defaultStringEncoding) {
        return .success(stringValue)
      } else {
        return .failure(PubNubError(
          .decryptionError,
          additional: ["Cannot create String from provided Data \(data)"])
        )
      }
    }
  }
}
