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

/// Object capable of encryption/decryption
public struct CryptoModule {
  private let defaultCryptor: any Cryptor
  private let cryptors: [any Cryptor]
  private let legacyCryptorId: CryptorId = []

  typealias Base64EncodedString = String

  /// Represents an encrypted stream with its total content length
  public struct EncryptedStreamResult {
    /// The encrypted input stream
    public let stream: InputStream
    /// Total length of the encrypted content
    public let contentLength: Int
  }

  /// Initializes `CryptoModule` with custom ``Cryptor`` objects capable of encryption and decryption
  ///
  /// Use this constructor if you would like to provide **custom** objects for decryption and encryption
  /// and don't want to use PubNub's built-in `Cryptors`. Otherwise, refer to convenience static factory methods
  /// such as ``aesCbcCryptoModule(with:withRandomIV:)``and ``legacyCryptoModule(with:withRandomIV:)``
  /// that return `CryptoModule` configured for you.
  ///
  /// - Parameters:
  ///   - default: Primary ``Cryptor`` instance used for encryption and decryption
  ///   - cryptors: An optional list of ``Cryptor`` instances which older messages/files were encoded
  public init(default cryptor: any Cryptor, cryptors: [any Cryptor] = []) {
    self.defaultCryptor = cryptor
    self.cryptors = cryptors
  }

  /// Encrypts the given `Data` object
  ///
  /// - Parameters:
  ///   - data: Data to encrypt
  /// - Returns:
  ///   - **Success**: An encrypted `Data` object
  ///   - **Failure**: `PubNubError` describing the reason of failure
  public func encrypt(data: Data) -> Result<Data, PubNubError> {
    PubNub.log.debug(
      "Encrypting Data \(data.asUTF8String())",
      category: .crypto
    )

    let encryptionResult = performDataEncryption(data: data)

    switch encryptionResult {
    case .success:
      PubNub.log.debug("Data encrypted successfully", category: .crypto)
    case let .failure(error):
      PubNub.log.debug("Encryption of Data failed due to \(error)", category: .crypto)
    }

    return encryptionResult
  }

  private func performDataEncryption(data: Data) -> Result<Data, PubNubError> {
    guard !data.isEmpty else {
      return .failure(PubNubError(
        .encryptionFailure,
        additional: ["Cannot encrypt empty Data"]
      ))
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
  /// - Returns:
  ///  - **Success**: A decrypted `Data` object
  ///  - **Failure**: `PubNubError` describing the reason of failure
  public func decrypt(data: Data) -> Result<Data, PubNubError> {
    PubNub.log.debug(
      "Decrypting Data",
      category: .crypto
    )

    let decryptionResult = performDataDecryption(data: data)

    switch decryptionResult {
    case .success:
      PubNub.log.debug("Data decrypted successfully", category: .crypto)
    case let .failure(error):
      PubNub.log.debug("Decryption of Data failed due to \(error)", category: .crypto)
    }

    return decryptionResult
  }

  private func performDataDecryption(data: Data) -> Result<Data, PubNubError> {
    guard !data.isEmpty else {
      return .failure(PubNubError(
        .decryptionFailure,
        additional: ["Cannot decrypt empty Data in \(String(describing: self))"]
      ))
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
            additional: ["Decrypting resulted with empty Data"]
          ))
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
        additional: ["Cannot decrypt InputStream"]
      ))
    }
  }

  /// Creates an encrypted stream from the given stream
  ///
  /// - Parameters:
  ///   - stream: Stream to encrypt
  ///   - contentLength: Content length of the stream to encrypt
  /// - Returns:
  ///   - **Success**: An `EncryptedStreamResult` containing the encrypted input stream and its total content length
  ///   - **Failure**: `PubNubError` describing the reason of failure
  public func encrypt(stream: InputStream, contentLength: Int) -> Result<EncryptedStreamResult, PubNubError> {
    PubNub.log.debug(
      "Encrypting file",
      category: .crypto
    )

    let streamEncryptionResult = performStreamEncryption(
      stream: stream,
      contentLength: contentLength
    )

    switch streamEncryptionResult {
    case .success:
      PubNub.log.debug("File encrypted successfully")
    case let .failure(error):
      PubNub.log.debug("Encryption of file failed due to \(error)")
    }

    return streamEncryptionResult.map { multipartStream in
      EncryptedStreamResult(
        stream: multipartStream,
        contentLength: multipartStream.length
      )
    }
  }

  /// Encrypts the given local file URL and returns the result as an `EncryptedStreamResult`
  ///
  /// - Parameters:
  ///   - from: The local file URL of the stream to encrypt
  /// - Returns:
  ///   - **Success**: An `EncryptedStreamResult` containing the encrypted input stream and its total content length
  ///   - **Failure**: `PubNubError` describing the reason of failure
  public func encryptStream(from localFileURL: URL) -> Result<EncryptedStreamResult, PubNubError> {
    guard let inputStream = InputStream(url: localFileURL) else {
      PubNub.log.debug(
        "Cannot create InputStream from \(localFileURL). Ensure that the file exists at the specified path",
        category: .crypto
      )
      return .failure(PubNubError(
        .fileMissingAtPath,
        additional: ["Cannot create InputStream from \(localFileURL)"]
      ))
    }

    let streamEncryptionResult = performStreamEncryption(
      stream: inputStream,
      contentLength: localFileURL.sizeOf
    )

    switch streamEncryptionResult {
    case .success:
      PubNub.log.debug("File encrypted successfully")
    case let .failure(error):
      PubNub.log.debug("Encryption of file failed due to \(error)")
    }

    return streamEncryptionResult.map {
      EncryptedStreamResult(
        stream: $0,
        contentLength: $0.length
      )
    }
  }

  private func performStreamEncryption(stream: InputStream, contentLength: Int) -> Result<MultipartInputStream, PubNubError> {
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
  ///   - contentLength: Content length of the encrypted stream
  ///   - to: URL where the stream should be decrypted to
  /// - Returns:
  ///  - **Success**: A decrypted `InputStream` object
  ///  - **Failure**: `PubNubError` describing the reason of failure
  @discardableResult
  public func decrypt(
    stream: InputStream,
    contentLength: Int,
    to outputPath: URL
  ) -> Result<InputStream, PubNubError> {
    PubNub.log.debug(
      "Decrypting file",
      category: .crypto
    )
    let streamDecryptionResult = performStreamDecryption(
      stream: stream,
      contentLength: contentLength,
      to: outputPath
    )

    switch streamDecryptionResult {
    case .success:
      PubNub.log.debug("File decrypted successfully")
    case let .failure(error):
      PubNub.log.debug("Decryption of file failed due to \(error)")
    }

    return streamDecryptionResult
  }

  /// Decrypts the stream from the given local file URL and writes it to the output path
  ///
  /// - Parameters:
  ///   - from: The local file URL of the encrypted stream
  ///   - to: The path to write the decrypted stream
  /// - Returns:
  ///  - **Success**: A decrypted `InputStream` object
  ///  - **Failure**: `PubNubError` describing the reason of failure
  @discardableResult
  public func decryptStream(from localFileURL: URL, to outputPath: URL) -> Result<InputStream, PubNubError> {
    PubNub.log.debug(
      "Decrypting file",
      category: .crypto
    )

    guard let inputStream = InputStream(url: localFileURL) else {
      PubNub.log.debug(
        "Cannot create InputStream from \(localFileURL). Ensure that the file exists at the specified path",
        category: .crypto
      )
      return .failure(PubNubError(
        .decryptionFailure,
        additional: ["File doesn't exist at \(localFileURL) path"]
      ))
    }

    let streamDecryptionResult = performStreamDecryption(
      stream: inputStream,
      contentLength: localFileURL.sizeOf,
      to: outputPath
    )

    switch streamDecryptionResult {
    case .success:
      PubNub.log.debug("File decrypted successfully", category: .crypto)
    case let .failure(error):
      PubNub.log.debug("Decryption of file failed due to \(error)", category: .crypto)
    }

    return streamDecryptionResult
  }

  private func performStreamDecryption(
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
            additional: ["Decrypting resulted with an empty File"]
          ))
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

  private func cryptor(matching header: CryptorHeader) -> (any Cryptor)? {
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
  public static func == (lhs: CryptoModule, rhs: CryptoModule) -> Bool {
    lhs.cryptors.map { $0.id } == rhs.cryptors.map { $0.id }
  }
}

extension CryptoModule: Hashable {
  public func hash(into hasher: inout Hasher) {
    for cryptor in cryptors {
      hasher.combine(cryptor)
    }
  }
}

extension CryptoModule: CustomStringConvertible {
  public var description: String {
    String.formattedDescription(
      self,
      arguments: [
        ("defaultCryptor", defaultCryptor.id),
        ("cryptors", defaultCryptor.id)
      ]
    )
  }
}

extension CryptoModule {
  func encrypt(string: String) -> Result<Base64EncodedString, PubNubError> {
    PubNub.log.debug(
      "Encrypting String",
      category: .crypto
    )

    let encryptionResult: Result<Base64EncodedString, PubNubError> = if let data = string.data(using: .utf8) {
      encrypt(
        data: data
      ).map {
        $0.base64EncodedString()
      }
    } else {
      .failure(PubNubError(
        .encryptionFailure,
        additional: ["Cannot create Data from provided String"]
      ))
    }

    switch encryptionResult {
    case .success:
      PubNub.log.debug(
        "String encrypted successfully",
        category: .crypto
      )
    case let .failure(error):
      PubNub.log.debug(
        "Encryption of String failed due to \(error)",
        category: .crypto
      )
    }

    return encryptionResult
  }

  func decryptedString(from data: Data) -> Result<String, PubNubError> {
    PubNub.log.debug(
      "Decrypting Data",
      category: .crypto
    )

    let decryptionResult = decrypt(data: data).flatMap {
      if let stringValue = String(data: $0, encoding: .utf8) {
        return .success(stringValue)
      } else {
        return .failure(PubNubError(
          .decryptionFailure,
          additional: ["Cannot create String from provided Data"]
        ))
      }
    }

    switch decryptionResult {
    case .success:
      PubNub.log.debug(
        "Data decrypted successfully",
        category: .crypto
      )
    case let .failure(error):
      PubNub.log.debug(
        "Decryption of Data failed due to \(error)",
        category: .crypto
      )
    }

    return decryptionResult
  }

  // swiftlint:disable:next file_length
}
