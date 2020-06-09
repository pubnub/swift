//
//  SubscribePresencePayload.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2020 PubNub Inc.
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

struct SubscribePresencePayload: Codable, Hashable {
  let actions: [PubNubPresenceAction]

  let occupancy: Int
  let timetoken: Timetoken
  let stateChange: [String: AnyJSON]?

  let actionEvent: Action

  /// The type of presence change that occurred
  enum Action: String, Codable, Hashable {
    /// Another user has joined the channel
    case join
    /// Another user has explicitly left the channel
    case leave
    /// Another user has timed out on the channel and has left
    case timeout
    /// A user has updated their state
    case stateChange = "state-change"
    /// Multiple presence changes have taken place in a single response
    case interval
  }

  enum CodingKeys: String, CodingKey {
    case action
    case timetoken = "timestamp"
    case occupancy

    // Internval Keys
    case join
    case leave
    case timeout

    // State breakdown
    case uuid
    case stateChange = "data"
  }

  public init(
    actionEvent: Action,
    actions: [PubNubPresenceAction],
    occupancy: Int,
    timetoken: Timetoken,
    stateChange: [String: AnyJSON]? = nil
  ) {
    self.actionEvent = actionEvent
    self.actions = actions
    self.occupancy = occupancy
    self.timetoken = timetoken
    self.stateChange = stateChange
  }

  // We want the timetoken as a Int instead of a String
  // swiftlint:disable:next cyclomatic_complexity
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    actionEvent = try container.decode(Action.self, forKey: .action)
    occupancy = try container.decode(Int.self, forKey: .occupancy)
    timetoken = try container.decode(Timetoken.self, forKey: .timetoken)
    stateChange = try container.decodeIfPresent([String: AnyJSON].self, forKey: .stateChange)

    let uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""

    var actions = [PubNubPresenceAction]()
    switch actionEvent {
    case .join:
      actions.append(PubNubPresenceAction.join(uuid: uuid, time: timetoken))
    case .leave:
      actions.append(PubNubPresenceAction.leave(uuid: uuid, time: timetoken))
    case .timeout:
      actions.append(PubNubPresenceAction.timeout(uuid: uuid, time: timetoken))
    case .stateChange:
      break
    case .interval:
      if let join = try container.decodeIfPresent([String].self, forKey: .join), !join.isEmpty {
        for uuid in join {
          actions.append(PubNubPresenceAction.join(uuid: uuid, time: timetoken))
        }
      }
      if let leave = try container.decodeIfPresent([String].self, forKey: .leave), !leave.isEmpty {
        for uuid in leave {
          actions.append(PubNubPresenceAction.leave(uuid: uuid, time: timetoken))
        }
      }
      if let timeout = try container.decodeIfPresent([String].self, forKey: .timeout), !timeout.isEmpty {
        for uuid in timeout {
          actions.append(PubNubPresenceAction.timeout(uuid: uuid, time: timetoken))
        }
      }
    }
    self.actions = actions
  }

  // swiftlint:disable:next cyclomatic_complexity
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(actionEvent, forKey: .action)
    try container.encode(timetoken, forKey: .timetoken)
    try container.encode(occupancy, forKey: .occupancy)
    try container.encodeIfPresent(stateChange, forKey: .stateChange)

    switch actionEvent {
    case .join:
      try container.encodeIfPresent(actions.first?[case: PubNubPresenceAction.join]?.0, forKey: .uuid)
    case .leave:
      try container.encodeIfPresent(actions.first?[case: PubNubPresenceAction.leave]?.0, forKey: .uuid)
    case .timeout:
      try container.encodeIfPresent(actions.first?[case: PubNubPresenceAction.timeout]?.0, forKey: .uuid)
    case .stateChange:
      break
    case .interval:
      var joins = [String]()
      var leaves = [String]()
      var timeouts = [String]()

      for action in actions {
        switch action {
        case .join(uuid: let uuid, time: _):
          joins.append(uuid)
        case .leave(uuid: let uuid, time: _):
          leaves.append(uuid)
        case .timeout(uuid: let uuid, time: _):
          timeouts.append(uuid)
        }
      }

      if !joins.isEmpty {
        try container.encode(joins, forKey: .join)
      }
      if !leaves.isEmpty {
        try container.encode(leaves, forKey: .leave)
      }
      if !timeouts.isEmpty {
        try container.encode(timeouts, forKey: .timeout)
      }
    }
  }
}
