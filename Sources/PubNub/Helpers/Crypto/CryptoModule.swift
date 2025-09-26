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
  // swiftlint:disable:previous type_body_length
  private let defaultCryptor: any Cryptor
  private let cryptors: [any Cryptor]
  private let legacyCryptorId: CryptorId = []
  private let logger: PubNubLogger?

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
    self.logger = nil
  }

  init(default cryptor: any Cryptor, cryptors: [any Cryptor] = [], logger: PubNubLogger?) {
    if let logger {
      self.defaultCryptor = cryptor.clone(with: logger)
      self.cryptors = cryptors.map { $0.clone(with: logger) }
    } else {
      self.defaultCryptor = cryptor
      self.cryptors = cryptors
    }
    self.logger = logger
  }

  /// Creates a clone of the `CryptoModule` with a new logger
  func clone(with logger: PubNubLogger) -> CryptoModule {
    CryptoModule(default: defaultCryptor, cryptors: cryptors, logger: logger)
  }

  /// Encrypts the given `Data` object
  ///
  /// - Parameters:
  ///   - data: Data to encrypt
  /// - Returns:
  ///   - **Success**: An encrypted `Data` object
  ///   - **Failure**: `PubNubError` describing the reason of failure
  public func encrypt(data: Data) -> Result<Data, PubNubError> {
    logger?.debug(
      .customObject(
        .init(
          operation: "encrypt-data",
          details: "Execute encrypt",
          arguments: [("data", data.utf8String)]
        )
      ), category: .crypto
    )

    let encryptionResult = performDataEncryption(data: data)

    if case let .failure(error) = encryptionResult {
      logger?.error(
        .customObject(
          .init(
            operation: "encrypt-data-failure",
            details: "Data encryption failed",
            arguments: [
              ("errorReason", error.reason),
              ("dataSize", data.count)
            ]
          )
        ),
        category: .crypto
      )
      logger?.debug(
        .customObject(
          .init(
            operation: "encrypt-data-failure-details",
            details: "Detailed encryption failure information",
            arguments: [("error", error)]
          )
        ),
        category: .crypto
      )
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
    logger?.debug(
      .customObject(
        .init(
          operation: "decrypt-data",
          details: "Decrypting Data"
        )
      ),
      category: .crypto
    )

    let decryptionResult = performDataDecryption(data: data)

    if case let .failure(error) = decryptionResult {
      logger?.error(
        .customObject(
          .init(
            operation: "decrypt-data-failure",
            details: "Data decryption failed",
            arguments: [
              ("errorReason", error.reason),
              ("dataSize", data.count)
            ]
          )
        ),
        category: .crypto
      )

      logger?.debug(
        .customObject(
          .init(
            operation: "decrypt-data-failure-details",
            details: "Detailed decryption failure information",
            arguments: [("error", error)]
          )
        ),
        category: .crypto
      )
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
        let error = PubNubError(
          .unknownCryptorFailure,
          additional: ["No matching Cryptor for ID: \(header.cryptorId())"]
        )

        logger?.error(
          .customObject(
            .init(
              operation: "unknown-cryptor-failure",
              details: "No matching Cryptor found for decryption",
              arguments: [
                ("cryptorId", header.cryptorId()),
                ("availableCryptors", cryptors.map { $0.id }),
                ("defaultCryptorId", defaultCryptor.id)
              ]
            )
          ),
          category: .crypto
        )

        return .failure(error)
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
    logger?.debug(
      .customObject(
        .init(
          operation: "encrypt-stream",
          details: "Execute encrypt",
          arguments: [
            ("stream", stream.description),
            ("contentLength", contentLength)
          ]
        )
      ),
      category: .crypto
    )

    let streamEncryptionResult = performStreamEncryption(
      stream: stream,
      contentLength: contentLength
    )

    if case let .failure(error) = streamEncryptionResult {
      logger?.debug(
        .customObject(
          .init(
            operation: "encrypt-stream-failure",
            details: "Encryption of File failed",
            arguments: [("error", error)]
          )
        ),
        category: .crypto
      )
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
      logger?.debug(
        .customObject(
          .init(
            operation: "encrypt-stream-failure",
            details: "Cannot create InputStream from the given path. Ensure that the file exists at the specified path"
          )
        ),
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

    if case let .failure(error) = streamEncryptionResult {
      logger?.debug(
        .customObject(
          .init(
            operation: "encrypt-stream-failure",
            details: "Encryption of File failed",
            arguments: [("error", error)]
          )
        ),
        category: .crypto
      )
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
    logger?.debug(
      .customObject(
        .init(
          operation: "decrypt-stream",
          details: "Execute decrypt",
          arguments: [
            ("stream", stream.description),
            ("contentLength", contentLength),
            ("to", outputPath.absoluteString)
          ]
        )
      ),
      category: .crypto
    )

    let streamDecryptionResult = performStreamDecryption(
      stream: stream,
      contentLength: contentLength,
      to: outputPath
    )

    if case let .failure(error) = streamDecryptionResult {
      logger?.debug(
        .customObject(
          .init(
            operation: "decrypt-stream-failure",
            details: "Decryption of File failed",
            arguments: [("error", error)]
          )
        ),
        category: .crypto
      )
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
    logger?.debug(
      .customObject(
        .init(
          operation: "decrypt-stream",
          details: "Execute decryptStream",
          arguments: [
            ("from", localFileURL.absoluteString),
            ("to", outputPath.absoluteString)
          ]
        )
      ),
      category: .crypto
    )

    guard let inputStream = InputStream(url: localFileURL) else {
      logger?.debug(
        .customObject(
          .init(
            operation: "decrypt-stream-failure",
            details: "Cannot create InputStream. Ensure that the file exists at the specified path",
            arguments: [("localFileUrl", localFileURL.absoluteString)]
          )
        ),
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

    if case let .failure(error) = streamDecryptionResult {
      logger?.debug(
        .customObject(
          .init(
            operation: "decrypt-stream-failure",
            details: "Decryption of File failed",
            arguments: [("error", error)]
          )
        ),
        category: .crypto
      )
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
        let error = PubNubError(
          .unknownCryptorFailure,
          additional: ["No matching Cryptor for ID: \(readHeaderResp.header.cryptorId())"]
        )

        logger?.error(
          .customObject(
            .init(
              operation: "unknown-cryptor-failure",
              details: "No matching cryptor found for stream decryption",
              arguments: [
                ("cryptorId", readHeaderResp.header.cryptorId()),
                ("availableCryptors", cryptors.map { $0.id }),
                ("defaultCryptorId", defaultCryptor.id)
              ]
            )
          ),
          category: .crypto
        )

        return .failure(error)
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
    String.logDescription(
      of: self,
      arguments: [
        ("defaultCryptor", defaultCryptor.id),
        ("cryptors", defaultCryptor.id)
      ]
    )
  }
}

extension CryptoModule {
  func encrypt(string: String) -> Result<Base64EncodedString, PubNubError> {
    logger?.debug(
      .customObject(
        .init(
          operation: "encrypt-string",
          details: "Execute encrypt",
          arguments: [("string", string)]
        )
      ), category: .crypto
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

    if case let .failure(error) = encryptionResult {
      logger?.debug(
        .customObject(
          .init(
            operation: "encrypt-string-failure",
            details: "Encryption of String failed",
            arguments: [("error", error)]
          )
        ),
        category: .crypto
      )
    }

    return encryptionResult
  }

  func decryptedString(from data: Data) -> Result<String, PubNubError> {
    logger?.debug(
      .customObject(
        .init(
          operation: "decrypt-data",
          details: "Decrypt Data",
          arguments: [("data", data.utf8String)]
        )
      ),
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

    if case let .failure(error) = decryptionResult {
      logger?.error(
        .customObject(
          .init(
            operation: "decrypt-string-failure",
            details: "String decryption failed",
            arguments: [
              ("errorReason", error.reason),
              ("dataSize", data.count)
            ]
          )
        ),
        category: .crypto
      )

      logger?.debug(
        .customObject(
          .init(
            operation: "decrypt-string-failure-details",
            details: "Detailed string decryption failure information",
            arguments: [("error", error)]
          )
        ),
        category: .crypto
      )
    }

    return decryptionResult
  }

  // swiftlint:disable:next file_length
}
