//
//  PubNubEntityEvent.swift
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

public struct PubNubEntityEvent: Codable {
  public enum Action: String, Codable, Hashable {
    case updated = "set"
    case removed = "delete"
  }

  public enum EntityType: String, Codable, Hashable {
    case user = "uuid"
    case space = "channel"
    case membership
  }

  public let source: String
  public let version: String
  public let action: Action
  public let type: EntityType
  public let data: AnyJSON

  public init(
    source: String,
    version: String,
    action: Action,
    type: EntityType,
    data: AnyJSON
  ) {
    self.source = source
    self.version = version
    self.action = action
    self.type = type
    self.data = data
  }

  enum CodingKeys: String, CodingKey {
    case source
    case version
    case action = "event"
    case type
    case data
  }
}
