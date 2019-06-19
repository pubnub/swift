//
//  PubNubConfigurationTests.swift
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

@testable import PubNub
import XCTest

class PubNubConfigurationTests: XCTestCase {
  let publishDictionaryKey = "PubNubPubKey"
  let subscribeDictionaryKey = "PubNubSubKey"

  let plistPublishKeyValue = "TEST_PUB_KEY"
  let plistSubscribeKeyValue = "TEST_SUB_KEY"

  let publishKeyValue = "NotARealPublishKey"
  let subscribeKeyValue = "NotARealSubscribeKey"

  // Info.plist for the PubNubTests Target Bundle
  let testsBundle = Bundle(for: PubNubConfigurationTests.self)

  func testDefault() {
    let config = PubNubConfiguration.default

    XCTAssertEqual(config, PubNubConfiguration.default)

    XCTAssertEqual(config.publishKey, "")
    XCTAssertEqual(config.subscribeKey, "")
    XCTAssertEqual(config.cipherKey, nil)
    XCTAssertEqual(config.authKey, nil)
    XCTAssertNotNil(config.uuid)
    XCTAssertEqual(config.useSecureConnections, true)
    XCTAssertEqual(config.origin, "ps.pndsn.com")
    XCTAssertEqual(config.presenceTimeout, 300)
    XCTAssertEqual(config.heartbeatInterval, -1)
    XCTAssertEqual(config.supressLeaveEvents, false)
    XCTAssertEqual(config.requestMessageCountThreshold, 100)
  }

  func testInit_Bundle() {
    let config = PubNubConfiguration(from: testsBundle)

    XCTAssertEqual(config.publishKey, plistPublishKeyValue)
    XCTAssertEqual(config.subscribeKey, plistSubscribeKeyValue)
  }

  func testInit_Dictionary() {
    let infoDict = [publishDictionaryKey: "test_pub_key",
                    subscribeDictionaryKey: "test_sub_key"]

    let config = PubNubConfiguration(from: infoDict,
                                     using: publishDictionaryKey,
                                     and: subscribeDictionaryKey)

    XCTAssertEqual(config.publishKey, infoDict[publishDictionaryKey])
    XCTAssertEqual(config.subscribeKey, infoDict[subscribeDictionaryKey])
  }

  func testInit_RawValues() {
    let config = PubNubConfiguration(publishKey: publishKeyValue,
                                     subscribeKey: subscribeKeyValue)

    XCTAssertEqual(config.publishKey, publishKeyValue)
    XCTAssertEqual(config.subscribeKey, subscribeKeyValue)
  }
}
