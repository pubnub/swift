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
  private var eventListenersCache: [UUID: EventListener] = [:]
  private var statusListenersCache: [UUID: StatusListener] = [:]

  var eventListeners: [EventListener] {
    eventListenersCache.values.compactMap { $0 }
  }

  var statusListeners: [StatusListener] {
    statusListenersCache.values.compactMap { $0 }
  }

  func storeEventListener(_ eventListener: EventListener) {
    eventListenersCache[eventListener.uuid] = eventListener
  }

  func storeStatusListener(_ statusListener: StatusListener) {
    statusListenersCache[statusListener.uuid] = statusListener
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
