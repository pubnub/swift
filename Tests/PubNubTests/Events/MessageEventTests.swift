//
//  MessageEventTests.swift
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

@testable import PubNub
import XCTest

class MessageEventTests: XCTestCase {
  let message = """
  {
    \"a\": \"1\",
    \"f\": 514,
    \"i\": \"db9c5e39-7c95-40f5-8d71-125765b6f561\",
    \"p\": {
      \"t\": \"15614814456537442\",
      \"r\": 2
    },
    \"k\": \"demo\",
    \"c\": \"channelSwift\",
    \"d\": {
      \"message\": \"Hello\"
    },
    \"u\": {
      \"metaKey\": \"metaValue\"
    },
    \"b\": \"channelSwift\"
  }
  """

  let messageNoPublisher = """
  {
    \"a\": \"1\",
    \"f\": 514,
    \"p\": {
      \"t\": \"15614814456537442\",
      \"r\": 2
    },
    \"k\": \"demo\",
    \"c\": \"channelSwift\",
    \"d\": {
      \"message\": \"Hello\"
    },
    \"u\": {
      \"metaKey\": \"metaValue\"
    },
    \"b\": \"channelSwift\"
  }
  """

  func testMessageEvent_MessageResponse() {
    guard let messageData = message.data(using: .utf8),
          let event = try? Constant.jsonDecoder.decode(MessageResponse.self,
                                                       from: messageData) as MessageEvent
    else {
      return XCTFail("Could not create data from string")
    }

    XCTAssertEqual(event.publisher, "db9c5e39-7c95-40f5-8d71-125765b6f561")
    XCTAssertEqual(event.payload, AnyJSON(["message": "Hello"]))
    XCTAssertEqual(event.subscription, "channelSwift")
    XCTAssertEqual(event.timetoken, 15_614_814_456_537_442)
    XCTAssertEqual(event.userMetadata, AnyJSON(["metaKey": "metaValue"]))
  }

  func testMessageEvent_Description() {
    guard let messageData = message.data(using: .utf8),
          let event = try? Constant.jsonDecoder.decode(MessageResponse.self,
                                                       from: messageData) as MessageEvent
    else {
      return XCTFail("Could not create data from string")
    }

    let user = "User 'db9c5e39-7c95-40f5-8d71-125765b6f561'"
    let message = "'{\"message\":\"Hello\"}' message"

    let description = "\(user) sent \(message) on 'channelSwift' at 15614814456537442"

    XCTAssertEqual(event.description, description)
  }

  func testMessageEvent_Description_NoPublisher() {
    guard let messageData = messageNoPublisher.data(using: .utf8),
          let event = try? Constant.jsonDecoder.decode(MessageResponse.self,
                                                       from: messageData) as MessageEvent
    else {
      return XCTFail("Could not create data from string")
    }

    let user = "User 'Unknown'"
    let message = "'{\"message\":\"Hello\"}' message"

    let description = "\(user) sent \(message) on 'channelSwift' at 15614814456537442"

    XCTAssertEqual(event.description, description)
  }
}
