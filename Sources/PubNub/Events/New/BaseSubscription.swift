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

  public func dispose() {
    guard !(isBeingDisposed.lockedRead { $0 }) else { return }
    clearCallbacks()
    onDispose()
    removeAllListeners()
    isBeingDisposed.lockedWrite { $0 = true }
  }

  func onDispose() {}

  // MARK: - EventListenerHandler

  public func addEventListener(_ listener: EventListener) {
    listenersContainer.storeEventListener(listener)
  }

  public func removeEventListener(_ listener: EventListener) {
    listenersContainer.removeEventListener(listener)
  }

  public func removeAllListeners() {
    listenersContainer.removeAllEventListeners()
  }

  // MARK: - Hashable

  public static func == (lhs: BaseSubscription, rhs: BaseSubscription) -> Bool {
    lhs.uuid == rhs.uuid
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }
}
