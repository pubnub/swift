//
//  PubNubSubscriptionObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
//
// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
// While these symbols are public, they are intended strictly for internal usage.
//
// External developers should refrain from directly using these symbols in their code, as their implementation details
// may change in future versions of the framework, potentially leading to breaking changes.

import Foundation

@objc
public class KMPSubscription: NSObject {
  let subscription: Subscription

  @objc public var onMessage: ((KMPMessage) -> Void)?
  @objc public var onPresence: (([KMPPresenceChange]) -> Void)?
  @objc public var onSignal: ((KMPMessage) -> Void)?
  @objc public var onMessageAction: ((KMPMessageAction) -> Void)?
  @objc public var onAppContext: ((KMPAppContextEventResult) -> Void)?
  @objc public var onFile: ((KMPFileChangeEvent) -> Void)?

  @objc
  public init(entity: KMPEntity, receivePresenceEvents: Bool) {
    self.subscription = Subscription(
      entity: entity.entity,
      options: receivePresenceEvents ? ReceivePresenceEvents() : .empty()
    )
  }

  @objc
  public init(entity: KMPEntity) {
    self.subscription = Subscription(entity: entity.entity)
  }

  @objc
  public func dispose() {
    subscription.dispose()
  }

  @objc
  public func addListener(_ listener: KMPEventListener) {
    let eventListener = EventListener(
      uuid: listener.uuid
    )
    eventListener.onMessage = {
      listener.onMessage?(KMPMessage(message: $0))
    }
    eventListener.onSignal = {
      listener.onSignal?(KMPMessage(message: $0))
    }
    eventListener.onPresence = {
      listener.onPresence?(KMPPresenceChange.from(change: $0))
    }
    eventListener.onMessageAction = {
      listener.onMessageAction?(KMPMessageAction(action: $0))
    }
    eventListener.onFileEvent = { [weak self] in
      listener.onFile?(KMPFileChangeEvent.from(event: $0, with: self?.subscription.entity.pubnub))
    }
    eventListener.onAppContext = {
      listener.onAppContext?(KMPAppContextEventResult.from(event: $0))
    }

    subscription.addEventListener(eventListener)
  }

  @objc
  public func removeListener(_ listener: KMPEventListener) {
    subscription.removeEventListener(with: listener.uuid)
  }

  @objc
  public func removeAllListeners() {
    subscription.removeAllListeners()
  }

  @objc
  public func subscribe(with timetoken: Timetoken) {
    subscription.subscribe(with: timetoken)
  }

  @objc
  public func unsubscribe() {
    subscription.unsubscribe()
  }

  @objc
  public func append(subscription: KMPSubscription) -> KMPSubscriptionSet {
    let underlyingSubscription = Subscription(
      entity: subscription.subscription.entity
    )

    underlyingSubscription.onMessage = {
      subscription.onMessage?(KMPMessage(message: $0))
    }
    underlyingSubscription.onSignal = {
      subscription.onSignal?(KMPMessage(message: $0))
    }
    underlyingSubscription.onPresence = {
      subscription.onPresence?(KMPPresenceChange.from(change: $0))
    }
    underlyingSubscription.onMessageAction = {
      subscription.onMessageAction?(KMPMessageAction(action: $0))
    }
    underlyingSubscription.onFileEvent = { [weak underlyingSubscription] in
      subscription.onFile?(KMPFileChangeEvent.from(event: $0, with: underlyingSubscription?.pubnub))
    }
    underlyingSubscription.onAppContext = {
      subscription.onAppContext?(KMPAppContextEventResult.from(event: $0))
    }

    return KMPSubscriptionSet(
      subscriptionSet: SubscriptionSet(subscriptions: [
        self.subscription,
        underlyingSubscription
      ])
    )
  }
}

@objc
public class KMPSubscriptionSet: NSObject {
  private let subscriptionSet: SubscriptionSet

  @objc public var onMessage: ((KMPMessage) -> Void)?
  @objc public var onPresence: (([KMPPresenceChange]) -> Void)?
  @objc public var onSignal: ((KMPMessage) -> Void)?
  @objc public var onMessageAction: ((KMPMessageAction) -> Void)?
  @objc public var onAppContext: ((KMPAppContextEventResult) -> Void)?
  @objc public var onFile: ((KMPFileChangeEvent) -> Void)?

  init(subscriptionSet: SubscriptionSet) {
    self.subscriptionSet = subscriptionSet
  }

  @objc
  public init(subscriptions: [KMPSubscription]) {
    self.subscriptionSet = SubscriptionSet(subscriptions: subscriptions.map { $0.subscription })
  }

  @objc
  public func dispose() {
    subscriptionSet.dispose()
  }

  @objc
  public func addListener(_ listener: KMPEventListener) {
    let pubnub = subscriptionSet.currentSubscriptions.first?.entity.pubnub
    let eventListener = EventListener(uuid: listener.uuid)

    eventListener.onMessage = {
      listener.onMessage?(KMPMessage(message: $0))
    }
    eventListener.onSignal = {
      listener.onSignal?(KMPMessage(message: $0))
    }
    eventListener.onPresence = {
      listener.onPresence?(KMPPresenceChange.from(change: $0))
    }
    eventListener.onMessageAction = {
      listener.onMessageAction?(KMPMessageAction(action: $0))
    }
    eventListener.onFileEvent = {
      listener.onFile?(KMPFileChangeEvent.from(event: $0, with: pubnub))
    }
    eventListener.onAppContext = {
      listener.onAppContext?(KMPAppContextEventResult.from(event: $0))
    }

    subscriptionSet.addEventListener(eventListener)
  }

  @objc
  public func removeListener(_ listener: KMPEventListener) {
    subscriptionSet.removeEventListener(with: listener.uuid)
  }

  @objc
  public func removeAllListeners() {
    subscriptionSet.removeAllListeners()
  }

  @objc
  public func subscribe(with timetoken: Timetoken) {
    subscriptionSet.subscribe(with: timetoken)
  }

  @objc
  public func unsubscribe() {
    subscriptionSet.unsubscribe()
  }

  @objc
  public func append(subscription: KMPSubscription) {
    let underlyingSubscription = Subscription(entity: subscription.subscription.entity)

    underlyingSubscription.onMessage = {
      subscription.onMessage?(KMPMessage(message: $0))
    }
    underlyingSubscription.onSignal = {
      subscription.onSignal?(KMPMessage(message: $0))
    }
    underlyingSubscription.onPresence = {
      subscription.onPresence?(KMPPresenceChange.from(change: $0))
    }
    underlyingSubscription.onMessageAction = {
      subscription.onMessageAction?(KMPMessageAction(action: $0))
    }
    underlyingSubscription.onFileEvent = { [weak underlyingSubscription] in
      subscription.onFile?(KMPFileChangeEvent.from(event: $0, with: underlyingSubscription?.pubnub))
    }
    underlyingSubscription.onAppContext = {
      subscription.onAppContext?(KMPAppContextEventResult.from(event: $0))
    }

    subscriptionSet.add(subscription: underlyingSubscription)
  }

  @objc
  public func remove(subscription: KMPSubscription) {
    subscriptionSet.remove(subscription: subscription.subscription)
  }
}
