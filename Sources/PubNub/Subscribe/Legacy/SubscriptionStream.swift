//
//  SubscriptionStream.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// A channel or group that has successfully been subscribed or unsubscribed
@available(*, deprecated, message: "This enumeration will be removed in future versions")
public enum SubscriptionChangeEvent {
  /// The channels or groups that have successfully been subscribed
  case subscribed(channels: [PubNubChannel], groups: [PubNubChannel])
  /// The response header for one or more subscription events
  case responseHeader(channels: [PubNubChannel], groups: [PubNubChannel], previous: SubscribeCursor?, next: SubscribeCursor?)
  /// The channels or groups that have successfully been unsubscribed
  case unsubscribed(channels: [PubNubChannel], groups: [PubNubChannel])

  /// Whether this event represents an actual change or contains no data
  var didChange: Bool {
    switch self {
    case let .subscribed(channels, groups):
      return !channels.isEmpty || !groups.isEmpty
    case .responseHeader:
      return false
    case let .unsubscribed(channels, groups):
      return !channels.isEmpty || !groups.isEmpty
    }
  }
}

/// Local events emitted from the Subscribe method
public enum PubNubSubscribeEvent {
  /// The connection status of the PubNub subscription was changed
  case connectionChanged(ConnectionStatus)
  /// An error was received
  case errorReceived(PubNubError)
}

/// Listener capable of emitting batched and single PubNubEvent objects
public typealias SubscriptionListener = CoreListener

/// Listener capable of emitting batched and single PubNubEvent objects
public final class CoreListener: BaseSubscriptionListener {
  /// All the changes that can be received for Metadata objects
  @available(*, deprecated, message: "Use PubNubAppContextEvent via didReceiveAppContextEvent")
  public enum ObjectMetadataChangeEvents {
    /// The changeset for the UUID object that changed
    case setUUID(PubNubUserMetadataChangeset)
    /// The unique identifer of the UUID that was removed
    case removedUUID(metadataId: String)
    /// The changeset for the Channel object that changed
    case setChannel(PubNubChannelMetadataChangeset)
    /// The unique identifer of the Channel that was removed
    case removedChannel(metadataId: String)
    /// The `PubNubMembershipMetadata` of the set Membership
    case setMembership(PubNubMembershipMetadata)
    /// The `PubNubMembershipMetadata` of the removed Membership
    case removedMembership(PubNubMembershipMetadata)
  }

  /// Event that either contains a change to the subscription connection or a subscription error
  public typealias StatusEvent = Result<ConnectionStatus, PubNubError>

  /// Batched subscription event that possibly contains multiple message events
  ///
  /// This will also emit individual events to `didReceiveSubscription`
  @available(*, deprecated, message: "Use the granular callbacks (didReceiveMessage, didReceiveSignal, etc.) instead")
  public var didReceiveBatchSubscription: (([PubNubEvent]) -> Void)?
  /// Receiver for all subscription events
  @available(*, deprecated, message: "Use the granular callbacks (didReceiveMessage, didReceiveSignal, etc.) instead")
  public var didReceiveSubscription: ((PubNubEvent) -> Void)?
  /// Receiver for status (Connection & Error) events
  public var didReceiveStatus: ((StatusEvent) -> Void)?
  /// Receiver for presence events
  public var didReceivePresence: ((PubNubPresenceChange) -> Void)?
  /// Receiver for message events
  public var didReceiveMessage: ((PubNubMessage) -> Void)?
  /// Receiver for signal events
  public var didReceiveSignal: ((PubNubMessage) -> Void)?
  /// Receiver for App Context events
  public var didReceiveAppContextEvent: ((PubNubAppContextEvent) -> Void)?
  /// Receiver for Object Metadata Events
  @available(*, deprecated, message: "Use didReceiveAppContextEvent with PubNubAppContextEvent")
  public var didReceiveObjectMetadataEvent: ((ObjectMetadataChangeEvents) -> Void)?
  /// Receiver for message action events
  public var didReceiveMessageAction: ((PubNubMessageActionEvent) -> Void)?
  /// Receiver for File Upload events
  public var didReceiveFileUpload: ((PubNubFileEvent) -> Void)?
  /// Receiver for DataSync events
  public var didReceiveDataSyncEvent: ((PubNubDataSyncEvent) -> Void)?

  // MARK: Parent Override

  override public func emit(subscribe event: PubNubSubscribeEvent) {
    queue.async { [weak self] in
      guard let self = self else { return }
      switch event {
      case let .connectionChanged(status):
        self.didReceiveStatus?(.success(status))
      case let .errorReceived(error):
        if error.isCancellationError, self.supressCancellationErrors { return }
        self.didReceiveStatus?(.failure(error))
      }
    }
  }

  override public func emit(batch: [SubscribeMessagePayload]) {
    emitDidReceive(subscription: batch.map { $0.asPubNubEvent() })
  }

  public func emitDidReceive(subscription batch: [PubNubEvent]) {
    queue.async { [weak self] in
      self?.didReceiveBatchSubscription?(batch)

      for event in batch {
        self?.emitDidReceive(subscription: event)
      }
    }
  }

  public func emitDidReceive(subscription event: PubNubEvent) {
    queue.async { [weak self] in
      guard let self = self else { return }
      // Emit Master Event
      self.didReceiveSubscription?(event)

      // Emit Granular Event
      switch event {
      case let .messageReceived(message):
        self.didReceiveMessage?(message)
      case let .signalReceived(signal):
        self.didReceiveSignal?(signal)
      case let .presenceChanged(presence):
        self.didReceivePresence?(presence)
      case let .appContextChanged(appContext):
        self.didReceiveAppContextEvent?(appContext)
        self.emitDeprecatedObjectMetadataEvent(from: appContext)
      case let .messageActionChanged(action):
        self.didReceiveMessageAction?(action)
      case let .fileChanged(fileEvent):
        if case let .uploaded(file) = fileEvent {
          self.didReceiveFileUpload?(file)
        }
      case let .dataSyncChanged(dataSyncEvent):
        self.didReceiveDataSyncEvent?(dataSyncEvent)
      }
    }
  }

  // Bridges the unified `PubNubAppContextEvent` back to the deprecated `didReceiveObjectMetadataEvent` closure so existing listeners keep working.
  @available(*, deprecated)
  private func emitDeprecatedObjectMetadataEvent(from appContext: PubNubAppContextEvent) {
    guard let didReceiveObjectMetadataEvent = didReceiveObjectMetadataEvent else {
      return
    }
    switch appContext {
    case let .userMetadataSet(changeset):
      didReceiveObjectMetadataEvent(.setUUID(changeset))
    case let .userMetadataRemoved(metadataId):
      didReceiveObjectMetadataEvent(.removedUUID(metadataId: metadataId))
    case let .channelMetadataSet(changeset):
      didReceiveObjectMetadataEvent(.setChannel(changeset))
    case let .channelMetadataRemoved(metadataId):
      didReceiveObjectMetadataEvent(.removedChannel(metadataId: metadataId))
    case let .membershipMetadataSet(membership):
      didReceiveObjectMetadataEvent(.setMembership(membership))
    case let .membershipMetadataRemoved(membership):
      didReceiveObjectMetadataEvent(.removedMembership(membership))
    }
  }
}

/// Listener that will emit events related to PubNub subscription and presence APIs
open class BaseSubscriptionListener: EventStreamReceiver, Hashable {
  // EventStream
  public let uuid: UUID
  public let queue: DispatchQueue

  /// Whether you would like to avoid receiving cancellation errors from this listener
  public let supressCancellationErrors: Bool
  // Keeps a mechanism to cancel a listener
  var token: ListenerToken?

  public init(queue: DispatchQueue = .main, supressCancellationErrors: Bool = true) {
    self.queue = queue
    self.supressCancellationErrors = supressCancellationErrors
    self.uuid = UUID()
  }

  init(queue: DispatchQueue = .main, uuid: UUID = UUID(), supressCancellationErrors: Bool = true) {
    self.queue = queue
    self.uuid = uuid
    self.supressCancellationErrors = supressCancellationErrors
  }

  deinit {
    cancel()
  }

  open func emit(batch _: [SubscribeMessagePayload]) {}
  open func emit(subscribe _: PubNubSubscribeEvent) {}

  public func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }

  public static func == (lhs: BaseSubscriptionListener, rhs: BaseSubscriptionListener) -> Bool {
    return lhs.uuid == rhs.uuid
  }
}

extension BaseSubscriptionListener: Cancellable {
  public var isCancelled: Bool {
    return token?.isCancelled ?? true
  }

  public func cancel() {
    token?.cancel()
  }
}

open class PubNubEntityListener: BaseSubscriptionListener {
  override public final func emit(batch: [SubscribeMessagePayload]) {
    queue.async { [weak self] in
      self?.emit(entity: batch.compactMap { event in
        if event.messageType == .object {
          return try? event.payload.decode(PubNubEntityEvent.self)
        } else {
          return nil
        }
      })
    }
  }

  open func emit(entity _: [PubNubEntityEvent]) {
    preconditionFailure("`emit(entity:)` not implemented by subclass")
  }
}
