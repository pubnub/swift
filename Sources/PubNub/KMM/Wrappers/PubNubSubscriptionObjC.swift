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
  @objc public var onPresence: (([PubNubPresenceEventResultObjC]) -> Void)?
  @objc public var onSignal: ((PubNubMessageObjC) -> Void)?
  @objc public var onMessageAction: ((PubNubMessageActionObjC) -> Void)?
  @objc public var onAppContext: ((PubNubObjectEventResultObjC) -> Void)?
  @objc public var onFile: ((PubNubFileEventResultObjC) -> Void)?
  
  @objc
  public init(entity: PubNubEntityRepresentableObjC) {
    self.subscription = Subscription(entity: entity.entity)
  }
  
  @objc
  func dispose() {
    subscription.dispose()
  }
  
  @objc
  func addListener(_ listener: EventListenerObjC) {
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
      listener.onPresence?(PubNubPresenceEventResultObjC.from(change: $0))
    }
    eventListener.onMessageAction = {
      listener.onMessageAction?(PubNubMessageActionObjC(action: $0))
    }
    eventListener.onFileEvent = { [weak self] in
      listener.onFile?(PubNubFileEventResultObjC.from(event: $0, with: self?.subscription.entity.pubnub))
    }
    eventListener.onAppContext = {
      listener.onAppContext?(PubNubObjectEventResultObjC.from(event: $0))
    }

    subscription.addEventListener(eventListener)
  }
  
  @objc
  func removeListener(_ listener: EventListenerObjC) {
    subscription.removeEventListener(with: listener.uuid)
  }
  
  @objc
  func removeAllListeners() {
    subscription.removeAllListeners()
  }
  
  @objc 
  func subscribe(with timetoken: Timetoken) {
    subscription.subscribe(with: timetoken)
  }
  
  @objc
  func unsubscribe() {
    subscription.unsubscribe()
  }
  
  @objc
  func append(subscription: PubNubSubscriptionObjC) -> PubNubSubscriptionSetObjC {
    let underlyingSubscription = Subscription(entity: subscription.subscription.entity)
        
    underlyingSubscription.onMessage = {
      subscription.onMessage?(PubNubMessageObjC(message: $0))
    }
    underlyingSubscription.onSignal = {
      subscription.onSignal?(PubNubMessageObjC(message: $0))
    }
    underlyingSubscription.onPresence = {
      subscription.onPresence?(PubNubPresenceEventResultObjC.from(change: $0))
    }
    underlyingSubscription.onMessageAction = {
      subscription.onMessageAction?(PubNubMessageActionObjC(action: $0))
    }
    underlyingSubscription.onFileEvent = { [weak underlyingSubscription] in
      subscription.onFile?(PubNubFileEventResultObjC.from(event: $0, with: underlyingSubscription?.pubnub))
    }
    underlyingSubscription.onAppContext = {
      subscription.onAppContext?(PubNubObjectEventResultObjC.from(event: $0))
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
  @objc public var onPresence: (([PubNubPresenceEventResultObjC]) -> Void)?
  @objc public var onSignal: ((PubNubMessageObjC) -> Void)?
  @objc public var onMessageAction: ((PubNubMessageActionObjC) -> Void)?
  @objc public var onAppContext: ((PubNubObjectEventResultObjC) -> Void)?
  @objc public var onFile: ((PubNubFileEventResultObjC) -> Void)?
  
  init(subscriptionSet: SubscriptionSet) {
    self.subscriptionSet = subscriptionSet
  }
  
  @objc
  func dispose() {
    subscriptionSet.dispose()
  }
  
  @objc
  func addListener(_ listener: EventListenerObjC) {
    let pubnub = subscriptionSet.currentSubscriptions.first?.entity.pubnub
    let eventListener = EventListener(uuid: listener.uuid)
    
    eventListener.onMessage = {
      listener.onMessage?(PubNubMessageObjC(message: $0))
    }
    eventListener.onSignal = {
      listener.onSignal?(PubNubMessageObjC(message: $0))
    }
    eventListener.onPresence = {
      listener.onPresence?(PubNubPresenceEventResultObjC.from(change: $0))
    }
    eventListener.onMessageAction = {
      listener.onMessageAction?(PubNubMessageActionObjC(action: $0))
    }
    eventListener.onFileEvent = {
      listener.onFile?(PubNubFileEventResultObjC.from(event: $0, with: pubnub))
    }
    eventListener.onAppContext = {
      listener.onAppContext?(PubNubObjectEventResultObjC.from(event: $0))
    }
    
    subscriptionSet.addEventListener(eventListener)
  }
  
  @objc
  func removeListener(_ listener: EventListenerObjC) {
    subscriptionSet.removeEventListener(with: listener.uuid)
  }
  
  @objc
  func removeAllListeners() {
    subscriptionSet.removeAllListeners()
  }
  
  @objc
  func subscribe(with timetoken: Timetoken) {
    subscriptionSet.subscribe(with: timetoken)
  }
  
  @objc
  func unsubscribe() {
    subscriptionSet.unsubscribe()
  }
  
  @objc
  func append(subscription: PubNubSubscriptionObjC) {
    let underlyingSubscription = Subscription(entity: subscription.subscription.entity)

    underlyingSubscription.onMessage = {
      subscription.onMessage?(PubNubMessageObjC(message: $0))
    }
    underlyingSubscription.onSignal = {
      subscription.onSignal?(PubNubMessageObjC(message: $0))
    }
    underlyingSubscription.onPresence = {
      subscription.onPresence?(PubNubPresenceEventResultObjC.from(change: $0))
    }
    underlyingSubscription.onMessageAction = {
      subscription.onMessageAction?(PubNubMessageActionObjC(action: $0))
    }
    underlyingSubscription.onFileEvent = { [weak underlyingSubscription] in
      subscription.onFile?(PubNubFileEventResultObjC.from(event: $0, with: underlyingSubscription?.pubnub))
    }
    underlyingSubscription.onAppContext = {
      subscription.onAppContext?(PubNubObjectEventResultObjC.from(event: $0))
    }
    
    subscriptionSet.add(subscription: underlyingSubscription)
  }
  
  @objc
  func remove(subscription: PubNubSubscriptionObjC) {
    subscriptionSet.remove(subscription: subscription.subscription)
  }
}
