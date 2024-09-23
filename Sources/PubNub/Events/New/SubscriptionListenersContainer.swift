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
  private let eventListenersCache: Atomic<[UUID: EventListener]> = Atomic([:])
  private let statusListenersCache: Atomic<[UUID: StatusListener]> = Atomic([:])

  var eventListeners: [EventListener] {
    eventListenersCache.lockedRead { $0.values.compactMap { $0 } }
  }

  var statusListeners: [StatusListener] {
    statusListenersCache.lockedRead { $0.values.compactMap { $0 } }
  }

  func storeEventListener(_ eventListener: EventListener) {
    eventListenersCache.lockedWrite { $0[eventListener.uuid] = eventListener }
  }

  func storeStatusListener(_ statusListener: StatusListener) {
    statusListenersCache.lockedWrite { $0[statusListener.uuid] = statusListener }
  }

  func removeEventListener(_ listener: EventListener) {
    eventListenersCache.lockedWrite { $0[listener.uuid] = nil }
  }

  func removeStatusListener(_ listener: StatusListener) {
    statusListenersCache.lockedWrite { $0[listener.uuid] = nil }
  }

  func removeAllEventListeners() {
    eventListenersCache.lockedWrite { $0.removeAll() }
  }

  func removeAllStatusListeners() {
    statusListenersCache.lockedWrite { $0.removeAll() }
  }
}
