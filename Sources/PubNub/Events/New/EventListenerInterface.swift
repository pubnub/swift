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
public protocol StatusListenerInterface: AnyObject {
  /// An underlying queue to dispatch events
  var queue: DispatchQueue { get }
  /// A unique emitter's identifier
  var uuid: UUID { get }
  /// A closure to be called when the connection status changes.
  var onConnectionStateChange: ((ConnectionStatus) -> Void)? { get set }
}

/// Concrete implementation of `StatusListenerInterface`
public class StatusListener: StatusListenerInterface {
  public let uuid: UUID
  public let queue: DispatchQueue
  public var onConnectionStateChange: ((ConnectionStatus) -> Void)?

  init(
    uuid: UUID = UUID(),
    queue: DispatchQueue = .main,
    onConnectionStateChange: @escaping ((ConnectionStatus) -> Void)
  ) {
    self.uuid = uuid
    self.queue = queue
    self.onConnectionStateChange = onConnectionStateChange
  }
}

// MARK: - EventListenerInterface

/// A protocol for types that emit PubNub events.
///
/// Utilize closures to receive notifications when specific types of PubNub events occur.
public protocol EventListenerInterface: AnyObject {
  /// An underlying queue to dispatch events
  var queue: DispatchQueue { get }
  /// A unique emitter's identifier
  var uuid: UUID { get }
  /// Receiver for a single event
  var onEvent: ((PubNubEvent) -> Void)? { get set }
  /// Receiver for multiple events. This will also emit individual events to `onEvent:`
  var onEvents: (([PubNubEvent]) -> Void)? { get set }
  /// Receiver for Message events
  var onMessage: ((PubNubMessage) -> Void)? { get set }
  /// Receiver for Signal events
  var onSignal: ((PubNubMessage) -> Void)? { get set }
  /// Receiver for Presence events
  var onPresence: ((PubNubPresenceChange) -> Void)? { get set }
  /// Receiver for Message Action events
  var onMessageAction: ((PubNubMessageActionEvent) -> Void)? { get set }
  /// Receiver for File events
  var onFileEvent: ((PubNubFileChangeEvent) -> Void)? { get set }
  /// Receiver for App Context events
  var onAppContext: ((PubNubAppContextEvent) -> Void)? { get set }
}

/// A protocol representing a type that can be utilized to dispose of a conforming object.
public protocol SubscriptionDisposable {
  /// Determines whether current emitter is disposed
  var isDisposed: Bool { get }
  /// Stops listening to incoming events and disposes current emitter
  func dispose()
}

/// A protocol representing an additional listener that can be added or removed
public protocol EventListenerHandler {
  func addEventListener(_ listener: EventListenerInterface)
  func removeEventListener(_ listener: EventListenerInterface)
}

/// A concrete implementation for `EventListenerInterface`
public class EventListener: EventListenerInterface {
  public let queue: DispatchQueue
  public let uuid: UUID
  public var onEvent: ((PubNubEvent) -> Void)?
  public var onEvents: (([PubNubEvent]) -> Void)?
  public var onMessage: ((PubNubMessage) -> Void)?
  public var onSignal: ((PubNubMessage) -> Void)?
  public var onPresence: ((PubNubPresenceChange) -> Void)?
  public var onMessageAction: ((PubNubMessageActionEvent) -> Void)?
  public var onFileEvent: ((PubNubFileChangeEvent) -> Void)?
  public var onAppContext: ((PubNubAppContextEvent) -> Void)?
  
  init(
    queue: DispatchQueue = .main,
    uuid: UUID = UUID(),
    onEvent: ((PubNubEvent) -> Void)? = nil,
    onEvents: (([PubNubEvent]) -> Void)? = nil,
    onMessage: ((PubNubMessage) -> Void)? = nil,
    onSignal: ((PubNubMessage) -> Void)? = nil,
    onPresence: ((PubNubPresenceChange) -> Void)? = nil,
    onMessageAction: ((PubNubMessageActionEvent) -> Void)? = nil,
    onFileEvent: ((PubNubFileChangeEvent) -> Void)? = nil,
    onAppContext: ((PubNubAppContextEvent) -> Void)? = nil
  ) {
    self.queue = queue
    self.uuid = uuid
    self.onEvent = onEvent
    self.onEvents = onEvents
    self.onMessage = onMessage
    self.onSignal = onSignal
    self.onPresence = onPresence
    self.onMessageAction = onMessageAction
    self.onFileEvent = onFileEvent
    self.onAppContext = onAppContext
  }
}

extension EventListenerInterface {
  func emit(events: [PubNubEvent]) {
    queue.async { [weak self] in
      if !events.isEmpty {
        self?.onEvents?(events)
      }
      for event in events {
        self?.onEvent?(event)
        switch event {
        case let .messageReceived(message):
          self?.onMessage?(message)
        case let .signalReceived(signal):
          self?.onSignal?(signal)
        case let .presenceChanged(presence):
          self?.onPresence?(presence)
        case let .appContextChanged(appContextEvent):
          self?.onAppContext?(appContextEvent)
        case let .messageActionChanged(messageActionEvent):
          self?.onMessageAction?(messageActionEvent)
        case let .fileChanged(fileEvent):
          switch fileEvent {
          case let .uploaded(fileInfo):
            self?.onFileEvent?(.uploaded(fileInfo))
          }
        }
      }
    }
  }
}

extension EventListenerInterface {
  func clearCallbacks() {
    onEvent = nil
    onEvents = nil
    onMessage = nil
    onSignal = nil
    onPresence = nil
    onMessageAction = nil
    onFileEvent = nil
    onAppContext = nil
  }
}

// `SubscribeMessagesReceiver` is an internal protocol defining a receiver for subscription messages.
// Types that conform to this protocol are responsible for handling and processing these payloads
// into concrete events for the user.
protocol SubscribeMessagesReceiver: AnyObject {
  // A dictionary representing the names of the underlying subscriptions
  var subscriptionTopology: [SubscribableType: [String]] { get }
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
