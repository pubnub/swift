//
//  PubNubSpaceEvent.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
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
