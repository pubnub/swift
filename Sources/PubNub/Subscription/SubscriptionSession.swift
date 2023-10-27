//
//  SubscriptionSession.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

@available(*, deprecated)
public class SubscriptionSession {
  /// An unique identifier for subscription session
  public var uuid: UUID {
    strategy.uuid
  }
  
  /// PSV2 feature to subscribe with a custom filter expression.
  @available(*, unavailable)
  public var filterExpression: String?

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
