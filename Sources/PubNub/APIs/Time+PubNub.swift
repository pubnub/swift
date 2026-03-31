//
//  Time+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - Time

public extension PubNub {
  /// Get current `Timetoken` from System
  ///
  /// - Parameters:
  ///   - custom: Custom configuration overrides for this request
  ///   - completion: The async `Result` of the method call
  ///     - **Success**: The current `Timetoken`
  ///     - **Failure**: An `Error` describing the failure
  func time(
    custom requestConfig: RequestConfiguration = RequestConfiguration(),
    completion: ((Result<Timetoken, Error>) -> Void)?
  ) {
    logger.debug(
      .customObject(
        .init(
          operation: "time",
          details: "Get current Timetoken",
          arguments: [("custom", requestConfig)]
        )
      ), category: .pubNub
    )

    route(
      TimeRouter(.time, configuration: requestConfig.customConfiguration ?? configuration),
      responseDecoder: TimeResponseDecoder(),
      custom: requestConfig
    ) { result in
      completion?(result.map { $0.payload.timetoken })
    }
  }
}
