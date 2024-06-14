//
//  WeakStatusListenerBox.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class SubscriptionListenersContainer {
  private var eventListenersCache: [UUID: WeakListenerBox<EventListener>] = [:]
  private var statusListenersCache: [UUID: WeakListenerBox<StatusListener>] = [:]

  var eventListeners: [EventListenerInterface] {
    eventListenersCache.values.compactMap { $0.listener }
  }

  var statusListeners: [StatusListenerInterface] {
    statusListenersCache.values.compactMap { $0.listener }
  }

  func storeEventListener(_ eventListener: EventListener) {
    eventListenersCache[eventListener.uuid] = WeakListenerBox<EventListener>(
      listener: eventListener,
      onCancellation: { [weak self, weak eventListener] in
        if let eventListener {
          self?.eventListenersCache.removeValue(forKey: eventListener.uuid)
        }
      }
    )
  }

  func storeStatusListener(_ statusListener: StatusListener) {
    statusListenersCache[statusListener.uuid] = WeakListenerBox<StatusListener>(
      listener: statusListener,
      onCancellation: { [weak statusListener, weak self] in
        if let statusListener {
          self?.statusListenersCache.removeValue(forKey: statusListener.uuid)
        }
      }
    )
  }

  func removeEventListener(with key: UUID) {
    eventListenersCache[key] = nil
  }

  func removeStatusListener(with key: UUID) {
    statusListenersCache[key] = nil
  }
  
  func removeAllEventListeners() {
    eventListenersCache.removeAll()
  }
  
  func removeAllStatusListeners() {
    statusListenersCache.removeAll()
  }
}

private class WeakListenerBox<T: AnyObject> {
  private var onCancellation: (() -> Void)?

  weak var listener: T? {
    willSet {
      if newValue == nil {
        onCancellation?()
      }
    }
  }

  init(listener: T, onCancellation: @escaping () -> Void) {
    self.listener = listener
    self.onCancellation = onCancellation
  }

  deinit {
    listener = nil
  }
}
