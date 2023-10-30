//
//  EventStream.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// An object capable of broadcasting other objects as events
public protocol EventStreamReceiver {
  /// The unique identifier for this listener
  var uuid: UUID { get }
  /// The queue that events will be received on
  var queue: DispatchQueue { get }
}

public extension EventStreamReceiver {
  var queue: DispatchQueue {
    return .main
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }
}

/// Allows for an object to be cancelled
public protocol Cancellable {
  /// Whether this listener has been cancelled
  ///
  /// If this listener has become cancelled you will need to discard it, create a new listener,
  /// and attach it to a PubNub instance in order to continue receiving events
  var isCancelled: Bool { get }

  /// Stop receiving events on this listener
  ///
  /// If this listener has become cancelled you will need to discard it, create a new listener,
  /// and attach it to a PubNub instance in order to continue receiving events
  /// - Important: This is called implicitly in the event the listener falls out of scope and is released
  func cancel()
}

/// An object capable of broadcasting a stream of events to attached listeners
public protocol EventStreamEmitter: AnyObject where ListenerType: Cancellable {
  associatedtype ListenerType

  /// Collection of active event listeners
  var listeners: [ListenerType] { get }
  /// Add a new listener to the list of active listeners
  func add(_ listener: ListenerType)
  /// Remove a listener from the list of active listeners
  func remove(_ listener: ListenerType)
  /// Notify the active listeners of a new event
  func notify(listeners closure: (ListenerType) -> Void)
}

public extension EventStreamEmitter {
  func remove(_ listener: ListenerType) {
    listener.cancel()
  }
}

/// A mechanism to automatically remove a listener from an EventStreamEmitter
public class ListenerToken: Cancellable {
  private let cancelledState = AtomicInt(0)
  private var cancellationClosure: (() -> Void)?

  public var isCancelled: Bool {
    return cancelledState.isEqual(to: 1)
  }

  /// Unique identifer of the token
  public let tokenId = UUID()

  public init(cancellationClosure: @escaping () -> Void) {
    self.cancellationClosure = cancellationClosure
  }

  deinit {
    cancel()
  }

  public func cancel() {
    if cancelledState.bitwiseOrAssignemnt(1) == 0 {
      if let closure = cancellationClosure {
        cancellationClosure = nil
        closure()
      }
    }
  }
}

// MARK: - CustomStringConvertible

extension ListenerToken: CustomStringConvertible {
  public var description: String {
    return "ListenerToken: \(tokenId)"
  }
}
