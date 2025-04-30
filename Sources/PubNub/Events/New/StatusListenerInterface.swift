//
//  StatusListenerInterface.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A protocol for types that emit PubNub status events from the Subscribe loop.
public protocol StatusListenerInterface: AnyObject {
  /// An underlying queue to dispatch events
  var queue: DispatchQueue { get }
  /// A unique emitter's identifier
  var uuid: UUID { get }
  /// A closure to be called when the connection status changes.
  var onConnectionStateChange: ((ConnectionStatus) -> Void)? { get set }
}

/// Defines additional status listener that can be attached to `Subscription` or `SubscriptionSet`
public class StatusListener: StatusListenerInterface {
  public let uuid: UUID
  public let queue: DispatchQueue
  public var onConnectionStateChange: ((ConnectionStatus) -> Void)?

  public init(
    uuid: UUID = UUID(),
    queue: DispatchQueue = .main,
    onConnectionStateChange: @escaping ((ConnectionStatus) -> Void)
  ) {
    self.uuid = uuid
    self.queue = queue
    self.onConnectionStateChange = onConnectionStateChange
  }
}
