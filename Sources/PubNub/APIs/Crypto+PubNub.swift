//
//  Crypto+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Crypto

public extension PubNub {
  /// Encrypts the `Data` object using `CryptoModule` provided in configuration
  /// - Parameter message: The plain text message to be encrypted
  /// - Returns: A `Result` containing either the encryped `Data` (mapped to Base64-encoded data) or the `CryptoError`
  func encrypt(message: String) -> Result<Data, Error> {
    logger.debug(
      .customObject(
        .init(
          operation: "encrypt",
          details: "Execute encrypt",
          arguments: [("message", message)]
        )
      ), category: .crypto
    )

    guard let cryptoModule = configuration.cryptoModule else {
      logger.debug(
        .customObject(
          .init(
            operation: "encrypt",
            details: "Encryption of a String message failed due to \(ErrorDescription.missingCryptoKey)"
          )
        ), category: .crypto
      )
      return .failure(CryptoError.invalidKey)
    }

    guard let dataMessage = message.data(using: .utf8) else {
      logger.debug(
        .customObject(
          .init(
            operation: "encrypt",
            details: "Encryption of a String message failed due to \("invalid UTF-8 encoded String")",
            arguments: [("message", message)]
          )
        ), category: .crypto
      )
      return .failure(CryptoError.decodeError)
    }

    let encryptionResult = cryptoModule.encrypt(data: dataMessage).map {
      $0.base64EncodedData()
    }.mapError {
      $0 as Error
    }

    if case let .failure(error) = encryptionResult {
      logger.debug(
        .customObject(
          .init(
            operation: "encrypt",
            details: "Encryption of a String message failed due to \(error)",
            arguments: [("message", message), ("error", error)]
          )
        ), category: .crypto
      )
    }

    return encryptionResult
  }

  /// Decrypts the given `Data` object using `CryptoModule` provided in `configuration`
  /// - Parameter data: The encrypted `Data` to decrypt
  /// - Returns: A `Result` containing either the decrypted plain text message or the `CryptoError`
  func decrypt(data: Data) -> Result<String, Error> {
    logger.debug(
      .customObject(.init(
        operation: "decrypt",
        details: "Decrypt a Data message",
        arguments: [("data.count", data.count)]
      )), category: .crypto
    )

    guard let cryptoModule = configuration.cryptoModule else {
      logger.debug(
        .customObject(
          .init(
            operation: "decrypt",
            details: "Decryption of Data failed due to \(ErrorDescription.missingCryptoKey)",
            arguments: [("data.count", data.count)]
          )
        ), category: .crypto
      )

      return .failure(CryptoError.invalidKey)
    }
    guard let base64EncodedData = Data(base64Encoded: data) else {
      logger.debug(
        .customObject(
          .init(
            operation: "decrypt",
            details: "Decryption of Data failed due to \("invalid Base64-encoded Data")",
            arguments: [("data.count", data.count)]
          )
        ), category: .crypto
      )
      return .failure(CryptoError.decodeError)
    }

    let decryptionResult = cryptoModule.decrypt(data: base64EncodedData)
      .flatMap { data -> Result<String, PubNubError> in
        guard let string = String(data: data, encoding: .utf8) else {
          return .failure(PubNubError(.decryptionFailure, additional: ["Cannot create String from received bytes"]))
        }
        return .success(string)
      }
      .mapError {
        $0 as Error
      }

    if case let .failure(error) = decryptionResult {
      logger.debug(
        .customObject(
          .init(
            operation: "decrypt",
            details: "Decryption of Data failed due to \(error)",
            arguments: [("data.count", data.count), ("error", error)]
          )
        ), category: .crypto
      )
    }

    return decryptionResult
  }
}
