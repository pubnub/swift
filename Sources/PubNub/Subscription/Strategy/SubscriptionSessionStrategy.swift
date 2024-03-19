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

protocol SubscriptionSessionStrategy: AnyObject {
  var uuid: UUID { get }
  var configuration: PubNubConfiguration { get set }
  var subscribedChannels: [String] { get }
  var subscribedChannelGroups: [String] { get }
  var subscriptionCount: Int { get }
  var connectionStatus: ConnectionStatus { get }
  var previousTokenResponse: SubscribeCursor? { get set }
  var filterExpression: String? { get set }
  var listeners: WeakSet<BaseSubscriptionListener> { get set }

  func subscribe(
    to channels: [PubNubChannel],
    and groups: [PubNubChannel],
    at cursor: SubscribeCursor?
  )
  func unsubscribeFrom(
    mainChannels: [PubNubChannel],
    presenceChannelsOnly: [PubNubChannel],
    mainGroups: [PubNubChannel],
    presenceGroupsOnly: [PubNubChannel]
  )

  func reconnect(at cursor: SubscribeCursor?)
  func disconnect()
  func unsubscribeAll()
}
