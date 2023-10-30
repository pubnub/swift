//
//  CryptoModule.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@available(*, unavailable, renamed: "CryptoModule")
public class CryptorModule {
  public static func aesCbcCryptoModule(with key: String, withRandomIV: Bool = true) -> CryptoModule {
    preconditionFailure("This method is no longer available")
  }
  public static func legacyCryptoModule(with key: String, withRandomIV: Bool = true) -> CryptoModule {
    preconditionFailure("This method is no longer available")
  }
}

/// Object capable of encryption/decryption
public struct CryptoModule {
  private let defaultCryptor: Cryptor
  private let cryptors: [Cryptor]
  private let legacyCryptorId: CryptorId = []
  
  typealias Base64EncodedString = String
  
  /// Initializes `CryptoModule` with custom ``Cryptor`` objects capable of encryption and decryption
  ///
  /// Use this constructor if you would like to provide **custom** objects for decryption and encryption and don't want to use PubNub's built-in `Cryptors`.
  /// Otherwise, refer to convenience static factory methods such as ``aesCbcCryptoModule(with:withRandomIV:)``
  /// and ``legacyCryptoModule(with:withRandomIV:)`` that return `CryptoModule` configured for you.
  ///
  /// - Parameters:
  ///   - default: Primary ``Cryptor`` instance used for encryption and decryption
  ///   - cryptors: An optional list of ``Cryptor`` instances which older messages/files were encoded
  public init(default cryptor: Cryptor, cryptors: [Cryptor] = []) {
    self.defaultCryptor = cryptor
    self.cryptors = cryptors
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
  ///   - data: Data to decrypt
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
        let offset = header.toData().count
        contentData = data.suffix(from: offset + dataLength)
        metadata = data.subdata(in: offset..<offset + dataLength)
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
  /// - Returns: A success, storing an `InputStream` value if operation succeeds. Otherwise, a failure storing `PubNubError` is returned
  public func encrypt(stream: InputStream, contentLength: Int) -> Result<InputStream, PubNubError> {
    guard contentLength > 0 else {
      return .failure(PubNubError(
        .encryptionFailure,
        additional: ["Cannot encrypt empty InputStream"]
      ))
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
  ///   - stream: Stream to decrypt
  ///   - contentLength: Content length of encrypted stream
  ///   - to: URL where the stream should be decrypted to
  /// - Returns: A success, storing a decrypted `InputStream` value if operation succeeds. Otherwise, a failure storing `PubNubError` is returned
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
        additional: ["Could not decrypt InputStream"]
      ))
    }
  }
  
  private func cryptor(matching header: CryptorHeader) -> Cryptor? {
    header.cryptorId() == defaultCryptor.id ? defaultCryptor : cryptors.first(where: {
      $0.id == header.cryptorId()
    })
  }
}

/// Convenience methods for creating `CryptoModule`
public extension CryptoModule {
  
  /// Returns **recommended** `CryptoModule` for encryption/decryption
  ///
  /// - Parameters:
  ///   - key: Key used for encryption/decryption
  ///   - withRandomIV: A flag describing whether random initialization vector should be used
  ///
  /// This method sets ``AESCBCCryptor`` as the primary object for decryption and encryption. It also
  /// instantiates ``LegacyCryptor``under the hood with `withRandomIV`. This way, you can interact with historical
  /// messages or messages sent from older clients
  static func aesCbcCryptoModule(with key: String, withRandomIV: Bool = true) -> CryptoModule {
    CryptoModule(default: AESCBCCryptor(key: key), cryptors: [LegacyCryptor(key: key, withRandomIV: withRandomIV)])
  }
  
  /// Returns legacy `CryptoModule` for encryption/decryption
  ///
  /// - Parameters:
  ///   - key: Key used for encryption/decryption
  ///   - withRandomIV: A flag describing whether random initialization vector should be used
  /// - Warning: It's highly recommended to always use ``aesCbcCryptoModule(with:withRandomIV:)``
  static func legacyCryptoModule(with key: String, withRandomIV: Bool = true) -> CryptoModule {
    CryptoModule(default: LegacyCryptor(key: key, withRandomIV: withRandomIV), cryptors: [AESCBCCryptor(key: key)])
  }
}

extension CryptoModule: Equatable {
  public static func ==(lhs: CryptoModule, rhs: CryptoModule) -> Bool {
    lhs.cryptors.map { $0.id } == rhs.cryptors.map { $0.id }
  }
}

extension CryptoModule: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(cryptors.map { $0.id })
  }
}

extension CryptoModule: CustomStringConvertible {
  public var description: String {
    "Default cryptor: \(defaultCryptor.id), others: \(cryptors.map { $0.id })"
  }
}

internal extension CryptoModule {
  func encrypt(string: String) -> Result<Base64EncodedString, PubNubError> {
    guard let data = string.data(using: .utf8) else {
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
      if let stringValue = String(data: $0, encoding: .utf8) {
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
