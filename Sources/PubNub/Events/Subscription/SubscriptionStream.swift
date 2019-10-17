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

public enum SubscriptionChangeEvent {
  case subscribed(channels: [PubNubChannel], groups: [PubNubChannel])
  case unsubscribed(channels: [PubNubChannel], groups: [PubNubChannel])

  var didChange: Bool {
    switch self {
    case let .subscribed(channels, groups):
      return !channels.isEmpty || !groups.isEmpty
    case let .unsubscribed(channels, groups):
      return !channels.isEmpty || !groups.isEmpty
    }
  }
}

public enum SubscriptionEvent {
  case messageReceived(MessageEvent)
  case signalReceived(MessageEvent)
  case connectionStatusChanged(ConnectionStatus)
  case subscriptionChanged(SubscriptionChangeEvent)
  case presenceChanged(PresenceEvent)
  case userUpdated(UserEvent)
  case userDeleted(IdentifierEvent)
  case spaceUpdated(SpaceEvent)
  case spaceDeleted(IdentifierEvent)
  case membershipAdded(MembershipEvent)
  case membershipUpdated(MembershipEvent)
  case membershipDeleted(MembershipIdentifiable)
  case subscribeError(PubNubError)

  var isCancellationError: Bool {
    switch self {
    case let .subscribeError(error):
      return error.isCancellationError
    default:
      return false
    }
  }
}

public protocol SubscriptionStream: EventStream {
  func emitDidReceive(subscription event: SubscriptionEvent)
}

extension SubscriptionStream {
  func emitDidReceive(subscription _: SubscriptionEvent) { /* no-op */ }
}

public final class SubscriptionListener: SubscriptionStream, Hashable, Cancellable {
  public let uuid: UUID
  public var queue: DispatchQueue

  var token: ListenerToken?
  public var supressCancellationErrors: Bool = true

  public init(queue: DispatchQueue = .main) {
    uuid = UUID()
    self.queue = queue
  }

  deinit {
    cancel()
  }

  public var didReceiveSubscription: ((SubscriptionEvent) -> Void)?

  public var didReceiveMessage: ((MessageEvent) -> Void)?
  public var didReceiveStatus: ((StatusEvent) -> Void)?
  public var didReceivePresence: ((PresenceEvent) -> Void)?
  public var didReceiveSignal: ((MessageEvent) -> Void)?
  public var didReceiveSubscriptionChange: ((SubscriptionChangeEvent) -> Void)?

  public var didReceiveUserEvent: ((UserEvents) -> Void)?
  public var didReceiveSpaceEvent: ((SpaceEvents) -> Void)?
  public var didReceiveMembershipEvent: ((MembershipEvents) -> Void)?

  // swiftlint:disable:next cyclomatic_complexity
  public func emitDidReceive(subscription event: SubscriptionEvent) {
    if event.isCancellationError, supressCancellationErrors {
      return
    }

    queue.async {
      // Emit Master Event
      self.didReceiveSubscription?(event)

      // Emit Granular Event
      switch event {
      case let .messageReceived(message):
        self.didReceiveMessage?(message)
      case let .signalReceived(signal):
        self.didReceiveSignal?(signal)
      case let .connectionStatusChanged(status):
        self.didReceiveStatus?(.success(status))
      case let .subscriptionChanged(change):
        self.didReceiveSubscriptionChange?(change)
      case let .presenceChanged(presence):
        self.didReceivePresence?(presence)
      case let .userUpdated(user):
        self.didReceiveUserEvent?(.updated(user))
      case let .userDeleted(user):
        self.didReceiveUserEvent?(.deleted(user))
      case let .spaceUpdated(space):
        self.didReceiveSpaceEvent?(.updated(space))
      case let .spaceDeleted(space):
        self.didReceiveSpaceEvent?(.deleted(space))
      case let .membershipAdded(membership):
        self.didReceiveMembershipEvent?(.userAddedOnSpace(membership))
      case let .membershipUpdated(membership):
        self.didReceiveMembershipEvent?(.userUpdatedOnSpace(membership))
      case let .membershipDeleted(membership):
        self.didReceiveMembershipEvent?(.userDeletedFromSpace(membership))
      case let .subscribeError(error):
        self.didReceiveStatus?(.failure(error))
      }
    }
  }

  public static func == (lhs: SubscriptionListener, rhs: SubscriptionListener) -> Bool {
    return lhs.uuid == rhs.uuid
  }

  public var isCancelled: Bool {
    return token?.isCancelled ?? true
  }

  public func cancel() {
    token?.cancel()
  }
}
