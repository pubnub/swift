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

/// A protocol that represents Precence for a PubNub Channel
public protocol PubNubPresence {
  /// The channel identifier
  var channel: String { get }
  /// The total number of UUIDs present on the channel
  var occupancy: Int { get set }
  /// The known UUIDs present on the channel
  ///
  /// The `count` of this Array may differ from the `occupancy` field
  var occupants: [String] { get set }
  /// The Dictionary of UUIDs mapped to their respective presence state data
  var occupantsState: [String: JSONCodable] { get set }

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

extension Dictionary where Key == String, Value == PubNubPresence {
  /// The total channels (keys) that this object contains
  public var totalChannels: Int {
    return keys.count
  }

  /// The total occupancy of all the channels in this `Dictioanry`
  public var totalOccupancy: Int {
    return values.reduce(0) { $0 + $1.occupancy }
  }
}

/// The default implementation of the `PubNubPresence` protocol
public struct PubNubPresenceBase: PubNubPresence, Hashable {
  public let channel: String
  public var occupancy: Int
  public var occupants: [String]
  var concreteOccupantsState: [String: AnyJSON]
  public var occupantsState: [String: JSONCodable] {
    get { return concreteOccupantsState }
    set { concreteOccupantsState = newValue.mapValues { $0.codableValue } }
  }

  /// The default init
  public init(
    channel: String,
    occupancy: Int,
    occupants: [String],
    occupantsState concreteOccupantsState: [String: JSONCodable]
  ) {
    self.channel = channel
    self.occupancy = occupancy
    self.occupants = occupants
    self.concreteOccupantsState = concreteOccupantsState.mapValues { $0.codableValue }
  }

  public init(from other: PubNubPresence) throws {
    self.init(
      channel: other.channel,
      occupancy: other.occupancy,
      occupants: other.occupants,
      occupantsState: other.occupantsState
    )
  }

  init(from hereNow: HereNowChannelsPayload, channel: String) {
    self.init(
      channel: channel,
      occupancy: hereNow.occupancy,
      occupants: hereNow.occupants,
      occupantsState: hereNow.occupantsState
    )
  }
}

extension Dictionary where Key == String, Value == HereNowChannelsPayload {
  var asPubNubPresenceBase: [String: PubNubPresenceBase] {
    var presenceByChannel = [String: PubNubPresenceBase]()
    forEach { presenceByChannel[$0.key] = PubNubPresenceBase(from: $0.value, channel: $0.key) }
    return presenceByChannel
  }
}

// MARK: - Presence Change

/// The change in presence that took place on that channel
public enum PubNubPresenceChangeAction: CaseAccessible, Hashable {
  /// The list of UUIDs that joined the channel
  case join(uuids: [String])
  /// The list of UUIDs that left the channel
  case leave(uuids: [String])
  /// The list of UUIDs that timed-out on the channel
  case timeout(uuids: [String])
  /// The UUID and the presence state that changed for that UUID
  case stateChange(uuid: String, state: JSONCodable)

  public static func == (lhs: PubNubPresenceChangeAction, rhs: PubNubPresenceChangeAction) -> Bool {
    switch (lhs, rhs) {
    case let (.join(lhsUUIDs), .join(rhsUUIDs)),
         let (.leave(lhsUUIDs), .leave(rhsUUIDs)),
         let (.timeout(lhsUUIDs), .timeout(rhsUUIDs)):
      return lhsUUIDs == rhsUUIDs
    case let (.stateChange(lhsUUID, lhsState), .stateChange(rhsUUID, rhsState)):
      return lhsUUID == rhsUUID && lhsState.codableValue == rhsState.codableValue
    default:
      return false
    }
  }

  public func hash(into hasher: inout Hasher) {
    switch self {
    case let .join(uuids: uuids),
         let .leave(uuids: uuids),
         let .timeout(uuids: uuids):
      hasher.combine(uuids)
    case let .stateChange(uuid, state):
      hasher.combine(uuid)
      hasher.combine(state.codableValue)
    }
  }
}

extension Array where Element == PubNubPresenceChangeAction {
  /// Whether the array contains a `PubNubPresenceChangeAction.join` that contains the UUID
  /// - Parameter contains: The unique identifier to search for
  public func join(contains uuid: String) -> Bool {
    return contains(where: { $0[case: PubNubPresenceChangeAction.join]?.contains(uuid) ?? false })
  }

  /// Whether the array contains a `PubNubPresenceChangeAction.leave` that contains the UUID
  /// - Parameter contains: The unique identifier to search for
  public func leave(contains uuid: String) -> Bool {
    return contains(where: { $0[case: PubNubPresenceChangeAction.leave]?.contains(uuid) ?? false })
  }

  /// Whether the array contains a `PubNubPresenceChangeAction.timeout` that contains the UUID
  /// - Parameter contains: The unique identifier to search for
  public func timeout(contains uuid: String) -> Bool {
    return contains(where: { $0[case: PubNubPresenceChangeAction.timeout]?.contains(uuid) ?? false })
  }
}

/// A protocol that represents a PubNub Precence changeset
public protocol PubNubPresenceChange {
  /// One or more presence change that took place
  var actions: [PubNubPresenceChangeAction] { get }
  /// Occupance of the channel at the time of the event
  var occupancy: Int { get }
  /// The timetoken of the presence change
  var timetoken: Timetoken { get }
  /// Whether a HereNow  call be performed to receive missing occupant information
  var refreshHereNow: Bool { get }
  /// The channel for which the message belongs
  var channel: String { get }
  /// The channel group or wildcard subscription match (if exists)
  var subscription: String? { get }
  /// Timetoken for when the action was published
  var published: Timetoken? { get }
  /// Meta information for the message
  var metadata: JSONCodable? { get }

  /// Allows for converting  between different MessageEvent types
  init(from other: PubNubPresenceChange) throws
}

extension PubNubPresenceChange {
  /// Converts this protocol into a custom type
  /// - Parameter into: The explicit type for the returned value
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  public func transcode<T: PubNubPresenceChange>(into _: T.Type) throws -> T {
    return try transcode()
  }

  /// Converts this protocol into a custom type
  /// - Returns: The protocol intiailized as a custom type
  /// - Throws: An error why the custom type was unable to be created using this protocol instance
  public func transcode<T: PubNubPresenceChange>() throws -> T {
    // Check if we're already that object, and return
    if let custom = self as? T {
      return custom
    }

    return try T(from: self)
  }
}

// MARK: Concrete Base Class

/// The default implementation of the `PubNubPresenceChange` protocol
public struct PubNubPresenceChangeBase: PubNubPresenceChange, Hashable {
  public var actions: [PubNubPresenceChangeAction]
  /// Occupance of the channel at the time of the event
  public var occupancy: Int
  /// The timetoken of the presence change
  public var timetoken: Timetoken
  /// Whether a HereNow  call be performed to receive missing occupant information
  public var refreshHereNow: Bool
  /// The channel for which the message belongs
  public var channel: String
  /// The channel group or wildcard subscription match (if exists)
  public var subscription: String?
  /// Timetoken for when the action was initiated
  public var published: Timetoken?
  /// A concrete representation of the `metadata`
  var concreteMetadata: AnyJSON?
  public var metadata: JSONCodable? {
    return concreteMetadata
  }

  /// Allows for transcoding between different MessageEvent types
  public init(from other: PubNubPresenceChange) throws {
    self.init(
      actions: other.actions,
      occupancy: other.occupancy,
      timetoken: other.timetoken,
      refreshHereNow: other.refreshHereNow,
      channel: other.channel,
      subscription: other.subscription,
      published: other.published,
      metadata: other.metadata
    )
  }

  /// Attempts to initialize from  a `SubscribeMessagePayload`
  ///
  /// This will fail if the `payload` proprety of the `SubscribeMessagePayload` cannot be
  /// decoded into a `SubscribePresencePayload`.
  init?(from subscribe: SubscribeMessagePayload) {
    guard let payload = try? subscribe.payload.decode(SubscribePresencePayload.self) else {
      return nil
    }

    var actions = [PubNubPresenceChangeAction]()
    if let uuid = payload.uuid {
      switch payload.actionEvent {
      case .join:
        actions.append(.join(uuids: [uuid]))
      case .leave:
        actions.append(.leave(uuids: [uuid]))
      case .timeout:
        actions.append(.timeout(uuids: [uuid]))
      default:
        break
      }
      // Set state whenever a state value is passed (subscribe with state || state-change)
      if let state = payload.state {
        actions.append(.stateChange(uuid: uuid, state: state))
      }
    }

    if !payload.join.isEmpty {
      actions.append(.join(uuids: payload.join))
    }
    if !payload.leave.isEmpty {
      actions.append(.leave(uuids: payload.leave))
    }
    if !payload.timeout.isEmpty {
      actions.append(.timeout(uuids: payload.timeout))
    }

    self.init(
      actions: actions,
      occupancy: payload.occupancy,
      timetoken: payload.timestamp,
      refreshHereNow: payload.refreshHereNow,
      channel: subscribe.channel,
      subscription: subscribe.subscription,
      published: subscribe.publishTimetoken.timetoken,
      metadata: subscribe.metadata
    )
  }

  /// Base init for each property
  public init(
    actions: [PubNubPresenceChangeAction],
    occupancy: Int,
    timetoken: Timetoken,
    refreshHereNow: Bool,
    channel: String,
    subscription: String? = nil,
    published: Timetoken? = nil,
    metadata: JSONCodable? = nil
  ) {
    self.actions = actions
    self.occupancy = occupancy
    self.timetoken = timetoken
    self.refreshHereNow = refreshHereNow
    self.channel = channel
    self.subscription = subscription
    self.published = published
    concreteMetadata = metadata?.codableValue
  }
}
