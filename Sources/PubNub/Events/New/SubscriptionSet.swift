//
//  PubNubSubscriptionSet.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A final class representing a set of `Subscription`.
public final class SubscriptionSet {
  public let queue: DispatchQueue
  public let uuid: UUID = UUID()
  public let options: SubscriptionOptions

  @AtomicValue public private(set) var isDisposed: Bool = false
  @AtomicValue var listenersCache: SubscriptionListenersContainer = .init()
  @AtomicValue var currentSubscriptions: Set<AnySubscription> = []

  public var onEvent: ((PubNubEvent) -> Void)?
  public var onEvents: (([PubNubEvent]) -> Void)?
  public var onMessage: ((PubNubMessage) -> Void)?
  public var onSignal: ((PubNubMessage) -> Void)?
  public var onPresence: ((PubNubPresenceChange) -> Void)?
  public var onMessageAction: ((PubNubMessageActionEvent) -> Void)?
  public var onFileEvent: ((PubNubFileChangeEvent) -> Void)?
  public var onAppContext: ((PubNubAppContextEvent) -> Void)?

  // Internally intercepts messages from the Subscribe loop and forwards them to the current `SubscriptionSet`
  lazy var adapter: BaseSubscriptionListenerAdapter = BaseSubscriptionListenerAdapter(
    receiver: self,
    uuid: uuid,
    queue: queue
  )

  /// Initializes `SubscriptionSet` object with the specified parameters.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled
  ///   - entities: A collection of `SubscribeTarget` entities to include in the Subscribe loop
  ///   - options: Additional subscription options
  public init(
    queue: DispatchQueue = .main,
    entities: some Collection<SubscribeTarget> = [],
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) {
    self.queue = queue
    self.options = SubscriptionOptions.empty() + options
    self.currentSubscriptions = Set(entities.map { $0.subscription(queue: queue, options: options).eraseToAnySubscription() })
  }

  /// Initializes `SubscriptionSet` object with the specified parameters.
  ///
  /// - Parameters:
  ///   - queue: The dispatch queue on which the subscription events should be handled
  ///   - subscriptions: A collection of existing `SubscriptionInterface` instances to include in the Subscribe loop
  ///   - options: Additional subscription options
  public init(
    queue: DispatchQueue = .main,
    subscriptions: some Collection<SubscriptionInterface> = [],
    options: SubscriptionOptions = SubscriptionOptions.empty()
  ) {
    self.queue = queue
    self.options = options
    self.currentSubscriptions = Set(subscriptions.map { $0.eraseToAnySubscription() })
  }

  /// Adds a subscription to the existing set of subscriptions.
  ///
  /// - Parameter subscription: Subscription to add
  public func add(subscription: some SubscriptionInterface) {
    currentSubscriptions.insert(subscription.eraseToAnySubscription())
  }

  /// Adds a collection of subscription to the existing set of subscriptions.
  ///
  /// - Parameter subscriptions: List of subscription to add
  public func add(subscriptions: some Collection<SubscriptionInterface>) {
    currentSubscriptions.formUnion(subscriptions.map { $0.eraseToAnySubscription() })
  }

  /// Removes a subscription from the existing set of subscriptions.
  ///
  /// - Parameter subscription: Subscription to remove
  public func remove(subscription: some SubscriptionInterface) {
    currentSubscriptions.remove(subscription.eraseToAnySubscription())
  }

  /// Removes a collection of subscription from the existing set of subscriptions.
  ///
  /// - Parameter subscriptions: Collection of subscription to remove
  public func remove(subscriptions: some Collection<SubscriptionInterface>) {
    currentSubscriptions.subtract(subscriptions.map { $0.eraseToAnySubscription() })
  }

  deinit {
    dispose()
  }
}

// MARK: - SubscriptionInterface

extension SubscriptionSet: SubscriptionInterface {
  /// Creates a clone of the current instance of `SubscriptionSet`.
  ///
  /// Use this method to create a new instance with the same configuration as the current `SubscriptionSet`.
  /// The clone is a separate instance that can be used independently.
  public func clone() -> SubscriptionSet {
    let copy = SubscriptionSet(
      queue: queue,
      subscriptions: currentSubscriptions.map { $0.clone() },
      options: options
    )

    if let pubnub, pubnub.hasRegisteredAdapter(with: uuid) {
      pubnub.registerAdapter(copy.adapter)
    }

    return copy
  }

  /// Disposes of the current instance of `SubscriptionSet`, ending all associated subscriptions.
  ///
  /// Use this method to gracefully end the subscription and release associated resources.
  /// Once disposed, the subscription interface cannot be restarted.
  public func dispose() {
    clearCallbacks()
    removeAllListeners()
    currentSubscriptions.forEach { $0.dispose() }
    isDisposed = true
  }
}

// MARK: - InternalSubscriptionInterface

extension SubscriptionSet: InternalSubscriptionInterface {
  var pubnub: PubNub? {
    get {
      currentSubscriptions.first?.pubnub
    }
  }

  var subscriptionTopology: [SubscribeTargetType: [String]] {
    var result: [SubscribeTargetType: Set<String>] = [
      .channel: [],
      .channelGroup: []
    ]

    currentSubscriptions.forEach { subscription in
      let topology = subscription.subscriptionTopology
      result[.channel]?.formUnion(topology[.channel] ?? [])
      result[.channelGroup]?.formUnion(topology[.channelGroup] ?? [])
    }

    return result.mapValues { Array($0) }
  }

  func shouldProcessSubscription(_ subscription: InternalSubscriptionInterface) -> Bool {
    let belongsToCurrentSet = currentSubscriptions.contains { $0.uuid == subscription.uuid }

    switch belongsToCurrentSet {
    case true:
      return pubnub?.hasRegisteredAdapter(with: subscription.uuid) ?? false
    case false:
      return false
    }
  }
}
