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
public final class Subscription: SubscriptionInternalInterface {
  /// The queue that events will be received on
  public let queue: DispatchQueue
  /// A unique identifier for `Subscription`
  public let uuid: UUID = UUID()
  /// An underlying entity that should be added to the Subscribe loop
  public let entity: SubscribeTarget
  /// Attached options
  public let options: SubscriptionOptions

  /// Initializes a `Subscription` object.
  ///
  /// - Parameters:
  ///   - queue: An underlying queue to dispatch events
  ///   - entity: An object that should be added to the Subscribe loop.
  ///   - options: Additional subscription options
  public init(
    queue: DispatchQueue = .main,
    entity: SubscribeTarget,
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) {
    self.queue = queue
    self.entity = entity
    self.options = SubscriptionOptions.empty() + options
  }

  public var isDisposed: Bool { isBeingDisposed.lockedRead { $0 } }
  public var onEvent: ((PubNubEvent) -> Void)?
  public var onEvents: (([PubNubEvent]) -> Void)?
  public var onMessage: ((PubNubMessage) -> Void)?
  public var onSignal: ((PubNubMessage) -> Void)?
  public var onPresence: ((PubNubPresenceChange) -> Void)?
  public var onMessageAction: ((PubNubMessageActionEvent) -> Void)?
  public var onFileEvent: ((PubNubFileChangeEvent) -> Void)?
  public var onAppContext: ((PubNubAppContextEvent) -> Void)?

  private let isBeingDisposed: Atomic<Bool> = Atomic(false)
  private let listenersContainer: SubscriptionListenersContainer = .init()
  
  // Intercepts messages from the Subscribe loop and forwards them to the current `Subscription`
  lazy var adapter = BaseSubscriptionListenerAdapter(
    receiver: self,
    uuid: uuid,
    queue: queue
  )

  weak var pubnub: PubNub? {
    entity.pubnub
  }

  var subscriptionType: SubscribeTargetType {
    entity.targetType
  }

  var subscriptionNames: [String] {
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
    let clonedSubscription = Subscription(
      queue: queue,
      entity: entity,
      options: options
    )
    if pubnub?.hasRegisteredAdapter(with: uuid) ?? false {
      pubnub?.registerAdapter(clonedSubscription.adapter)
    }
    return clonedSubscription
  }

  /// Disposes the current `Subscription`, ending the subscription.
  ///
  /// Use this method to gracefully end the subscription and release associated resources.
  /// Once disposed, the subscription interface cannot be restarted.
  public func dispose() {
    clearCallbacks()
    unsubscribe()
    removeAllListeners()
    isBeingDisposed.lockedWrite { $0 = true }
  }
  
  deinit {
    dispose()
  }
}

extension Subscription: EventListenerHandler {
  /// Adds additional subscription listener
  public func addEventListener(_ listener: EventListener) {
    listenersContainer.storeEventListener(listener)
  }

  /// Removes subscription listener
  public func removeEventListener(_ listener: EventListener) {
    listenersContainer.removeEventListener(listener)
  }

  /// Removes all event listeners
  public func removeAllListeners() {
    listenersContainer.removeAllEventListeners()
  }
}

extension Subscription {
  /// Subscribes to the associated `entity` with the specified timetoken.
  ///
  /// - Parameter timetoken: The timetoken to use for subscribing. If `nil`, the `0` value is used.
  public func subscribe(with timetoken: Timetoken?) {
    guard let pubnub = pubnub, !isDisposed else {
      return
    }
    let channels = subscriptionType == .channel ? [self] : []
    let channelGroups = subscriptionType == .channelGroup ? [self] : []

    pubnub.internalSubscribe(with: channels, and: channelGroups, at: timetoken)
  }

  /// Unsubscribes from the associated entity, ending the PubNub subscription.
  ///
  /// Use this method to gracefully end the subscription and stop receiving messages for the associated entity.
  /// If there are no remaining subscriptions that match the associated entity, the unsubscribe action will be performed,
  /// and the entity will be deregistered from the Subscribe loop. After unsubscribing, the subscription interface
  /// can be restarted if needed.
  public func unsubscribe() {
    guard let pubnub = pubnub, !isDisposed else {
      return
    }
    let channels = subscriptionType == .channel ? [self] : []
    let groups = subscriptionType == .channelGroup ? [self] : []

    pubnub.internalUnsubscribe(from: channels, and: groups, presenceOnly: false)
  }
}

extension Subscription: Hashable {
  public static func == (lhs: Subscription, rhs: Subscription) -> Bool {
    lhs.uuid == rhs.uuid
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }
}

// MARK: - SubscribeMessagesReceiver

extension Subscription: SubscribeMessagesReceiver {
  var subscriptionTopology: [SubscribeTargetType: [String]] {
    [subscriptionType: subscriptionNames]
  }

  @discardableResult func onPayloadsReceived(payloads: [SubscribeMessagePayload]) -> [PubNubEvent] {
    let events = payloads.compactMap { event(from: $0) }
    // Emit events to the current Subscription's closures
    emit(events: events)
    // Emits events to the underlying attached listeners
    listenersContainer.eventListeners.forEach { $0.emit(events: events) }
    // Returns events that were emitted
    return events
  }

  func event(from payload: SubscribeMessagePayload) -> PubNubEvent? {
    let isMatchingEntity: Bool

    if subscriptionType == .channel {
      isMatchingEntity = isMatchingEntityName(entity.name, string: payload.channel)
    } else if subscriptionType == .channelGroup {
      isMatchingEntity = isMatchingEntityName(entity.name, string: payload.subscription ?? payload.channel)
    } else {
      isMatchingEntity = true
    }

    if isMatchingEntity {
      let event = payload.asPubNubEvent()
      return options.filterCriteriaSatisfied(event: event) ? event : nil
    } else {
      return nil
    }
  }

  fileprivate func isMatchingEntityName(_ entityName: String, string: String) -> Bool {
    guard entityName.hasSuffix(".*") else {
      return entityName == string
    }
    if let firstIndex = entityName.lastIndex(of: "."), let secondIndex = string.lastIndex(of: ".") {
      return entityName.prefix(upTo: firstIndex) == string.prefix(upTo: secondIndex)
    }
    return false
  }
}
