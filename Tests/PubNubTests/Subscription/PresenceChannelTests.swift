//
//  PresenceChannelTests.swift
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

class PresenceChannelTests: XCTestCase {
  let testState = ["StateKey": "StateValue"]
  let state = PresenceChannel("TestChannel",
                              with: ["StateKey": "StateValue"],
                              and: .initialized)
  var mutableState = PresenceChannel("TestChannel",
                                     with: ["StateKey": "StateValue"],
                                     and: .initialized)

  func testUserState_Get() {
    XCTAssertEqual(state.userState as? [String: String], testState)
  }

  func testUserState_Set() {
    let newState = ["StateKey": "NewValue"]
    mutableState.userState = newState
    XCTAssertEqual(mutableState.userState as? [String: String], newState)
  }

  func testEquatable() {
    XCTAssertEqual(state, PresenceChannel("TestChannel"))
  }

  func testHashable() {
    XCTAssertEqual(state.hashValue, state.name.hashValue)
  }

  func testCustomStringConvertible() {
    XCTAssertEqual(state.description, state.name.description)
  }

  func testExpressibleByStringLiteral() {
    let literalState = PresenceChannel("StateName")
    XCTAssertEqual(literalState.name, "StateName")
  }
}
