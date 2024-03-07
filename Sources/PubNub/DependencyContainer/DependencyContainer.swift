//
//  DependencyContainer.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// A protocol that represents a unique key for each dependency. Each type conforming to DependencyKey
// represents a distinct dependency.
protocol DependencyKey {
  // A value associated with a given `DependencyKey`
  associatedtype Value
  // Creates a value of the type Value for a given `DependencyKey` if no existing dependency
  // is found in the `DependencyContainer`. The `container` parameter is used in case of
  // nested dependencies, i.e., when the dependency being created depends on other objects in the `DependencyContainer`.
  static func value(from container: DependencyContainer) -> Value
}

// The class that serves as a registry for dependencies. Each dependency is associated with a unique key
// conforming to the `DependencyKey` protocol.
class DependencyContainer {
  private var values: [ObjectIdentifier: Any] = [:]
  
  init(instanceID: UUID = UUID(), configuration: PubNubConfiguration) {
    self[PubNubConfigurationDependencyKey.self] = configuration
    self[PubNubInstanceIDDependencyKey.self] = instanceID
  }
  
  subscript<K>(key: K.Type) -> K.Value where K: DependencyKey {
    get {
      if let existingValue = values[ObjectIdentifier(key)] {
        return existingValue as! K.Value
      }
      let value = key.value(from: self)
      values[ObjectIdentifier(key)] = value
      return value
    } set {
      values[ObjectIdentifier(key)] = newValue
    }
  }
  
  @discardableResult
  func register<K: DependencyKey>(value: K.Value?, forKey key: K.Type) -> DependencyContainer {
    if let value {
      values[ObjectIdentifier(key)] = value
    }
    return self
  }
}

extension DependencyContainer {
  var configuration: PubNubConfiguration {
    self[PubNubConfigurationDependencyKey.self]
  }
  
  var instanceID: UUID {
    self[PubNubInstanceIDDependencyKey.self]
  }
  
  var fileURLSession: URLSessionReplaceable {
    self[FileURLSessionDependencyKey.self]
  }
  
  var subscriptionSession: SubscriptionSession {
    self[SubscriptionSessionDependencyKey.self]
  }
  
  var httpSession: SessionReplaceable {
    resolveSession(
      session: self[HTTPSessionDependencyKey.self],
      with: [instanceIDOperator].compactMap { $0 }
    )
  }
  
  var presenceStateContainer: PubNubPresenceStateContainer {
    self[PresenceStateContainerDependencyKey.self]
  }
  
  fileprivate var automaticRetry: RequestOperator? {
    configuration.automaticRetry
  }
  
  fileprivate var instanceIDOperator: RequestOperator? {
    configuration.useInstanceId ? InstanceIdOperator(instanceID: instanceID.uuidString) : nil
  }
  
  fileprivate var httpSubscribeSession: SessionReplaceable {
    resolveSession(
      session: self[HTTPSubscribeSessionDependencyKey.self],
      with: [instanceIDOperator].compactMap { $0 }
    )
  }
  
  fileprivate var httpPresenceSession: SessionReplaceable {
    resolveSession(
      session: self[HTTPPresenceSessionDependencyKey.self],
      with: [instanceIDOperator].compactMap { $0 }
    )
  }
  
  fileprivate var httpSubscribeSessionQueue: DispatchQueue {
    self[HTTPSubscribeSessionQueueDependencyKey.self]
  }
  
  fileprivate var subscribeEventEngine: SubscribeEngine {
    self[SubscribeEventEngineDependencyKey.self]
  }
  
  fileprivate var subscribeEffectFactory: SubscribeEffectFactory {
    self[SubscribeEffectFactoryDependencyKey.self]
  }
  
  fileprivate var presenceEffectFactory: PresenceEffectFactory {
    self[PresenceEffectFactoryDependencyKey.self]
  }
  
  fileprivate var presenceEngine: PresenceEngine {
    self[PresenceEventEngineDependencyKey.self]
  }
}

fileprivate extension DependencyContainer {
  func resolveSession(session: SessionReplaceable, with operators: [RequestOperator?]) -> SessionReplaceable {
    session.defaultRequestOperator == nil ? session.usingDefault(requestOperator: MultiplexRequestOperator(
      operators: operators.compactMap { $0 }
    )) : session.usingDefault(requestOperator: session.defaultRequestOperator?.merge(
      operators: operators.compactMap { $0 })
    )
  }
}

// - MARK: PubNubConfiguration

struct PubNubConfigurationDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> PubNubConfiguration {
    container.configuration
  }
}

struct PubNubInstanceIDDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> UUID {
    container.instanceID
  }
}

// MARK: - HTTPSession

struct HTTPSessionDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> SessionReplaceable {
    HTTPSession(configuration: .pubnub)
  }
}

struct HTTPSubscribeSessionDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> SessionReplaceable {
    HTTPSession(
      configuration: .subscription,
      sessionQueue: container.httpSubscribeSessionQueue,
      sessionStream: SessionListener(queue: container.httpSubscribeSessionQueue)
    )
  }
}

struct HTTPSubscribeSessionQueueDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> DispatchQueue {
    DispatchQueue(label: "Subscribe Response Queue")
  }
}

struct HTTPPresenceSessionDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> HTTPSession {
    HTTPSession(
      configuration: .pubnub,
      sessionQueue: container.httpSubscribeSessionQueue,
      sessionStream: SessionListener(queue: container.httpSubscribeSessionQueue)
    )
  }
}

// MARK: - FileURLSession

struct FileURLSessionDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> URLSessionReplaceable {
    URLSession(
      configuration: .pubnubBackground,
      delegate: FileSessionManager(),
      delegateQueue: .main
    )
  }
}

// MARK: - PresenceStateContainer

struct PresenceStateContainerDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> PubNubPresenceStateContainer {
    PubNubPresenceStateContainer.shared
  }
}

// MARK: SubscribeEventEngine

struct SubscribeEventEngineDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> SubscribeEngine {
    SubscribeEngine(
      state: Subscribe.UnsubscribedState(),
      transition: SubscribeTransition(),
      dispatcher: EffectDispatcher(factory: container.subscribeEffectFactory),
      dependencies: EventEngineDependencies(value: Subscribe.Dependencies(configuration: container.configuration))
    )
  }
}

struct SubscribeEffectFactoryDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> SubscribeEffectFactory {
    SubscribeEffectFactory(
      session: container.httpSubscribeSession,
      presenceStateContainer: container.presenceStateContainer
    )
  }
}

// MARK: PresenceEventEngine

struct PresenceEffectFactoryDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> PresenceEffectFactory {
    PresenceEffectFactory(
      session: container.httpPresenceSession,
      presenceStateContainer: container.presenceStateContainer
    )
  }
}

struct PresenceEventEngineDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> PresenceEngine {
    PresenceEngine(
      state: Presence.HeartbeatInactive(),
      transition: PresenceTransition(configuration: container.configuration),
      dispatcher: EffectDispatcher(factory: container.presenceEffectFactory),
      dependencies: EventEngineDependencies(value: Presence.Dependencies(configuration: container.configuration))
    )
  }
}

// MARK: - SubscriptionSession

struct SubscriptionSessionDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> SubscriptionSession {
    if container.configuration.enableEventEngine {
      return SubscriptionSession(
        strategy: EventEngineSubscriptionSessionStrategy(
          configuration: container.configuration,
          subscribeEngine: container.subscribeEventEngine,
          presenceEngine: container.presenceEngine,
          presenceStateContainer: container.presenceStateContainer
        )
      )
    } else {
      return SubscriptionSession(
        strategy: LegacySubscriptionSessionStrategy(
          configuration: container.configuration,
          network: container.httpSubscribeSession,
          presenceSession: container.httpPresenceSession
        )
      )
    }
  }
}
