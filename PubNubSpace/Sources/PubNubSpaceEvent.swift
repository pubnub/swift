//
//  PubNubSpaceEvent.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

import PubNub

public enum PubNubSpaceEvent {
  /// The changeset for the Space entity that changed
  case spaceUpdated(PubNubSpace.Patcher)
  /// The Space entity that was remvoed
  case spaceRemoved(PubNubSpace)
}

/// Listener capable of emitting batched and single PubNubSpaceEvent objects
public final class PubNubSpaceListener: PubNubEntityListener {
  /// Batched subscription event that possibly contains multiple Space events
  ///
  /// This will also emit individual events to `didReceiveSpaceEvent`
  public var didReceiveSpaceEvents: (([PubNubSpaceEvent]) -> Void)?

  /// Receiver for all Space events
  public var didReceiveSpaceEvent: ((PubNubSpaceEvent) -> Void)?

  override public func emit(entity events: [PubNubEntityEvent]) {
    var spaceEvents = [PubNubSpaceEvent]()

    for event in events where event.type == .space {
      switch event.action {
      case .updated:
        if let patcher = try? event.data.decode(PubNubSpace.Patcher.self) {
          spaceEvents.append(.spaceUpdated(patcher))
        }
      case .removed:
        if let space = try? event.data.decode(PubNubSpace.self) {
          spaceEvents.append(.spaceRemoved(space))
        }
      }
    }

    didReceiveSpaceEvents?(spaceEvents)

    for event in spaceEvents {
      didReceiveSpaceEvent?(event)
    }
  }
}
