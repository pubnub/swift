//
//  PubNubPresence.swift
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

// MARK: Outbound Protocol

// TODO:
public protocol PubNubChannelPresence {
  var channel: String { get }
  var occupancy: Int { get }
  var occupants: [String] { get }
}

/// A protocol that represents a PubNub Precence changeset
public protocol PubNubPresence {
  /// One or more actions that occurred at this timetoken instance
  var actions: [PubNubPresenceAction] { get }
  /// Occupance of the channel at the time of the event
  var occupancy: Int { get }
  /// Timetoken for the presence change
  var timetoken: Timetoken { get }
  /// The updated state for the channel
  var stateChange: [String: JSONCodable]? { get }

  /// The channel for which the message belongs
  var channel: String { get }
  /// The channel group or wildcard subscription match (if exists)
  var subscription: String? { get }
  /// Timetoken for when the action was initiated
  var published: Timetoken? { get }
  /// Meta information for the message
  var metadata: JSONCodable? { get }

  /// Allows for converting  between different MessageEvent types
  init(from other: PubNubPresence) throws
}

extension PubNubPresence {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  public func transcode<T: PubNubPresence>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  public func transcode<T: PubNubPresence>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

/// The different types of presence actions that can correspond to a PubNub channel
public enum PubNubPresenceAction: CaseAccessible, Hashable {
  case join(uuid: String, time: Timetoken)
  case leave(uuid: String, time: Timetoken)
  case timeout(uuid: String, time: Timetoken)

  public var uuid: String {
    switch self {
    case .join(uuid: let uuid, time: _),
         .leave(uuid: let uuid, time: _),
         .timeout(uuid: let uuid, time: _):
      return uuid
    }
  }
  public var timetoken: Timetoken {
    switch self {
    case .join(uuid: _, time: let timetoken),
         .leave(uuid: _, time: let timetoken),
         .timeout(uuid: _, time: let timetoken):
      return timetoken
    }
  }
  public var associatedValue: (uuid: String, time: Timetoken) {
    switch self {
    case .join(uuid: let uuid, time: let timetoken),
         .leave(uuid: let uuid, time: let timetoken),
         .timeout(uuid: let uuid, time: let timetoken):
      return (uuid: uuid, time: timetoken)
    }
  }

  public var isJoin: Bool {
    switch self {
    case .join:
      return true
    default:
      return false
    }
  }
  public var isLeave: Bool {
    switch self {
    case .leave:
      return true
    default:
      return false
    }
  }
  public var isTimeout: Bool {
    switch self {
    case .timeout:
      return true
    default:
      return false
    }
  }
}

extension Array where Element == PubNubPresenceAction {
  public var isJoin: Bool {
    return count == 1 && (first?.isJoin ?? false)
  }
  public var isLeave: Bool {
    return count == 1 && (first?.isLeave ?? false)
  }
  public var isTimeout: Bool {
    return count == 1 && (first?.isTimeout ?? false)
  }

  public var joins: [PubNubPresenceAction] {
    return self.filter { $0.isJoin }
  }
  public var leaves: [PubNubPresenceAction] {
    return self.filter { $0.isLeave }
  }
  public var timeouts: [PubNubPresenceAction] {
    return self.filter { $0.isTimeout }
  }

  public var uuid: String? {
    if count == 1 {
      return first?.uuid
    }
    return nil
  }
}

// MARK: Concrete Base Class

/// The concrete base object that represents a `PubNubPrecence`
public struct PubNubPresenceBase: PubNubPresence, Hashable {
  /// One or more actions that occurred at this timetoken instance
  public var actions: [PubNubPresenceAction]
  /// Occupance of the channel at the time of the event
  public var occupancy: Int
  /// Timetoken for the presence change
  public var timetoken: Timetoken
  /// A concrete representation of the `stateChange`
  var concreteStateChange: [String: AnyJSON]?
  /// The channel for which the message belongs
  public var channel: String
  /// The channel group or wildcard subscription match (if exists)
  public var subscription: String?
  /// Timetoken for when the action was initiated
  public var published: Timetoken?
  /// A concrete representation of the `metadata`
  var concreteMetadata: AnyJSON?

  public var joins: [String] {
    return actions.joins.map { $0.uuid }
  }
  public var leaves: [String] {
    return actions.joins.map { $0.uuid }
  }
  public var timeouts: [String] {
    return actions.joins.map { $0.uuid }
  }

  public var metadata: JSONCodable? {
    return concreteMetadata
  }

  public var stateChange: [String: JSONCodable]? {
    return concreteStateChange
  }

  /// Allows for transcoding between different MessageEvent types
  public init(from other: PubNubPresence) throws {
    self.init(
      actions: other.actions,
      occupancy: other.occupancy,
      timetoken: other.timetoken,
      channel: other.channel,
      stateChange: other.stateChange?.mapValues { $0.codableValue },
      subscription: other.subscription,
      published: other.published,
      metadata: other.metadata?.codableValue
    )
  }

  /// Attempts to create a `PubNubPresence` from  a SubscribeMessagePayload
  ///
  /// This will fail if the `payload` proprety of the `SubscribeMessagePayload` cannot be
  /// decoded into a `SubscribePresencePayload`.
  init?(from subscribe: SubscribeMessagePayload) {
    guard let payload = try? subscribe.payload.decode(SubscribePresencePayload.self) else {
      return nil
    }

    self.init(
      actions: payload.actions,
      occupancy: payload.occupancy,
      timetoken: payload.timetoken,
      channel: subscribe.channel,
      stateChange: payload.stateChange,
      subscription: subscribe.subscription,
      published: subscribe.publishTimetoken.timetoken,
      metadata: subscribe.metadata
    )
  }

  /// Base init for each property
  public init(
    actions: [PubNubPresenceAction],
    occupancy: Int,
    timetoken: Timetoken,
    channel: String,
    stateChange: [String: AnyJSON]? = nil,
    subscription: String? = nil,
    published: Timetoken? = nil,
    metadata: AnyJSON? = nil
  ) {
    self.actions = actions
    self.occupancy = occupancy
    self.timetoken = timetoken
    concreteStateChange = stateChange
    self.channel = channel
    self.subscription = subscription
    self.published = published
    concreteMetadata = metadata
  }
}
