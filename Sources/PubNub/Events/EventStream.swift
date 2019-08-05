//
//  EventStream.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

public protocol EventStream {
  var uuid: UUID { get }
  var queue: DispatchQueue { get }
}

public extension EventStream {
  var queue: DispatchQueue {
    return .main
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(uuid)
  }
}

public protocol EventStreamListener: AnyObject {
  associatedtype ListenerType

  var listeners: [ListenerType] { get }

  func add(_ listener: ListenerType) -> ListenerToken
  func remove(_ listener: ListenerType)

  func notify(listeners closure: (ListenerType) -> Void)
}

public class ListenerToken: CustomStringConvertible {
  private let cancelledState = AtomicInt(0)
  private var cancellationClosure: (() -> Void)?

  public var isCancelled: Bool {
    return cancelledState.isEqual(to: 1)
  }

  public let tokenId = UUID()

  public init(cancellationClosure: @escaping () -> Void) {
    self.cancellationClosure = cancellationClosure
  }

  deinit {
    cancel()
  }

  public func cancel() {
    if cancelledState.bitwiseOrAssignemnt(1) == 0 {
      if let closure = cancellationClosure {
        cancellationClosure = nil
        closure()
      }
    }
  }
}

// MARK: - CustomStringConvertible

extension ListenerToken {
  public var description: String {
    return "ListenerToken: \(tokenId)"
  }
}
