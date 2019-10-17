//
//  PresenceEndpointIntegrationTests.swift
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

import PubNub
import XCTest

class PresenceEndpointIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: PresenceEndpointIntegrationTests.self)

  let channel = "SwiftPresenceITest"
  let emptyChannel = "SwiftEmptyPresenceITest"
  let otherEmptyChannel = "SwiftOtherEmptyPresenceITest"

  // MARK: - Here Now Single Channel

  func testHereNow_SingleChannel_Stateless() {
    let hereNowExpect = expectation(description: "Here Now Response")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let performHereNow = {
      // Here Now Test
      client.hereNow(on: [self.channel]) { result in
        switch result {
        case let .success(response):
          let channelPresence = response.channels[self.channel]
          XCTAssertNotNil(channelPresence)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    listener.didReceivePresence = { event in
      if event.channel == self.channel, event.join.contains(configuration.uuid) {
        performHereNow()
      }
    }
    client.add(listener)

    client.subscribe(to: [channel], withPresence: true)

    defer { listener.cancel() }
    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_SingleChannel_State() {
    let hereNowExpect = expectation(description: "Here Now Response")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let performHereNow = {
      // Here Now Test
      client.hereNow(on: [self.channel], also: true) { result in
        switch result {
        case let .success(response):
          let channel = response.channels[self.channel]
          XCTAssertNotNil(channel)
          let userPresence = channel?.uuids.first(where: { $0.uuid == configuration.uuid })
          XCTAssertNotNil(userPresence?.state)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    listener.didReceivePresence = { event in
      if event.channel == self.channel, event.join.contains(configuration.uuid) {
        performHereNow()
      }
    }
    client.add(listener)

    client.subscribe(to: [channel], withPresence: true, setting: [channel: ["StateKey": "StateValue"]])

    defer { listener.cancel() }
    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_SingleChannel_EmptyPresence() {
    let hereNowExpect = expectation(description: "Here Now Response")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    client.hereNow(on: [emptyChannel], also: true) { result in
      switch result {
      case let .success(response):
        XCTAssertTrue(response.channels.isEmpty)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      hereNowExpect.fulfill()
    }

    wait(for: [hereNowExpect], timeout: 10.0)
  }

  // MARK: - Here Now Mutlti Channel

  func testHereNow_MultiChannel_Stateless() {
    let hereNowExpect = expectation(description: "Here Now Response")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let performHereNow = {
      // Here Now Test
      client.hereNow(on: [self.channel, self.emptyChannel]) { result in
        switch result {
        case let .success(response):
          let channelPresence = response.channels[self.channel]
          XCTAssertNotNil(channelPresence)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    listener.didReceivePresence = { event in
      if event.channel == self.channel, event.join.contains(configuration.uuid) {
        performHereNow()
      }
    }
    client.add(listener)

    client.subscribe(to: [channel], withPresence: true)

    defer { listener.cancel() }
    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_MultiChannel_State() {
    let hereNowExpect = expectation(description: "Here Now Response")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let performHereNow = {
      // Here Now Test
      client.hereNow(on: [self.channel, self.emptyChannel], also: true) { result in
        switch result {
        case let .success(response):
          let channel = response.channels[self.channel]
          XCTAssertNotNil(channel)
          let userPresence = channel?.uuids.first(where: { $0.uuid == configuration.uuid })
          XCTAssertNotNil(userPresence?.state)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    listener.didReceivePresence = { event in
      if event.channel == self.channel, event.join.contains(configuration.uuid) {
        performHereNow()
      }
    }
    client.add(listener)

    client.subscribe(to: [channel], withPresence: true, setting: [channel: ["StateKey": "StateValue"]])

    defer { listener.cancel() }
    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_MultiChannel_EmptyPresence() {
    let hereNowExpect = expectation(description: "Here Now Response")

    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    client.hereNow(on: [emptyChannel, otherEmptyChannel], also: true) { result in
      switch result {
      case let .success(response):
        XCTAssertTrue(response.channels.isEmpty)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      hereNowExpect.fulfill()
    }

    wait(for: [hereNowExpect], timeout: 10.0)
  }
}
