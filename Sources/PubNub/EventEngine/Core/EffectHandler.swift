//
//  EffectHandler.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
import Foundation

// MARK: - EffectHandlerFactory

protocol EffectHandlerFactory<Invocation, Event, Dependencies> {
  associatedtype Invocation
  associatedtype Event
  associatedtype Dependencies
  
  func effect(
    for invocation: Invocation,
    with dependencies: EventEngineDependencies<Dependencies>
  ) -> any EffectHandler<Event>
}

// MARK: - EffectHandler

protocol EffectHandler<Event> {
  associatedtype Event
    
  func performTask(completionBlock: @escaping ([Event]) -> Void)
  func cancelTask()
}

extension EffectHandler {
  func cancelTask() {}
}

// MARK: - Delayed Effect Handler

protocol DelayedEffectHandler: AnyObject, EffectHandler {
  var workItem: DispatchWorkItem? { get set }
  
  func delayInterval() -> TimeInterval?
  func onEarlyExit(notify completionBlock: @escaping ([Event]) -> Void)
  func onDelayExpired(notify completionBlock: @escaping ([Event]) -> Void)
}

extension DelayedEffectHandler {
  func performTask(completionBlock: @escaping ([Event]) -> Void) {
    guard let delay = delayInterval() else {
      onEarlyExit(notify: completionBlock); return
    }
    let workItem = DispatchWorkItem() { [weak self] in
      self?.onDelayExpired(notify: completionBlock)
    }
    DispatchQueue.global(qos: .default).asyncAfter(
      deadline: .now() + delay,
      execute: workItem
    )
    self.workItem = workItem
  }
  
  func cancelTask() {
    workItem?.cancel()
  }
}
