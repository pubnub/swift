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

/// Represents the result of stream encryption
public struct EncryptedStreamResult {
  /// Encoded stream you can read from
  public let stream: InputStream
  /// Content length of encoded stream
  public let contentLength: Int
  
  public init(stream: InputStream, contentLength: Int) {
    self.stream = stream
    self.contentLength = contentLength
  }
}

/// Object capable of encryption/decryption.
///
/// - Important: Replaces obsolete [Crypto](https://github.com/pubnub/swift/blob/master/Sources/PubNub/Helpers/Crypto/Crypto.swift#L32)
public struct CryptorModule {
  private let defaultCryptor: Cryptor
  private let cryptors: [Cryptor]
  private let legacyCryptorId: CryptorId = []
  private let defaultStringEncoding: String.Encoding
  
  typealias Base64EncodedString = String
  
  /// Initializes `CryptorModule` with custom ``Cryptor`` objects capable of encryption and decryption
  ///
  /// Use this constructor if you would like to provide **custom** objects for decryption and encryption and don't want to use PubNub's built-in `Cryptors`.
  /// Otherwise, refer to convenience static factory methods such as ``aesCbcCryptoModule(with:withRandomIV:)``
  /// and ``legacyCryptoModule(with:withRandomIV:)`` that returns `CryptorModule` configured for you.
  ///
  /// - Parameters:
  ///   - default: Primary ``Cryptor`` instance used for encryption and decryption
  ///   - cryptors: An optional list of ``Cryptor`` instances which older messages/files were encoded
  ///   - encoding: Default String encoding used when publishing new messages
  public init(default cryptor: Cryptor, cryptors: [Cryptor] = [], encoding: String.Encoding = .utf8) {
    self.defaultCryptor = cryptor
    self.cryptors = cryptors
    self.defaultStringEncoding = encoding
  }
  
  /// Encrypts the given `Data` object
  /// 
  /// - Parameters:
  ///   - data: Data to encrypt
  /// - Returns: A success, storing encrypted `Data` if operation succeeds. Otherwise, a failure storing `PubNubError` is returned
  public func encrypt(data: Data) -> Result<Data, PubNubError> {
    guard !data.isEmpty else {
      return .failure(PubNubError(
        .encryptionError,
        additional: ["Cannot encrypt empty Data"])
      )
    }
    return defaultCryptor.encrypt(data: data).map {
      if defaultCryptor.id == LegacyCryptor.ID {
        return $0.data
      } else {
        return CryptorHeader.v1(
          cryptorId: defaultCryptor.id,
          data: $0.metadata
        ).asData() + $0.data
      }
    }.mapError {
      PubNubError(.encryptionError, underlying: $0)
    }
  }
  
  /// Decrypts the given `Data` object
  ///
  /// - Parameters:
  ///   - data: Data to encrypt
  /// - Returns: A success, storing decrypted `Data` if operation succeeds. Otherwise, a failure storing `PubNubError` is returned
  public func decrypt(data: Data) -> Result<Data, PubNubError> {
    guard !data.isEmpty else {
      return .failure(PubNubError(
        .decryptionError,
        additional: ["Cannot decrypt empty Data"])
      )
    }
    do {
      let header = try CryptorHeader.from(data: data)
      
      guard let cryptor = cryptor(matching: header) else {
        return .failure(PubNubError(
          .unknownCryptorError,
          additional: [
            "Could not find matching Cryptor for \(header.cryptorId()) while decrypting Data. " +
            "Ensure the corresponding instance is registered in \(String(describing: Self.self))"
          ]
        ))
      }
      return cryptor.decrypt(
        data: EncryptedData(
          metadata: header.metadataIfAny(),
          data: data.subdata(in: header.length()..<data.count)
        )
      )
      .flatMap {
        if $0.isEmpty {
          return .failure(PubNubError(
            .decryptionError,
            additional: ["Decrypting resulted with empty Data"])
          )
        }
        return .success($0)
      }
      .mapError {
        PubNubError(.decryptionError, underlying: $0)
      }
    } catch let error as PubNubError {
      return .failure(error)
    } catch {
      return .failure(PubNubError(
        .decryptionError,
        underlying: error,
        additional: ["Cannot decrypt InputStream"])
      )
    }
  }
  
  /// Encrypts the given `InputStream` object
  ///
  /// - Parameters:
  ///   - stream: Stream to encrypt
  ///   - contentLength: Content length of encoded stream
  /// - Returns: A success, storing an ``EncryptedStreamResult`` value if operation succeeds. Otherwise, a failure storing `PubNubError` is returned
  public func encrypt(stream: InputStream, contentLength: Int) -> Result<EncryptedStreamResult, PubNubError> {
    guard contentLength > 0 else {
      return .failure(PubNubError(
        .encryptionError,
        additional: ["Cannot encrypt empty InputStream"])
      )
    }
    return defaultCryptor.encrypt(
      stream: stream,
      contentLength: contentLength
    ).map {
      let header = defaultCryptor.id != LegacyCryptor.ID ? CryptorHeader.v1(
        cryptorId: defaultCryptor.id,
        data: $0.metadata
      ) : .none
      
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
  
  /// Decrypts the given `InputStream` object
  ///
  /// - Parameters:
  ///   - data: A value describing encrypted stream
  ///   - outputPath: URL where the stream should be decrypted to
  /// - Returns: A success, storing a decrypted ``EncryptedStreamResult`` value if operation succeeds. Otherwise, a failure storing `PubNubError` is returned
  @discardableResult
  public func decrypt(
    stream streamData: EncryptedStreamResult,
    to outputPath: URL
  ) -> Result<InputStream, PubNubError> {
    do {
      guard streamData.contentLength > 0 else {
        return .failure(PubNubError(
          .decryptionError,
          additional: ["Cannot decrypt empty InputStream"]
        ))
      }
      
      let finder = CryptorHeaderWithinStreamFinder(stream: streamData.stream)
      let readHeaderResponse = try finder.findHeader()
      
      guard let cryptor = cryptor(matching: readHeaderResponse.header) else {
        return .failure(PubNubError(
          .unknownCryptorError,
          additional: [
            "Could not find matching Cryptor for \(readHeaderResponse.header.cryptorId()) while decrypting InputStream. " +
            "Ensure the corresponding instance is registered in \(String(describing: Self.self))"
          ]
        ))
      }
      return cryptor.decrypt(
        data: EncryptedStreamData(
          stream: readHeaderResponse.continuationStream,
          contentLength: streamData.contentLength - readHeaderResponse.header.length(),
          metadata: readHeaderResponse.header.metadataIfAny()
        ),
        outputPath: outputPath
      ).flatMap {
        if outputPath.sizeOf == 0 {
          return .failure(PubNubError(
            .decryptionError,
            additional: ["Decrypting resulted with an empty File"])
          )
        }
        return .success($0)
      }
      .mapError {
        PubNubError(.decryptionError, underlying: $0)
      }
    } catch let error as PubNubError {
      return .failure(error)
    } catch {
      return .failure(PubNubError(
        .decryptionError,
        underlying: error,
        additional: ["Could not decrypt InputStream"])
      )
    }
  }
  
  private func cryptor(matching header: CryptorHeader) -> Cryptor? {
    header.cryptorId() == defaultCryptor.id ? defaultCryptor : cryptors.first(where: {
      $0.id == header.cryptorId()
    })
  }
}

/// Convenience methods for creating `CryptorModule`
public extension CryptorModule {
  
  /// Returns **recommended** `CryptorModule` for encryption/decryption
  ///
  /// - Parameters:
  ///   - key: Key used for encryption/decryption
  ///   - withRandomIV: A flag describing whether random initialization vector should be used
  ///
  /// This method sets ``AESCBCCryptor`` as the primary object for decryption and encryption. It also instantiates ``LegacyCryptor`` with `withRandomIV`
  /// flag in order to decode messages/files that were encoded in old way.
  static func aesCbcCryptoModule(with key: String, withRandomIV: Bool = true) -> CryptorModule {
    CryptorModule(default: AESCBCCryptor(key: key), cryptors: [LegacyCryptor(key: key, withRandomIV: withRandomIV)])
  }
  
  /// Returns legacy `CryptorModule` for encryption/decryption
  ///
  /// - Parameters:
  ///   - key: Key used for encryption/decryption
  ///   - withRandomIV: A flag describing whether random initialization vector should be used
  /// - Warning: It's highly recommended to always use ``aesCbcCryptoModule(with:withRandomIV:)``
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
    "Default cryptor: \(defaultCryptor.id), others: \(cryptors.map { $0.id })"
  }
}

internal extension CryptorModule {
  func encrypt(string: String) -> Result<Base64EncodedString, PubNubError> {
    guard let data = string.data(using: defaultStringEncoding) else {
      return .failure(PubNubError(
        .encryptionError,
        additional: ["Cannot create Data from provided String"]
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
          additional: ["Cannot create String from provided Data"])
        )
      }
    }
  }
}
