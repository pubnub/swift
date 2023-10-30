//
//  PubNubMembershipEvent.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

import PubNub

/// All the changes that can be received for Membership entities
public enum PubNubMembershipEvent {
  /// The Membership entity that was updated
  case membershipUpdated(PubNubMembership.Patcher)
  /// The Membership entity that was removed
  case membershipRemoved(PubNubMembership)
}

/// Listener capable of emitting batched and single PubNubMembershipEvent objects
public final class PubNubMembershipListener: PubNubEntityListener {
  /// Batched subscription event that possibly contains multiple Membership events
  ///
  /// This will also emit individual events to `didReceiveMembershipEvent`
  public var didReceiveMembershipEvents: (([PubNubMembershipEvent]) -> Void)?

  /// Receiver for all Membership events
  public var didReceiveMembershipEvent: ((PubNubMembershipEvent) -> Void)?

  override public func emit(entity events: [PubNubEntityEvent]) {
    var membershipEvents = [PubNubMembershipEvent]()

    for event in events where event.type == .membership {
      switch event.action {
      case .updated:
        if let patcher = try? event.data.decode(PubNubMembership.Patcher.self) {
          membershipEvents.append(.membershipUpdated(patcher))
        }
      case .removed:
        if let membership = try? event.data.decode(PubNubMembership.self) {
          membershipEvents.append(.membershipRemoved(membership))
        }
      }
    }

    didReceiveMembershipEvents?(membershipEvents)

    for event in membershipEvents {
      didReceiveMembershipEvent?(event)
    }
  }
}
