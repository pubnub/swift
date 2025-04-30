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

/// A property wrapper that provides thread-safe access to a value.
@propertyWrapper
public class AtomicValue<Value> {
  private let atomic: Atomic<Value>

  public var wrappedValue: Value {
    get { atomic.lockedRead { $0 } }
    set { atomic.lockedWrite { $0 = newValue } }
  }

  public init(wrappedValue: Value) {
    self.atomic = Atomic(wrappedValue)
  }
}

/// A final class representing a PubNub subscription.
public final class Subscription {
  public let queue: DispatchQueue
  public let uuid: UUID = UUID()
  public let entity: SubscribeTarget
  public let options: SubscriptionOptions

  @AtomicValue public private(set) var isDisposed: Bool = false
  @AtomicValue var listenersCache: SubscriptionListenersContainer = .init()

  public var onEvent: ((PubNubEvent) -> Void)?
  public var onEvents: (([PubNubEvent]) -> Void)?
  public var onMessage: ((PubNubMessage) -> Void)?
  public var onSignal: ((PubNubMessage) -> Void)?
  public var onPresence: ((PubNubPresenceChange) -> Void)?
  public var onMessageAction: ((PubNubMessageActionEvent) -> Void)?
  public var onFileEvent: ((PubNubFileChangeEvent) -> Void)?
  public var onAppContext: ((PubNubAppContextEvent) -> Void)?

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

  // Intercepts messages from the Subscribe loop and forwards them to the current `Subscription`
  lazy var adapter = BaseSubscriptionListenerAdapter(
    receiver: self,
    uuid: uuid,
    queue: queue
  )

  deinit {
    dispose()
  }
}

// MARK: - SubscriptionInterface

extension Subscription: SubscriptionInterface {
  /// Creates a clone of the current instance of `Subscription`.
  ///
  /// Use this method to create a new instance with the same configuration as the current `Subscription`.
  /// The clone is a separate instance that can be used independently.
  public func clone() -> Subscription {
    let copy = Subscription(
      queue: queue,
      entity: entity,
      options: options
    )

    if let pubnub = entity.pubnub, pubnub.hasRegisteredAdapter(with: uuid) {
      pubnub.registerAdapter(copy.adapter)
    }

    return copy
  }

  /// Disposes the current `Subscription`, ending the subscription.
  ///
  /// Use this method to gracefully end the subscription and release associated resources.
  /// Once disposed, the subscription interface cannot be restarted.
  public func dispose() {
    clearCallbacks()
    removeAllListeners()
    unsubscribe()
    isDisposed = true
  }
}

// MARK: - InternalSubscriptionInterface

extension Subscription: InternalSubscriptionInterface {
  // The PubNub instance associated with the current `Subscription`
  var pubnub: PubNub? {
    get {
      entity.pubnub
    }
  }

  // The topology of the subscription, returning underlying channel and/or channel groups.
  var subscriptionTopology: [SubscribeTargetType: [String]] {
    let hasPresenceOption = options.hasPresenceOption()
    let name = entity.name

    let subscriptionNames = switch entity {
    case is ChannelRepresentation:
      hasPresenceOption ? [name, name.presenceChannelName] : [name]
    case is ChannelGroupRepresentation:
      hasPresenceOption ? [name, name.presenceChannelName] : [name]
    default:
      [entity.name]
    }

    return [entity.targetType: subscriptionNames]
  }

  func shouldProcessSubscription(_ subscription: InternalSubscriptionInterface) -> Bool {
    subscription.uuid == uuid
  }
}
