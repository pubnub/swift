//
//  PubNubSubscriptionObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubSubscriptionObjC: NSObject {
  let subscription: Subscription

  @objc public var onMessage: ((PubNubMessageObjC) -> Void)?
  @objc public var onPresence: (([PubNubPresenceChangeObjC]) -> Void)?
  @objc public var onSignal: ((PubNubMessageObjC) -> Void)?
  @objc public var onMessageAction: ((PubNubMessageActionObjC) -> Void)?
  @objc public var onAppContext: ((PubNubAppContextEventObjC) -> Void)?
  @objc public var onFile: ((PubNubFileChangeEventObjC) -> Void)?

  @objc
  public init(entity: PubNubEntityRepresentableObjC) {
    self.subscription = Subscription(entity: entity.entity)
  }

  @objc
  public func dispose() {
    subscription.dispose()
  }

  @objc
  public func addListener(_ listener: PubNubEventListenerObjC) {
    let eventListener = EventListener(
      uuid: listener.uuid
    )
    eventListener.onMessage = {
      listener.onMessage?(PubNubMessageObjC(message: $0))
    }
    eventListener.onSignal = {
      listener.onSignal?(PubNubMessageObjC(message: $0))
    }
    eventListener.onPresence = {
      listener.onPresence?(PubNubPresenceChangeObjC.from(change: $0))
    }
    eventListener.onMessageAction = {
      listener.onMessageAction?(PubNubMessageActionObjC(action: $0))
    }
    eventListener.onFileEvent = { [weak self] in
      listener.onFile?(PubNubFileChangeEventObjC.from(event: $0, with: self?.subscription.entity.pubnub))
    }
    eventListener.onAppContext = {
      listener.onAppContext?(PubNubAppContextEventObjC.from(event: $0))
    }

    subscription.addEventListener(eventListener)
  }

  @objc
  public func removeListener(_ listener: PubNubEventListenerObjC) {
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
  public func append(subscription: PubNubSubscriptionObjC) -> PubNubSubscriptionSetObjC {
    let underlyingSubscription = Subscription(entity: subscription.subscription.entity)

    underlyingSubscription.onMessage = {
      subscription.onMessage?(PubNubMessageObjC(message: $0))
    }
    underlyingSubscription.onSignal = {
      subscription.onSignal?(PubNubMessageObjC(message: $0))
    }
    underlyingSubscription.onPresence = {
      subscription.onPresence?(PubNubPresenceChangeObjC.from(change: $0))
    }
    underlyingSubscription.onMessageAction = {
      subscription.onMessageAction?(PubNubMessageActionObjC(action: $0))
    }
    underlyingSubscription.onFileEvent = { [weak underlyingSubscription] in
      subscription.onFile?(PubNubFileChangeEventObjC.from(event: $0, with: underlyingSubscription?.pubnub))
    }
    underlyingSubscription.onAppContext = {
      subscription.onAppContext?(PubNubAppContextEventObjC.from(event: $0))
    }

    return PubNubSubscriptionSetObjC(
      subscriptionSet: SubscriptionSet(subscriptions: [
        self.subscription,
        underlyingSubscription
      ])
    )
  }
}

@objc
public class PubNubSubscriptionSetObjC: NSObject {
  private let subscriptionSet: SubscriptionSet

  @objc public var onMessage: ((PubNubMessageObjC) -> Void)?
  @objc public var onPresence: (([PubNubPresenceChangeObjC]) -> Void)?
  @objc public var onSignal: ((PubNubMessageObjC) -> Void)?
  @objc public var onMessageAction: ((PubNubMessageActionObjC) -> Void)?
  @objc public var onAppContext: ((PubNubAppContextEventObjC) -> Void)?
  @objc public var onFile: ((PubNubFileChangeEventObjC) -> Void)?

  init(subscriptionSet: SubscriptionSet) {
    self.subscriptionSet = subscriptionSet
  }

  @objc
  public init(subscriptions: [PubNubSubscriptionObjC]) {
    self.subscriptionSet = SubscriptionSet(subscriptions: subscriptions.map { $0.subscription })
  }

  @objc
  public func dispose() {
    subscriptionSet.dispose()
  }

  @objc
  public func addListener(_ listener: PubNubEventListenerObjC) {
    let pubnub = subscriptionSet.currentSubscriptions.first?.entity.pubnub
    let eventListener = EventListener(uuid: listener.uuid)

    eventListener.onMessage = {
      listener.onMessage?(PubNubMessageObjC(message: $0))
    }
    eventListener.onSignal = {
      listener.onSignal?(PubNubMessageObjC(message: $0))
    }
    eventListener.onPresence = {
      listener.onPresence?(PubNubPresenceChangeObjC.from(change: $0))
    }
    eventListener.onMessageAction = {
      listener.onMessageAction?(PubNubMessageActionObjC(action: $0))
    }
    eventListener.onFileEvent = {
      listener.onFile?(PubNubFileChangeEventObjC.from(event: $0, with: pubnub))
    }
    eventListener.onAppContext = {
      listener.onAppContext?(PubNubAppContextEventObjC.from(event: $0))
    }

    subscriptionSet.addEventListener(eventListener)
  }

  @objc
  public func removeListener(_ listener: PubNubEventListenerObjC) {
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
  public func append(subscription: PubNubSubscriptionObjC) {
    let underlyingSubscription = Subscription(entity: subscription.subscription.entity)

    underlyingSubscription.onMessage = {
      subscription.onMessage?(PubNubMessageObjC(message: $0))
    }
    underlyingSubscription.onSignal = {
      subscription.onSignal?(PubNubMessageObjC(message: $0))
    }
    underlyingSubscription.onPresence = {
      subscription.onPresence?(PubNubPresenceChangeObjC.from(change: $0))
    }
    underlyingSubscription.onMessageAction = {
      subscription.onMessageAction?(PubNubMessageActionObjC(action: $0))
    }
    underlyingSubscription.onFileEvent = { [weak underlyingSubscription] in
      subscription.onFile?(PubNubFileChangeEventObjC.from(event: $0, with: underlyingSubscription?.pubnub))
    }
    underlyingSubscription.onAppContext = {
      subscription.onAppContext?(PubNubAppContextEventObjC.from(event: $0))
    }

    subscriptionSet.add(subscription: underlyingSubscription)
  }

  @objc
  public func remove(subscription: PubNubSubscriptionObjC) {
    subscriptionSet.remove(subscription: subscription.subscription)
  }
}
