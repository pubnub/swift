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

// A protocol that represents a unique key for each dependency. Each type conforming to `DependencyKey`
// represents a distinct dependency.
protocol DependencyKey {
  // A value associated with a given `DependencyKey`
  associatedtype Value
  // Creates a value of the type Value for a given `DependencyKey` if no existing dependency
  // is found in the `DependencyContainer`. The `container` parameter is used in case of
  // nested dependencies, i.e., when the dependency being created depends on other objects in the `DependencyContainer`.
  static func value(from container: DependencyContainer) -> Value

  // Called when a value is resolved in the dependency container.
  //
  // This method is invoked when a specific `Value` type is resolved within the
  // dependency container. It can be used for custom logic or configuration
  // after the dependency has been resolved.
  static func onValueResolved(value: Value, in container: DependencyContainer)
}

extension DependencyKey {
  static func onValueResolved(value: Value, in container: DependencyContainer) {}
}

// The class that serves as a registry for dependencies. Each dependency is associated with a unique key
// conforming to the `DependencyKey` protocol.
class DependencyContainer {
  private var resolvedValues: [ObjectIdentifier: any Wrappable] = [:]
  private var registeredKeys: [ObjectIdentifier: (key: any DependencyKey.Type, scope: Scope)] = [:]

  // Defines the lifecycle of the given dependency
  enum Scope {
    // The dependency is owned by the container. It lives as long as the container itself lives.
    // The dependency is strongly referenced by the container.
    case container
    // The container does not own the dependency. The dependency could be deallocated even if the container
    // is still alive, if there are no more strong references to it.
    case weak
    // Indicates that the DependencyContainer doesn't keep any reference (neither strong nor weak) to the dependency.
    // Each time the dependency is requested, a new instance is created and returned
    case transient
  }

  init(instanceID: UUID = UUID(), configuration: PubNubConfiguration) {
    register(value: configuration, forKey: PubNubConfigurationDependencyKey.self)
    register(value: instanceID, forKey: PubNubInstanceIDDependencyKey.self)
    register(key: FileURLSessionDependencyKey.self, scope: .weak)
    register(key: DefaultHTTPSessionDependencyKey.self, scope: .weak)
    register(key: HTTPSubscribeSessionDependencyKey.self, scope: .weak)
    register(key: HTTPPresenceSessionDependencyKey.self, scope: .weak)
    register(key: HTTPSubscribeSessionQueueDependencyKey.self, scope: .weak)
    register(key: PresenceStateContainerDependencyKey.self, scope: .weak)
    register(key: SubscribeEventEngineDependencyKey.self, scope: .weak)
    register(key: PresenceEventEngineDependencyKey.self, scope: .weak)
    register(key: SubscriptionSessionDependencyKey.self, scope: .weak)
    register(key: PubNubLoggerDependencyKey.self, scope: .weak)
  }

  subscript<K>(key: K.Type) -> K.Value where K: DependencyKey {
    guard let underlyingKey = registeredKeys[ObjectIdentifier(key)] else {
      preconditionFailure("Cannot find \(key). Ensure this key was registered before")
    }
    if underlyingKey.scope == .transient {
      if let value = underlyingKey.key.value(from: self) as? K.Value {
        key.onValueResolved(value: value, in: self)
        return value
      } else {
        preconditionFailure("Cannot create value for key \(key)")
      }
    }
    if let valueWrapper = resolvedValues[ObjectIdentifier(key)] {
      if let underlyingValue = valueWrapper.value as? K.Value {
        return underlyingValue
      }
    }
    if let value = underlyingKey.key.value(from: self) as? K.Value {
      if Mirror(reflecting: value).displayStyle == .class && underlyingKey.scope == .weak {
        self.resolvedValues[ObjectIdentifier(key)] = WeakWrapper(value as AnyObject)
        key.onValueResolved(value: value, in: self)
      } else {
        self.resolvedValues[ObjectIdentifier(key)] = ValueWrapper(value)
        key.onValueResolved(value: value, in: self)
      }
      return value
    }
    preconditionFailure("Cannot create value for key \(key)")
  }

  func register<K: DependencyKey>(key: K.Type, scope: Scope = .container) {
    registeredKeys[ObjectIdentifier(key)] = (key: key, scope: scope)
  }

  @discardableResult
  func register<K: DependencyKey>(value: K.Value?, forKey key: K.Type, in scope: Scope = .container) -> DependencyContainer {
    guard let value = value else {
      return self
    }
    registeredKeys[ObjectIdentifier(key)] = (key: key, scope: scope)

    if Mirror(reflecting: value).displayStyle == .class && scope == .weak {
      resolvedValues[ObjectIdentifier(key)] = WeakWrapper(value as AnyObject)
    } else {
      resolvedValues[ObjectIdentifier(key)] = ValueWrapper(value)
    }

    return self
  }
}

typealias SubscribeEngine = EventEngine<any SubscribeState, Subscribe.Event, Subscribe.Invocation, Subscribe.Dependencies>
typealias PresenceEngine = EventEngine<any PresenceState, Presence.Event, Presence.Invocation, Presence.Dependencies>

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

  var presenceStateContainer: PubNubPresenceStateContainer {
    self[PresenceStateContainerDependencyKey.self]
  }

  var defaultHTTPSession: SessionReplaceable {
    self[DefaultHTTPSessionDependencyKey.self]
  }

  var httpSubscribeSession: SessionReplaceable {
    self[HTTPSubscribeSessionDependencyKey.self]
  }

  var httpPresenceSession: SessionReplaceable {
    self[HTTPPresenceSessionDependencyKey.self]
  }

  var logger: PubNubLogger {
    self[PubNubLoggerDependencyKey.self]
  }

  fileprivate var automaticRetry: RequestOperator? {
    configuration.automaticRetry
  }

  fileprivate var instanceIDOperator: RequestOperator? {
    configuration.useInstanceId ? InstanceIdOperator(instanceID: instanceID.uuidString) : nil
  }

  fileprivate var httpSubscribeSessionQueue: DispatchQueue {
    self[HTTPSubscribeSessionQueueDependencyKey.self]
  }

  fileprivate var subscribeEngine: SubscribeEngine {
    self[SubscribeEventEngineDependencyKey.self]
  }

  fileprivate var presenceEngine: PresenceEngine {
    self[PresenceEventEngineDependencyKey.self]
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

// MARK: - HTTPSessions

extension DependencyKey where Value == SessionReplaceable {
  @discardableResult
  static func updateSession(
    session: SessionReplaceable,
    with operators: [RequestOperator],
    and logger: PubNubLogger
  ) -> SessionReplaceable {
    session.defaultRequestOperator == nil ? session.usingDefault(requestOperator: MultiplexRequestOperator(
      operators: operators
    )) : session.usingDefault(requestOperator: session.defaultRequestOperator?.merge(
      operators: operators
    ))
    .usingDefault(logger: logger)
  }
}

struct DefaultHTTPSessionDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> SessionReplaceable {
    HTTPSession(configuration: .pubnub)
  }

  static func onValueResolved(value: SessionReplaceable, in container: DependencyContainer) {
    updateSession(session: value, with: [container.automaticRetry].compactMap { $0 }, and: container.logger)
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

  static func onValueResolved(value: SessionReplaceable, in container: DependencyContainer) {
    updateSession(session: value, with: [container.instanceIDOperator].compactMap { $0 }, and: container.logger)
  }
}

struct HTTPSubscribeSessionQueueDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> DispatchQueue {
    DispatchQueue(label: "Subscribe Response Queue")
  }
}

struct HTTPPresenceSessionDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> SessionReplaceable {
    HTTPSession(
      configuration: .pubnub,
      sessionQueue: container.httpSubscribeSessionQueue,
      sessionStream: SessionListener(queue: container.httpSubscribeSessionQueue)
    )
  }
  static func onValueResolved(value: SessionReplaceable, in container: DependencyContainer) {
    updateSession(session: value, with: [container.instanceIDOperator].compactMap { $0 }, and: container.logger)
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

struct FileURLSessionManagerDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> FileSessionManager {
    FileSessionManager()
  }

  static func onValueResolved(value: FileSessionManager, in container: DependencyContainer) {
    value.logger = container.logger
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
    let effectHandlerFactory = SubscribeEffectFactory(
      session: container.httpSubscribeSession,
      presenceStateContainer: container.presenceStateContainer
    )
    let subscribeEngine = SubscribeEngine(
      state: Subscribe.UnsubscribedState(),
      transition: SubscribeTransition(),
      dispatcher: EffectDispatcher(factory: effectHandlerFactory, logger: container.logger),
      dependencies: EventEngineDependencies(value: Subscribe.Dependencies(configuration: container.configuration)),
      logger: container.logger
    )
    return subscribeEngine
  }
}

// MARK: PresenceEventEngine

struct PresenceEventEngineDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> PresenceEngine {
    let effectHandlerFactory = PresenceEffectFactory(
      session: container.httpPresenceSession,
      presenceStateContainer: container.presenceStateContainer
    )
    let presenceEngine = PresenceEngine(
      state: Presence.HeartbeatInactive(),
      transition: PresenceTransition(configuration: container.configuration),
      dispatcher: EffectDispatcher(factory: effectHandlerFactory, logger: container.logger),
      dependencies: EventEngineDependencies(value: Presence.Dependencies(configuration: container.configuration)),
      logger: container.logger
    )
    return presenceEngine
  }
}

// MARK: - SubscriptionSession

struct SubscriptionSessionDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> SubscriptionSession {
    if container.configuration.enableEventEngine {
      return SubscriptionSession(
        strategy: EventEngineSubscriptionSessionStrategy(
          configuration: container.configuration,
          subscribeEngine: container.subscribeEngine,
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

// MARK: - Logger

struct PubNubLoggerDependencyKey: DependencyKey {
  static func value(from container: DependencyContainer) -> PubNubLogger {
    PubNubLogger.defaultLogger()
  }
}

// Provides a standard interface for objects that wrap or encapsulate other objects in a dependency container context.
protocol Wrappable<T> {
  associatedtype T

  var value: T? { get }
}

// A concrete implementation of the `Wrappable` protocol, designed to hold a weak reference to the object it wraps.
// It only accepts classes (reference types) as its generic parameter, because weak references
// can only be made to reference types.
private class WeakWrapper<T: AnyObject>: Wrappable {
  private weak var optionalValue: T?

  var value: T? {
    optionalValue
  }

  init(_ value: T) {
    self.optionalValue = value
  }
}

// Holds a strong reference to the object it wraps
private class ValueWrapper<T>: Wrappable {
  let value: T?

  init(_ value: T) {
    self.value = value
  }
}
