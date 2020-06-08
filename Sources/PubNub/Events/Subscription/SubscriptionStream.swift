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
  /// The channels or groups that have successfully been unsubscribed
  case unsubscribed(channels: [PubNubChannel], groups: [PubNubChannel])

  /// Whether this event represents an actual change or contains no data
  var didChange: Bool {
    switch self {
    case let .subscribed(channels, groups):
      return !channels.isEmpty || !groups.isEmpty
    case let .unsubscribed(channels, groups):
      return !channels.isEmpty || !groups.isEmpty
    }
  }
}

/// All the possible events related to PubNub subscription
public enum SubscriptionEvent {
  /// A message has been received
  case messageReceived(MessageEvent)
  /// A signal has been received
  case signalReceived(MessageEvent)
  /// A change in the subscription connection has occurred
  case connectionStatusChanged(ConnectionStatus)
  /// A change in the subscribed channels or groups has occurred
  case subscriptionChanged(SubscriptionChangeEvent)
  /// A presence change has been received
  case presenceChanged(PresenceEvent)
  /// A User object has been updated
  case userUpdated(UserEvent)
  /// A User object has been deleted
  case userDeleted(IdentifierEvent)
  /// A Space object has been updated
  case spaceUpdated(SpaceEvent)
  /// A Space object has been deleted
  case spaceDeleted(IdentifierEvent)
  /// A Membership object has been added
  case membershipAdded(MembershipEvent)
  /// A Membership object has been updated
  case membershipUpdated(MembershipEvent)
  /// A Membership object has been deleted
  case membershipDeleted(MembershipIdentifiable)
  /// A MessageAction was added to a published message
  case messageActionAdded(MessageActionEvent)
  /// A MessageAction was removed from a published message
  case messageActionRemoved(MessageActionEvent)
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

/// A way to emit a stream of PubNub subscription events
public protocol SubscriptionStream: EventStreamReceiver {
  /// The emitter used to broadcast `SubscriptionEvent` to its receivers
  /// - Parameter subscription: The event to be broadcast
  func emitDidReceive(subscription event: SubscriptionEvent)
}

extension SubscriptionStream {
  func emitDidReceive(subscription _: SubscriptionEvent) { /* no-op */ }
}

/// Listener that will emit events related to PubNub subscription and presence APIs
public final class SubscriptionListener: SubscriptionStream, Hashable {
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

  /// Receiver for all subscription events
  public var didReceiveSubscription: ((SubscriptionEvent) -> Void)?
  /// Receiver for message events
  public var didReceiveMessage: ((MessageEvent) -> Void)?
  /// Receiver for status (Connection & Error) events
  public var didReceiveStatus: ((StatusEvent) -> Void)?
  /// Receiver for presence events
  public var didReceivePresence: ((PresenceEvent) -> Void)?
  /// Receiver for signal events
  public var didReceiveSignal: ((MessageEvent) -> Void)?
  /// Receiver for changes in the subscribe/unsubscribe status of channels/groups
  public var didReceiveSubscriptionChange: ((SubscriptionChangeEvent) -> Void)?
  /// Receiver for User update and delete events
  public var didReceiveUserEvent: ((UserEvents) -> Void)?
  /// Receiver for Space update and delete events
  public var didReceiveSpaceEvent: ((SpaceEvents) -> Void)?
  /// Receiver for Membership join, update, and leave events
  public var didReceiveMembershipEvent: ((MembershipEvents) -> Void)?
  /// Receiver for message action events
  public var didReceiveMessageAction: ((MessageActionEvents) -> Void)?

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
      case let .userUpdated(user):
        self?.didReceiveUserEvent?(.updated(user))
      case let .userDeleted(user):
        self?.didReceiveUserEvent?(.deleted(user))
      case let .spaceUpdated(space):
        self?.didReceiveSpaceEvent?(.updated(space))
      case let .spaceDeleted(space):
        self?.didReceiveSpaceEvent?(.deleted(space))
      case let .membershipAdded(membership):
        self?.didReceiveMembershipEvent?(.userAddedOnSpace(membership))
      case let .membershipUpdated(membership):
        self?.didReceiveMembershipEvent?(.userUpdatedOnSpace(membership))
      case let .membershipDeleted(membership):
        self?.didReceiveMembershipEvent?(.userDeletedFromSpace(membership))
      case let .messageActionAdded(action):
        self?.didReceiveMessageAction?(.added(action))
      case let .messageActionRemoved(action):
        self?.didReceiveMessageAction?(.removed(action))
      case let .subscribeError(error):
        self?.didReceiveStatus?(.failure(error))
      }
    }
  }

  public static func == (lhs: SubscriptionListener, rhs: SubscriptionListener) -> Bool {
    return lhs.uuid == rhs.uuid
  }
}

extension SubscriptionListener: Cancellable {
  public var isCancelled: Bool {
    return token?.isCancelled ?? true
  }

  public func cancel() {
    token?.cancel()
  }
}
