//
//  SubscriptionSession.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@available(*, deprecated, message: "Subscribe and unsubscribe using methods from a PubNub object")
public class SubscriptionSession {
  /// An unique identifier for subscription session
  public var uuid: UUID {
    strategy.uuid
  }
  
  /// PSV2 feature to subscribe with a custom filter expression.
  @available(*, deprecated, message: "Use `subscribeFilterExpression` from a PubNub object")
  public var filterExpression: String? {
    get {
      strategy.filterExpression
    } set {
      strategy.filterExpression = newValue
    }
  }
  
  private let strategy: any SubscriptionSessionStrategy
  
  var previousTokenResponse: SubscribeCursor? {
    strategy.previousTokenResponse
  }
  
  var configuration: SubscriptionConfiguration {
    get {
      strategy.configuration
    } set {
      strategy.configuration = newValue
    }
  }
  
  internal init(strategy: any SubscriptionSessionStrategy) {
    self.strategy = strategy
  }

  /// Names of all subscribed channels
  ///
  /// This list includes both regular and presence channel names
  public var subscribedChannels: [String] {
    strategy.subscribedChannels
  }
  
  /// List of actively subscribed groups
  public var subscribedChannelGroups: [String] {
    strategy.subscribedChannelGroups
  }

  /// Combined value of all subscribed channels and groups
  public var subscriptionCount: Int {
    strategy.subscriptionCount
  }
  
  /// Current connection status
  public var connectionStatus: ConnectionStatus {
    strategy.connectionStatus
  }
        
  // MARK: - Subscription Loop

  /// Subscribe to channels and/or channel groups
  ///
  /// - Parameters:
  ///   - to: List of channels to subscribe on
  ///   - and: List of channel groups to subscribe on
  ///   - at: The timetoken to subscribe with
  ///   - withPresence: If true it also subscribes to presence events on the specified channels.
  ///   - setting: The object containing the state for the channel(s).
  public func subscribe(
    to channels: [String],
    and groups: [String] = [],
    at cursor: SubscribeCursor? = nil,
    withPresence: Bool = false
  ) {
    strategy.subscribe(
      to: channels,
      and: groups,
      at: cursor,
      withPresence: withPresence
    )
  }

  /// Reconnect a disconnected subscription stream
  /// - parameter timetoken: The timetoken to subscribe with
  public func reconnect(at cursor: SubscribeCursor? = nil) {
    strategy.reconnect(at: cursor)
  }

  /// Disconnect the subscription stream
  public func disconnect() {
    strategy.disconnect()
  }

  // MARK: - Unsubscribe

  /// Unsubscribe from channels and/or channel groups
  ///
  /// - Parameters:
  ///   - from: List of channels to unsubscribe from
  ///   - and: List of channel groups to unsubscribe from
  ///   - presenceOnly: If true, it only unsubscribes from presence events on the specified channels.
  public func unsubscribe(from channels: [String], and groups: [String] = [], presenceOnly: Bool = false) {
    strategy.unsubscribe(
      from: channels,
      and: groups,
      presenceOnly: presenceOnly
    )
  }

  /// Unsubscribe from all channels and channel groups
  public func unsubscribeAll() {
    strategy.unsubscribeAll()
  }
}

extension SubscriptionSession: EventStreamEmitter {
  public typealias ListenerType = BaseSubscriptionListener

  public var listeners: [ListenerType] {
    strategy.listeners
  }

  public func add(_ listener: ListenerType) {
    strategy.add(listener)
  }

  public func notify(listeners closure: (ListenerType) -> Void) {
    strategy.notify(listeners: closure)
  }
}

extension SubscriptionSession: Hashable, CustomStringConvertible {
  public static func == (lhs: SubscriptionSession, rhs: SubscriptionSession) -> Bool {
    lhs.uuid == rhs.uuid
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }

  public var description: String {
    uuid.uuidString
  }
}
