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

public protocol SubscriptionStream: EventStream {
  func emitDidReceive(message event: MessageEvent)
  func emitDidReceive(status event: StatusEvent)
  func emitDidReceive(presence event: PresenceEvent)
  func emitDidReceive(signal event: MessageEvent)
}

extension SubscriptionStream {
  func emitDidReceive(message _: MessageEvent) { /* no-op */ }
  func emitDidReceive(status _: StatusEvent) { /* no-op */ }
  func emitDidReceive(presence _: PresenceEvent) { /* no-op */ }
  func emitDidReceive(signal _: MessageEvent) { /* no-op */ }
}

public final class SubscriptionListener: SubscriptionStream, Hashable {
  public var uuid: UUID
  public var queue: DispatchQueue

  public init(queue: DispatchQueue = .main) {
    uuid = UUID()
    self.queue = queue
  }

  public var didReceiveMessage: ((MessageEvent) -> Void)?
  public var didReceiveStatus: ((StatusEvent) -> Void)?
  public var didReceivePresence: ((PresenceEvent) -> Void)?
  public var didReceiveSignal: ((MessageEvent) -> Void)?

  public func emitDidReceive(message event: MessageEvent) {
    queue.async { self.didReceiveMessage?(event) }
  }

  public func emitDidReceive(status event: StatusEvent) {
    queue.async { self.didReceiveStatus?(event) }
  }

  public func emitDidReceive(presence event: PresenceEvent) {
    queue.async { self.didReceivePresence?(event) }
  }

  public func emitDidReceive(signal event: MessageEvent) {
    queue.async { self.didReceiveSignal?(event) }
  }

  public static func == (lhs: SubscriptionListener, rhs: SubscriptionListener) -> Bool {
    return lhs.uuid == rhs.uuid
  }
}
