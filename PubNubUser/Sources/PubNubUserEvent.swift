//
//  PubNubUserEvent.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

import PubNub

/// All the changes that can be received for User entities
public enum PubNubUserEvent {
  /// The changeset for the User entity that changed
  case userUpdated(PubNubUser.Patcher)
  /// The User entity that was remvoed
  case userRemoved(PubNubUser)
}

/// Listener capable of emitting batched and single PubNubUserEvent objects
public final class PubNubUserListener: PubNubEntityListener {
  /// Batched subscription event that possibly contains multiple User events
  ///
  /// This will also emit individual events to `didReceiveUserEvent`
  public var didReceiveUserEvents: (([PubNubUserEvent]) -> Void)?

  /// Receiver for all User events
  public var didReceiveUserEvent: ((PubNubUserEvent) -> Void)?

  override public func emit(entity events: [PubNubEntityEvent]) {
    var userEvents = [PubNubUserEvent]()

    for event in events where event.type == .user {
      switch event.action {
      case .updated:
        if let patcher = try? event.data.decode(PubNubUser.Patcher.self) {
          userEvents.append(.userUpdated(patcher))
        }
      case .removed:
        if let user = try? event.data.decode(PubNubUser.self) {
          userEvents.append(.userRemoved(user))
        }
      }
    }

    didReceiveUserEvents?(userEvents)

    for event in userEvents {
      didReceiveUserEvent?(event)
    }
  }
}
