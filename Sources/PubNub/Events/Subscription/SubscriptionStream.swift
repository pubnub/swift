//
//  SubscriptionStream.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// A channel or group that has successfully been subscribed or unsubscribed
public enum SubscriptionChangeEvent {
  /// The channels or groups that have successfully been subscribed
  case subscribed(channels: [PubNubChannel], groups: [PubNubChannel])
  /// The response header for one or more subscription events
  case responseHeader(
    channels: [PubNubChannel], groups: [PubNubChannel], previous: SubscribeCursor?, next: SubscribeCursor?
  )
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

/// The header of a PubNub subscribe response for zero or more events
public struct SubscribeResponseHeader {
  /// The channels that are actively subscribed
  public let channels: [PubNubChannel]
  /// The groups that are actively subscribed
  public let groups: [PubNubChannel]
  /// The most recent successful Timetoken used in subscriptionstatus
  public let previous: SubscribeCursor?
  /// Timetoken that will be used on the next subscription cycle
  public let next: SubscribeCursor?

  public init(
    channels: [PubNubChannel],
    groups: [PubNubChannel],
    previous: SubscribeCursor?,
    next: SubscribeCursor?
  ) {
    self.channels = channels
    self.groups = groups
    self.previous = previous
    self.next = next
  }
}

/// Local events emitted from the Subscribe method
public enum PubNubSubscribeEvent {
  /// A change in the Channel or Group state occured
  case subscriptionChanged(SubscriptionChangeEvent)
  /// A subscribe response was received
  case responseReceived(SubscribeResponseHeader)
  /// The connection status of the PubNub subscription was changed
  case connectionChanged(ConnectionStatus)
  /// An error was received
  case errorReceived(PubNubError)
}

/// All the possible events related to PubNub subscription
public typealias SubscriptionEvent = PubNubCoreEvent

/// The Core PubNub Events found within the PubNub module
public enum PubNubCoreEvent {
  /// A message has been received
  case messageReceived(PubNubMessage)
  /// A signal has been received
  case signalReceived(PubNubMessage)

  /// A change in the subscription connection has occurred
  case connectionStatusChanged(ConnectionStatus)

  /// A change in the subscribed channels or groups has occurred
  case subscriptionChanged(SubscriptionChangeEvent)

  /// A presence change has been received
  case presenceChanged(PubNubPresenceChange)

  /// A User object has been updated
  case uuidMetadataSet(PubNubUUIDMetadataChangeset)
  /// A User object has been deleted
  case uuidMetadataRemoved(metadataId: String)
  /// A Space object has been updated
  case channelMetadataSet(PubNubChannelMetadataChangeset)
  /// A Space object has been deleted
  case channelMetadataRemoved(metadataId: String)
  /// A Membership object has been updated
  case membershipMetadataSet(PubNubMembershipMetadata)
  /// A Membership object has been deleted
  case membershipMetadataRemoved(PubNubMembershipMetadata)

  /// A MessageAction was added to a published message
  case messageActionAdded(PubNubMessageAction)
  /// A MessageAction was removed from a published message
  case messageActionRemoved(PubNubMessageAction)

  /// A File was uploaded to storage
  case fileUploaded(PubNubFileEvent)

  /// A subscription error has occurred
  case subscribeError(PubNubError)

  /// True if this event is an error related to cancellation otherwise false
  var isCancellationError: Bool {
    switch self {
    case let .subscribeError(error):
      return error.isCancellationError
    default:
      return false
    }
  }
}

/// Listener capable of emitting batched and single SubscriptionEvent objects
public typealias SubscriptionListener = CoreListener

/// Listener capable of emitting batched and single PubNubCoreEvent objects
public final class CoreListener: BaseSubscriptionListener {
  /// The type of action the Message Action event represents
  public enum MessageActionEvent: CaseAccessible {
    /// The Message Action was added to a message
    case added(PubNubMessageAction)
    /// The Message Action was removed from a message
    case removed(PubNubMessageAction)
  }

  /// All the changes that can be received for Metadata objects
  public enum ObjectMetadataChangeEvents {
    /// The changeset for the UUID object that changed
    case setUUID(PubNubUUIDMetadataChangeset)
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
  public var didReceiveBatchSubscription: (([SubscriptionEvent]) -> Void)?
  /// Receiver for all subscription events
  public var didReceiveSubscription: ((SubscriptionEvent) -> Void)?

  /// Receiver for changes in the subscribe/unsubscribe status of channels/groups
  public var didReceiveSubscriptionChange: ((SubscriptionChangeEvent) -> Void)?
  /// Receiver for status (Connection & Error) events
  public var didReceiveStatus: ((StatusEvent) -> Void)?
  /// Receiver for presence events
  public var didReceivePresence: ((PubNubPresenceChange) -> Void)?
  /// Receiver for message events
  public var didReceiveMessage: ((PubNubMessage) -> Void)?
  /// Receiver for signal events
  public var didReceiveSignal: ((PubNubMessage) -> Void)?

  /// Receiver for Object Metadata Events
  public var didReceiveObjectMetadataEvent: ((ObjectMetadataChangeEvents) -> Void)?

  /// Receiver for message action events
  public var didReceiveMessageAction: ((MessageActionEvent) -> Void)?

  /// Receiver for File Upload events
  public var didReceiveFileUpload: ((PubNubFileEvent) -> Void)?

  // MARK: Parent Override

  override public func emit(subscribe event: PubNubSubscribeEvent) {
    switch event {
    case let .subscriptionChanged(changeEvent):
      emitDidReceive(subscription: [.subscriptionChanged(changeEvent)])
    case let .responseReceived(header):
      emitDidReceive(subscription: [.subscriptionChanged(
        .responseHeader(
          channels: header.channels,
          groups: header.groups,
          previous: header.previous,
          next: header.next
        )
      )])
    case let .connectionChanged(status):
      emitDidReceive(subscription: [.connectionStatusChanged(status)])
    case let .errorReceived(error):
      emitDidReceive(subscription: [.subscribeError(error)])
    }
  }

  override public func emit(batch: [SubscribeMessagePayload]) {
    emitDidReceive(subscription: batch.map { message in
      switch message.messageType {
      case .message:
        return .messageReceived(PubNubMessageBase(from: message))
      case .signal:
        return .signalReceived(PubNubMessageBase(from: message))
      case .object:
        guard let objectAction = try? message.payload.decode(SubscribeObjectMetadataPayload.self) else {
          return .messageReceived(PubNubMessageBase(from: message))
        }
        return objectAction.subscribeEvent
      case .messageAction:
        guard let messageAction = PubNubMessageActionBase(from: message),
              let actionEventString = message.payload[rawValue: "event"] as? String,
              let actionEvent = SubscribeMessageActionPayload.Action(rawValue: actionEventString)
        else {
          return .messageReceived(PubNubMessageBase(from: message))
        }

        switch actionEvent {
        case .added:
          return .messageActionAdded(messageAction)
        case .removed:
          return .messageActionRemoved(messageAction)
        }
      case .file:
        // Attempt to decode as a File Message, then fallback to General if fails
        guard let fileMessage = try? PubNubFileEventBase(from: message) else {
          return .messageReceived(PubNubMessageBase(from: message))
        }
        return .fileUploaded(fileMessage)
      case .presence:
        guard let presence = PubNubPresenceChangeBase(from: message) else {
          return .messageReceived(PubNubMessageBase(from: message))
        }

        return .presenceChanged(presence)
      }
    })
  }

  public func emitDidReceive(subscription batch: [SubscriptionEvent]) {
    let supressCancellationErrors = self.supressCancellationErrors
    queue.async { [weak self] in
      // We also want to filter out cancellation errors
      self?.didReceiveBatchSubscription?(batch.filter { !($0.isCancellationError && supressCancellationErrors) })

      for event in batch {
        self?.emitDidReceive(subscription: event)
      }
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  public func emitDidReceive(subscription event: SubscriptionEvent) {
    if event.isCancellationError, supressCancellationErrors {
      return
    }

    queue.async { [weak self] in
      // Emit Master Event
      self?.didReceiveSubscription?(event)

      // Emit Granular Event
      switch event {
      case let .messageReceived(message):
        self?.didReceiveMessage?(message)
      case let .signalReceived(signal):
        self?.didReceiveSignal?(signal)

      case let .connectionStatusChanged(status):
        self?.didReceiveStatus?(.success(status))
      case let .subscriptionChanged(change):
        self?.didReceiveSubscriptionChange?(change)
      case let .presenceChanged(presence):
        self?.didReceivePresence?(presence)

      case let .uuidMetadataSet(metadata):
        self?.didReceiveObjectMetadataEvent?(.setUUID(metadata))
      case let .uuidMetadataRemoved(metadataId):
        self?.didReceiveObjectMetadataEvent?(.removedUUID(metadataId: metadataId))
      case let .channelMetadataSet(metadata):
        self?.didReceiveObjectMetadataEvent?(.setChannel(metadata))
      case let .channelMetadataRemoved(channelMetadataId):
        self?.didReceiveObjectMetadataEvent?(.removedChannel(metadataId: channelMetadataId))
      case let .membershipMetadataSet(membership):
        self?.didReceiveObjectMetadataEvent?(.setMembership(membership))
      case let .membershipMetadataRemoved(membership):
        self?.didReceiveObjectMetadataEvent?(.removedMembership(membership))

      case let .messageActionAdded(action):
        self?.didReceiveMessageAction?(.added(action))
      case let .messageActionRemoved(action):
        self?.didReceiveMessageAction?(.removed(action))
      case let .fileUploaded(file):
        self?.didReceiveFileUpload?(file)
      case let .subscribeError(error):
        self?.didReceiveStatus?(.failure(error))
      }
    }
  }
}

/// Listener that will emit events related to PubNub subscription and presence APIs
open class BaseSubscriptionListener: EventStreamReceiver, Hashable {
  // EventStream
  public let uuid = UUID()
  public var queue: DispatchQueue

  /// Whether you would like to avoid receiving cancellation errors from this listener
  public var supressCancellationErrors: Bool = true
  var token: ListenerToken?

  public init(queue: DispatchQueue = .main) {
    self.queue = queue
  }

  deinit {
    cancel()
  }

  open func emit(batch _: [SubscribeMessagePayload]) {}

  open func emit(subscribe _: PubNubSubscribeEvent) {}

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
