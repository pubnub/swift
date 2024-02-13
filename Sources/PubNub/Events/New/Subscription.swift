//
//  PubNubSubscription.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A final class representing a PubNub subscription.
///
/// Use this class to create and manage subscriptions for a specific `Subscribable` entity.
/// It conforms to `EventEmitter`, allowing the handling of subscription-related events.
public final class Subscription: EventEmitter, SubscriptionDisposable {
  /// Initializes a `Subscription` object.
  ///
  /// - Parameters:
  ///   - queue: An underlying queue to dispatch events
  ///   - entity: An object that should be added to the Subscribe loop.
  ///   - options: Additional subscription options
  public init(
    queue: DispatchQueue = .main,
    entity: Subscribable,
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) {
    self.queue = queue
    self.entity = entity
    self.options = SubscriptionOptions.empty() + options
  }
  
  public let queue: DispatchQueue
  /// A unique identifier for `Subscription`
  public let uuid: UUID = UUID()
  /// An underlying entity that should be added to the Subscribe loop
  public let entity: Subscribable
  /// Attached options
  public let options: SubscriptionOptions
  /// Whether current subscription is disposed or not
  public private(set) var isDisposed = false
  // Stores the timetoken the user subscribed with
  private(set) var timetoken: Timetoken?
  
  public var eventStream: ((PubNubEvent) -> Void)?
  public var eventsStream: (([PubNubEvent]) -> Void)?
  public var messagesStream: ((PubNubMessage) -> Void)?
  public var signalsStream: ((PubNubMessage) -> Void)?
  public var presenceStream: ((PubNubPresenceChange) -> Void)?
  public var messageActionsStream: ((PubNubMessageActionEvent) -> Void)?
  public var filesStream: ((PubNubFileEvent) -> Void)?
  public var appContextStream: ((PubNubAppContextEvent) -> Void)?
  
  // Intercepts messages from the Subscribe loop and forwards them to the current `Subscription`
  lazy var adapter = BaseSubscriptionListenerAdapter(
    receiver: self,
    uuid: uuid,
    queue: queue
  )
  
  internal var receiver: SubscribeReceiver? {
    entity.receiver
  }
  
  internal var subscriptionType: SubscribableType {
    entity.subscriptionType
  }
  
  internal var subscriptionNames: [String] {
    let hasPresenceOption = options.hasPresenceOption()
    let name = entity.name
    
    switch entity {
    case is ChannelRepresentation:
      return hasPresenceOption ? [name, name.presenceChannelName] : [name]
    case is ChannelGroupRepresentation:
      return hasPresenceOption ? [name, name.presenceChannelName] : [name]
    default:
      return [entity.name]
    }
  }
  
  /// Creates a clone of the current instance of `Subscription`.
  ///
  /// Use this method to create a new instance with the same configuration as the current `Subscription`.
  /// The clone is a separate instance that can be used independently.
  public func clone() -> Subscription {
    Subscription(
      queue: queue,
      entity: entity,
      options: options
    )
  }
  
  /// Disposes the current `Subscription`, ending the subscription.
  ///
  /// Use this method to gracefully end the subscription and release associated resources.
  /// Once disposed, the subscription interface cannot be restarted.
  public func dispose() {
    clearCallbacks()
    unsubscribe()
    isDisposed = true
  }
  
  deinit {
    dispose()
  }
}

extension Subscription: SubscribeCapable {
  /// Subscribes to the associated `entity` with the specified timetoken.
  ///
  /// - Parameter timetoken: The timetoken to use for subscribing. If `nil`, the `0` value is used.
  public func subscribe(with timetoken: Timetoken?) {
    guard let receiver = receiver, !isDisposed else {
      return
    }
    let channels = subscriptionType == .channel ? [self] : []
    let channelGroups = subscriptionType == .channelGroup ? [self] : []

    receiver.registerAdapter(adapter)
    receiver.internalSubscribe(with: channels, and: channelGroups, at: timetoken)
  }

  /// Unsubscribes from the associated entity, ending the PubNub subscription.
  ///
  /// Use this method to gracefully end the subscription and stop receiving messages for the associated entity.
  /// If there are no remaining subscriptions that match the associated entity, the unsubscribe action will be performed,
  /// and the entity will be deregistered from the Subscribe loop. After unsubscribing, the subscription interface
  /// can be restarted if needed.
  public func unsubscribe() {
    guard let receiver = receiver, !isDisposed else {
      return
    }
    let channels = subscriptionType == .channel ? [self] : []
    let groups = subscriptionType == .channelGroup ? [self] : []

    receiver.internalUnsubscribe(from: channels, and: groups, presenceOnly: false)
  }
}

extension Subscription: Hashable {
  public static func ==(lhs: Subscription, rhs: Subscription) -> Bool {
    lhs.uuid == rhs.uuid
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }
}

// MARK: - SubscribeMessagePayloadReceiver

extension Subscription: SubscribeMessagesReceiver {
  var subscriptionTopology: [SubscribableType : [String]] {
    [subscriptionType: subscriptionNames]
  }
  
  @discardableResult func onPayloadsReceived(payloads: [SubscribeMessagePayload]) -> [PubNubEvent] {
    let events = payloads.compactMap { event(from: $0) }
    emit(events: events)
    return events
  }
  
  func event(from payload: SubscribeMessagePayload) -> PubNubEvent? {
    let isNewerOrEqualToTimetoken = payload.publishTimetoken.timetoken >= timetoken ?? 0
    let receivedFromCurrentEntity: Bool
    
    if subscriptionType == .channel {
      receivedFromCurrentEntity = entity.name.matches(string: payload.channel)
    } else if subscriptionType == .channelGroup {
      receivedFromCurrentEntity = entity.name.matches(string: payload.subscription ?? payload.channel)
    } else {
      receivedFromCurrentEntity = true
    }
    
    if receivedFromCurrentEntity && isNewerOrEqualToTimetoken {
      let event = payload.asPubNubEvent()
      return options.filterCriteriaSatisfied(event: event) ? event : nil
    } else {
      return nil
    }
  }
}

// MARK: - Helper String extension

fileprivate extension String {
  func matches(string: String) -> Bool {
    guard hasSuffix(".*") else {
      return self == string
    }
    let pattern = "^" + self + "$"
    let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)

    return predicate.evaluate(with: string)
  }
}
