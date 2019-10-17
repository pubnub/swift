//
//  SubscribeSessionFactory.swift
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

public class SubscribeSessionFactory {
  private typealias SessionMap = [Int: WeakBox<SubscriptionSession>]

  public static var shared = SubscribeSessionFactory()
  private let sessions = Atomic<SessionMap>([:])
  private init() {}

  public func getSession(from config: SubscriptionConfiguration,
                         with session: SessionReplaceable? = nil) -> SubscriptionSession {
    let configHash = config.subscriptionHashValue
    if let session = sessions.lockedRead({ $0[configHash]?.unbox }) {
      PubNub.log.debug("Found existing session for config hash \(config.subscriptionHashValue)")
      return session
    }

    PubNub.log.debug("Creating new session for with hash value \(config.subscriptionHashValue)")
    return sessions.lockedWrite { dictionary in
      let sessionReplaceable = session ?? Session(configuration: URLSessionConfiguration.subscription)
      let subscriptionSession = SubscriptionSession(configuration: config,
                                                    network: sessionReplaceable)
      dictionary.updateValue(WeakBox(subscriptionSession), forKey: configHash)
      return subscriptionSession
    }
  }

  /// Clean-up method that can be used to poke each weakbox to see if its nil
  func sessionDestroyed() {
    sessions.lockedWrite { sessionMap in
      sessionMap.keys.forEach { if sessionMap[$0]?.unbox == nil { sessionMap.removeValue(forKey: $0) } }
    }
  }
}

// MARK: - SubscriptionConfiguration

public protocol SubscriptionConfiguration: RouterConfiguration {
  var automaticRetry: AutomaticRetry? { get }
  var durationUntilTimeout: Int { get }
  var heartbeatInterval: UInt { get }
  var supressLeaveEvents: Bool { get }
  var requestMessageCountThreshold: UInt { get }
  var filterExpression: String? { get }
}

extension SubscriptionConfiguration {
  /// The hash value.
  ///
  /// Hash values are not guaranteed to be equal across different executions of your program.
  /// Do not save hash values to use during a future execution.
  var subscriptionHashValue: Int {
    var hasher = Hasher()
    hasher.combine(durationUntilTimeout.hashValue)
    hasher.combine(heartbeatInterval.hashValue)
    hasher.combine(supressLeaveEvents.hashValue)
    hasher.combine(requestMessageCountThreshold.hashValue)
    hasher.combine(filterExpression.hashValue)
    hasher.combine(subscribeKey.hashValue)
    hasher.combine(uuid.hashValue)
    hasher.combine(useSecureConnections.hashValue)
    hasher.combine(origin.hashValue)
    hasher.combine(authKey.hashValue)
    return hasher.finalize()
  }
}

extension PubNubConfiguration: SubscriptionConfiguration {}
