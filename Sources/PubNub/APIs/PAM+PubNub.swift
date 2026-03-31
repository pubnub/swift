//
//  PAM+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - PAM

public extension PubNub {
  /// Extract permissions from provided token
  ///
  /// - Parameter token: The token from which permissions should be extracted.
  /// - Returns: PAMToken with permissions information.
  func parse(token: String) -> PAMToken? {
    do {
      return try PAMToken.token(from: token)
    } catch PAMToken.PAMTokenError.invalidEscapedToken {
      logger.error(
        .customObject(
          .init(
            operation: "pam-token-parse-failure",
            details: "PAM token parsing failed - invalid escaped token",
            arguments: [
              ("errorType", "invalidEscapedToken"),
              ("tokenLength", token.count)
            ]
          )
        ), category: .pubNub
      )
    } catch PAMToken.PAMTokenError.invalidBase64EncodedToken {
      logger.error(
        .customObject(
          .init(
            operation: "pam-token-parse-failure",
            details: "PAM token parsing failed - invalid Base64 encoding",
            arguments: [
              ("errorType", "invalidBase64EncodedToken"),
              ("tokenLength", token.count)
            ]
          )
        ), category: .pubNub
      )
    } catch PAMToken.PAMTokenError.invalidCBOR(let cborError) {
      logger.error(
        .customObject(
          .init(
            operation: "pam-token-parse-failure",
            details: "PAM token parsing failed - invalid CBOR format",
            arguments: [
              ("errorType", "invalidCBOR"),
              ("tokenLength", token.count)
            ]
          )
        ), category: .pubNub
      )
      logger.trace(
        .customObject(
          .init(
            operation: "pam-token-parse-failure",
            details: "CBOR error details",
            arguments: [
              ("errorType", "invalidCBOR"),
              ("cborError", cborError)
            ]
          )
        )
      )
    } catch {
      logger.error(
        .customObject(
          .init(
            operation: "pam-token-parse-failure",
            details: "PAM token parsing failed - unknown error",
            arguments: [
              ("errorType", "unknown"),
              ("tokenLength", token.count)
            ]
          )
        ), category: .pubNub
      )
    }

    // Single debug log for all PAM token parsing failures
    logger.trace(
      .customObject(
        .init(
          operation: "pam-token-parse-failure-details",
          details: "PAM token parsing failed (debug details)",
          arguments: [("token", token)]
        )
      ), category: .pubNub
    )

    return nil
  }
}
