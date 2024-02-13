//
//  EventEmitter.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// MARK: - StatusEmitter

/// A protocol for types that emit PubNub status events from the Subscribe loop.
public protocol StatusEmitter: AnyObject {
  /// A closure to be called when the connection status changes.
  var didReceiveConnectionStatusChange: ((ConnectionStatus) -> Void)? { get set }
  /// A closure to be called when a subscription error occurs.
  var didReceiveSubscribeError: ((PubNubError) -> Void)? { get set }
}

// MARK: - EventEmitter

/// A protocol for types that emit PubNub events.
///
/// Utilize closures to receive notifications when specific types of PubNub events occur.
public protocol EventEmitter: AnyObject {
  /// An underlying queue to dispatch events
  var queue: DispatchQueue { get }
  /// A unique emitter's identifier
  var uuid: UUID { get }
  /// Receiver for a single event
  var eventStream: ((PubNubEvent) -> Void)? { get set }
  /// Receiver for multiple events. This will also emit individual events to `eventStream:`
  var eventsStream: (([PubNubEvent]) -> Void)? { get set }
  /// Receiver for Message events
  var messagesStream: ((PubNubMessage) -> Void)? { get set }
  /// Receiver for Signal events
  var signalsStream: ((PubNubMessage) -> Void)? { get set }
  /// Receiver for Presence events
  var presenceStream: ((PubNubPresenceChange) -> Void)? { get set }
  /// Receiver for Message Action events
  var messageActionsStream: ((PubNubMessageActionEvent) -> Void)? { get set }
  /// Receiver for File Upload events
  var filesStream: ((PubNubFileEvent) -> Void)? { get set }
  /// Receiver for App Context events
  var appContextStream: ((PubNubAppContextEvent) -> Void)? { get set }
}

/// A protocol representing a type that can be used to dispose of subscriptions.
public protocol SubscriptionDisposable {
  /// Determines whether current emitter is disposed
  var isDisposed: Bool { get }
  /// Stops listening to incoming events and disposes current emitter
  func dispose()
}

extension EventEmitter {
  func emit(events: [PubNubEvent]) {
    queue.async { [weak self] in
      if !events.isEmpty {
        self?.eventsStream?(events)
      }
      for event in events {
        self?.eventStream?(event)
        switch event {
        case let .messageReceived(message):
          self?.messagesStream?(message)
        case let .signalReceived(signal):
          self?.signalsStream?(signal)
        case let .presenceChange(presence):
          self?.presenceStream?(presence)
        case let .appContextEvent(appContextEvent):
          self?.appContextStream?(appContextEvent)
        case let .messageActionEvent(messageActionEvent):
          self?.messageActionsStream?(messageActionEvent)
        case let .fileUploadEvent(fileEvent):
          self?.filesStream?(fileEvent)
        }
      }
    }
  }
}

extension EventEmitter {
  func clearCallbacks() {
    eventStream = nil
    eventsStream = nil
    messagesStream = nil
    signalsStream = nil
    presenceStream = nil
    messageActionsStream = nil
    filesStream = nil
    appContextStream = nil
  }
}

// `SubscribeMessagesReceiver` is an internal protocol defining a receiver for subscription messages.
// Types that conform to this protocol are responsible for handling and processing these payloads
// into concrete events for the user.
protocol SubscribeMessagesReceiver: AnyObject {
  // A dictionary representing the names of the underlying subscriptions
  var subscriptionTopology: [SubscribableType : [String]] { get }
  // This method should return an array of `PubNubEvent` instances,
  // representing the concrete events for the user.
  @discardableResult func onPayloadsReceived(payloads: [SubscribeMessagePayload]) -> [PubNubEvent]
}

// An internal class that functions as a bridge between the legacy `BaseSubscriptionListener`
// and either `Subscription` or `SubscriptionSet`, forwarding the received payloads.
class BaseSubscriptionListenerAdapter: BaseSubscriptionListener {
  private(set) weak var receiver: SubscribeMessagesReceiver?
  
  init(receiver: SubscribeMessagesReceiver, uuid: UUID, queue: DispatchQueue) {
    self.receiver = receiver
    super.init(queue: queue, uuid: uuid)
  }
  
  override func emit(batch: [SubscribeMessagePayload]) {
    if let receiver = receiver {
      receiver.onPayloadsReceived(payloads: batch)
    }
  }
  
  deinit {
    cancel()
  }
}
