//
//  SubscriptionSessionStrategy.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

protocol SubscriptionSessionStrategy: EventStreamEmitter where ListenerType == BaseSubscriptionListener {
  var uuid: UUID { get }
  var configuration: PubNubConfiguration { get set }
  var subscribedChannels: [String] { get }
  var subscribedChannelGroups: [String] { get }
  var subscriptionCount: Int { get }
  var connectionStatus: ConnectionStatus { get }
  var previousTokenResponse: SubscribeCursor? { get set }

  func subscribe(to channels: [String], and groups: [String], at cursor: SubscribeCursor?, withPresence: Bool)
  func unsubscribe(from channels: [String], and groups: [String], presenceOnly: Bool)
  func reconnect(at cursor: SubscribeCursor?)
  func disconnect()
  func unsubscribeAll()
}
