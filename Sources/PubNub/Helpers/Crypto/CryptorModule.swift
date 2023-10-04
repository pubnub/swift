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

/// Object capable of encryption/decryption
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
        .encryptionFailure,
        additional: ["Cannot encrypt empty Data"])
      )
    }
    return defaultCryptor.encrypt(data: data).map {
      if defaultCryptor.id == LegacyCryptor.ID {
        return $0.data
      }
      return CryptorHeader.v1(
        cryptorId: defaultCryptor.id,
        dataLength: $0.metadata.count
      ).toData() + $0.metadata + $0.data
    }.mapError {
      PubNubError(.encryptionFailure, underlying: $0)
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
        .decryptionFailure,
        additional: ["Cannot decrypt empty Data in \(String(describing: self))"])
      )
    }
    do {
      let header = try CryptorHeader.from(data: data)
      
      guard let cryptor = cryptor(matching: header) else {
        return .failure(PubNubError(
          .unknownCryptorFailure,
          additional: [
            "Could not find matching Cryptor for \(header.cryptorId()) while decrypting Data. " +
            "Ensure the corresponding instance is registered in \(String(describing: Self.self))"
          ]
        ))
      }
      
      let metadata: Data
      let contentData: Data
      
      switch header {
      case .none:
        metadata = Data()
        contentData = data
      case .v1(_, let dataLength):
        contentData = data.suffix(from: header.toData().count + dataLength)
        metadata = data.subdata(in: header.toData().count..<header.toData().count + dataLength)
      }
      
      return cryptor.decrypt(
        data: EncryptedData(
          metadata: metadata,
          data: contentData
        )
      )
      .flatMap {
        if $0.isEmpty {
          return .failure(PubNubError(
            .decryptionFailure,
            additional: ["Decrypting resulted with empty Data"])
          )
        }
        return .success($0)
      }
      .mapError {
        PubNubError(.decryptionFailure, underlying: $0)
      }
    } catch let error as PubNubError {
      return .failure(error)
    } catch {
      return .failure(PubNubError(
        .decryptionFailure,
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
  public func encrypt(stream: InputStream, contentLength: Int) -> Result<MultipartInputStream, PubNubError> {
    guard contentLength > 0 else {
      return .failure(PubNubError(
        .encryptionFailure,
        additional: ["Cannot encrypt empty InputStream"])
      )
    }
    return defaultCryptor.encrypt(
      stream: stream,
      contentLength: contentLength
    ).map {
      let header = defaultCryptor.id != LegacyCryptor.ID ? CryptorHeader.v1(
        cryptorId: defaultCryptor.id,
        dataLength: $0.metadata.count
      ) : .none
            
      switch header {
      case .none:
        return MultipartInputStream(
          inputStreams: [InputStream(data: header.toData()), $0.stream],
          length: $0.contentLength
        )
      case .v1(_, let dataLength):
        return MultipartInputStream(
          inputStreams: [InputStream(data: header.toData() + $0.metadata), $0.stream],
          length: $0.contentLength + header.toData().count + dataLength
        )
      }
    }.mapError {
      PubNubError(.encryptionFailure, underlying: $0)
    }
  }
  
  /// Decrypts the given `InputStream` object
  ///
  /// - Parameters:
  ///   - streamData: A value describing encrypted stream
  ///   - outputPath: URL where the stream should be decrypted to
  /// - Returns: A success, storing a decrypted ``EncryptedStreamResult`` value if operation succeeds. Otherwise, a failure storing `PubNubError` is returned
  @discardableResult
  public func decrypt(
    stream: InputStream,
    contentLength: Int,
    to outputPath: URL
  ) -> Result<InputStream, PubNubError> {
    do {
      guard contentLength > 0 else {
        return .failure(PubNubError(
          .decryptionFailure,
          additional: ["Cannot decrypt empty InputStream"]
        ))
      }
      
      let finder = CryptorHeaderWithinStreamFinder(stream: stream)
      let readHeaderResp = try finder.findHeader()
      let cryptorDefinedData = readHeaderResp.cryptorDefinedData
      
      guard let cryptor = cryptor(matching: readHeaderResp.header) else {
        return .failure(PubNubError(
          .unknownCryptorFailure,
          additional: [
            "Could not find matching Cryptor for \(readHeaderResp.header.cryptorId()) while decrypting InputStream. " +
            "Ensure the corresponding instance is registered in \(String(describing: Self.self))"
          ]
        ))
      }
      return cryptor.decrypt(
        data: EncryptedStreamData(
          stream: readHeaderResp.continuationStream,
          contentLength: contentLength - readHeaderResp.header.length() - cryptorDefinedData.count,
          metadata: cryptorDefinedData
        ),
        outputPath: outputPath
      ).flatMap {
        if outputPath.sizeOf == 0 {
          return .failure(PubNubError(
            .decryptionFailure,
            additional: ["Decrypting resulted with an empty File"])
          )
        }
        return .success($0)
      }
      .mapError {
        PubNubError(.decryptionFailure, underlying: $0)
      }
    } catch let error as PubNubError {
      return .failure(error)
    } catch {
      return .failure(PubNubError(
        .decryptionFailure,
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
        .encryptionFailure,
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
          .decryptionFailure,
          additional: ["Cannot create String from provided Data"])
        )
      }
    }
  }
}
