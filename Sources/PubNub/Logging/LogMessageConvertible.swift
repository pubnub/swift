//
//  LogMessageConvertible.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - LogMessageConvertible

/// A protocol that allows types to be converted into ``LogMessage`` instances
public protocol LogMessageConvertible {
  /// Converts the conforming type to a LogMessage
  ///
  /// - Parameters:
  ///   - pubNubId: The PubNub instance identifier
  ///   - logLevel: The log level as a string
  ///   - category: The category of the log message
  ///   - location: Optional location information
  /// - Returns: A LogMessage instance
  func toLogMessage(
    pubNubId: String,
    logLevel: LogLevel,
    category: LogCategory,
    location: String?
  ) -> LogMessage
}

/// A default implementation of the `LogMessageConvertible` protocol for `String`
extension String: LogMessageConvertible {
  public func toLogMessage(pubNubId: String, logLevel: LogLevel, category: LogCategory, location: String?) -> LogMessage {
    BaseLogMessage(
      pubNubId: pubNubId,
      logLevel: logLevel,
      category: category,
      location: location,
      type: "text",
      message: LogMessageContent.text(self),
      details: nil,
      additionalFields: [:]
    )
  }
}
