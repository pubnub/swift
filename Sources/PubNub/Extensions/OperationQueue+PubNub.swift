//
//  OperationQueue+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

extension OperationQueue {
  /// Convenience init that initializes and configures `OperationQueue`
  convenience init(
    qualityOfService: QualityOfService = .default,
    maxConcurrentOperationCount: Int = OperationQueue.defaultMaxConcurrentOperationCount,
    underlyingQueue: DispatchQueue? = nil,
    name: String? = nil,
    startSuspended: Bool = false
  ) {
    self.init()
    self.qualityOfService = qualityOfService
    self.maxConcurrentOperationCount = maxConcurrentOperationCount
    self.underlyingQueue = underlyingQueue
    self.name = name
    isSuspended = startSuspended
  }
}
