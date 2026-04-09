//
//  BaseSubscription.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A base class providing shared functionality for `Subscription` and `SubscriptionSet`.
///
/// This class is not intended to be instantiated or subclassed directly by external consumers.
public class BaseSubscription: EventListenerInterface, EventListenerHandler, Hashable {
  public let queue: DispatchQueue
  public let uuid: UUID = UUID()
  public let options: SubscriptionOptions

  let listenersContainer: SubscriptionListenersContainer = .init()
  let isBeingDisposed: Atomic<Bool> = .init(false)

  public var onEvent: ((PubNubEvent) -> Void)?
  public var onEvents: (([PubNubEvent]) -> Void)?
  public var onMessage: ((PubNubMessage) -> Void)?
  public var onSignal: ((PubNubMessage) -> Void)?
  public var onPresence: ((PubNubPresenceChange) -> Void)?
  public var onMessageAction: ((PubNubMessageActionEvent) -> Void)?
  public var onFileEvent: ((PubNubFileChangeEvent) -> Void)?
  public var onAppContext: ((PubNubAppContextEvent) -> Void)?

  init(queue: DispatchQueue, options: SubscriptionOptions) {
    self.queue = queue
    self.options = options
  }

  deinit {
    dispose()
  }

  public var isDisposed: Bool {
    isBeingDisposed.lockedRead { $0 }
  }

  /// Disposes the subscription, performing cleanup and making subsequent calls a no-op.
  /// Clears any stored callback closures, invokes the `onDispose()` hook, removes all registered listeners, and marks the subscription as disposed so future `dispose()` calls have no effect.
  public func dispose() {
    guard !(isBeingDisposed.lockedRead { $0 }) else { return }
    clearCallbacks()
    onDispose()
    removeAllListeners()
    isBeingDisposed.lockedWrite { $0 = true }
  }

  /// Called during the disposal sequence to allow subclasses to perform cleanup.
/// 
/// The default implementation does nothing. Subclasses may override this method to release resources or perform teardown work when the subscription is being disposed.
func onDispose() {}

  /// Registers an event listener to receive subscription events.
  /// - Parameter listener: The `EventListener` instance to register for receiving events.

  public func addEventListener(_ listener: EventListener) {
    listenersContainer.storeEventListener(listener)
  }

  /// Removes a previously registered event listener from this subscription.
  /// - Parameter listener: The `EventListener` instance to remove.
  public func removeEventListener(_ listener: EventListener) {
    listenersContainer.removeEventListener(listener)
  }

  /// Removes all event listeners registered with this subscription.
  /// 
  /// This only unregisters listeners previously added via `addEventListener(_:)`; it does not clear the subscription's callback closures.
  public func removeAllListeners() {
    listenersContainer.removeAllEventListeners()
  }

  /// Determines whether two `BaseSubscription` instances represent the same subscription by comparing their UUIDs.
  /// - Returns: `true` if both subscriptions have the same `uuid`, `false` otherwise.

  public static func == (lhs: BaseSubscription, rhs: BaseSubscription) -> Bool {
    lhs.uuid == rhs.uuid
  }

  /// Hashes the subscription's identity into the provided hasher.
  /// - Parameters:
  ///   - hasher: The hasher to incorporate this subscription's UUID into.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }
}
