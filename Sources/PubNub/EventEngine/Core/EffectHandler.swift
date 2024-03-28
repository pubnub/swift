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
  func onEmptyInterval(notify completionBlock: @escaping ([Event]) -> Void)
  func onDelayExpired(notify completionBlock: @escaping ([Event]) -> Void)
}

// MARK: - TimerEffect

class TimerEffect: EffectHandler {
  private let interval: TimeInterval
  private var workItem: DispatchWorkItem?

  init?(interval: TimeInterval?) {
    if let interval = interval {
      self.interval = interval
    } else {
      return nil
    }
  }

  func performTask(completionBlock: @escaping ([Void]) -> Void) {
    let workItem = DispatchWorkItem {
      completionBlock([])
    }
    DispatchQueue.global(qos: .default).asyncAfter(
      deadline: .now() + interval,
      execute: workItem
    )
    self.workItem = workItem
  }

  func cancelTask() {
    workItem?.cancel()
  }
}
