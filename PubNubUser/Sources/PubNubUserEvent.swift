//
//  PubNubUserEvent.swift
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
