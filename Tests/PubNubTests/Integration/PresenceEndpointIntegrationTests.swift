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

  // MARK: - Here Now Single Channel

  func testHereNow_SingleChannel_Stateless() {
    let hereNowExpect = expectation(description: "Here Now Response")

    var configuration = PubNubConfiguration(from: testsBundle)
    configuration.durationUntilTimeout = 11
    let client = PubNub(configuration: configuration)
    let testChannel = "testHereNow_SingleChannel_Stateless"

    let performHereNow = {
      // Here Now Test
      client.hereNow(on: [testChannel]) { result in
        switch result {
        case let .success(response):
          let channelPresence = response.channels[testChannel]
          XCTAssertNotNil(channelPresence)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    listener.didReceivePresence = { event in
      if event.channel == testChannel, event.actions.isJoin, event.actions.uuid == configuration.uuid {
        performHereNow()
      }
    }
    client.add(listener)

    client.subscribe(to: [testChannel], withPresence: true)

    defer { listener.cancel() }
    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_SingleChannel_State() {
    let hereNowExpect = expectation(description: "Here Now Response")

    var configuration = PubNubConfiguration(from: testsBundle)
    configuration.durationUntilTimeout = 11
    let client = PubNub(configuration: configuration)
    let testChannel = "testHereNow_SingleChannel_State"

    let performHereNow = {
      // Here Now Test
      client.hereNow(on: [testChannel], also: true) { result in
        switch result {
        case let .success(response):
          let channel = response.channels[testChannel]
          XCTAssertNotNil(channel)
          XCTAssertEqual(channel?.occupants[configuration.uuid], ["StateKey": "StateValue"])
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    listener.didReceivePresence = { event in
      if event.channel == testChannel, event.actions.isJoin, event.actions.uuid == configuration.uuid {
        performHereNow()
      }
    }
    client.add(listener)

    client.subscribe(to: [testChannel], withPresence: true, setting: [testChannel: ["StateKey": "StateValue"]])

    defer { listener.cancel() }
    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_SingleChannel_EmptyPresence() {
    let hereNowExpect = expectation(description: "Here Now Response")

    var configuration = PubNubConfiguration(from: testsBundle)
    configuration.durationUntilTimeout = 11
    let client = PubNub(configuration: configuration)
    let testChannel = "testHereNow_SingleChannel_EmptyPresence"

    client.hereNow(on: [testChannel], also: true) { result in
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

    var configuration = PubNubConfiguration(from: testsBundle)
    configuration.durationUntilTimeout = 11
    let client = PubNub(configuration: configuration)
    let testChannel = "testHereNow_MultiChannel_Stateless"
    let otherChannel = "testHereNow_MultiChannel_Stateless_Other"

    let performHereNow = {
      // Here Now Test
      client.hereNow(on: [testChannel, otherChannel]) { result in
        switch result {
        case let .success(response):
          let channelPresence = response.channels[testChannel]
          XCTAssertNotNil(channelPresence)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    listener.didReceivePresence = { event in
      if event.channel == testChannel, event.actions.isJoin, event.actions.uuid == configuration.uuid {
        performHereNow()
      }
    }
    client.add(listener)

    client.subscribe(to: [testChannel], withPresence: true)

    defer { listener.cancel() }
    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_MultiChannel_State() {
    let hereNowExpect = expectation(description: "Here Now Response")

    var configuration = PubNubConfiguration(from: testsBundle)
    configuration.durationUntilTimeout = 11
    let client = PubNub(configuration: configuration)
    let testChannel = "testHereNow_MultiChannel_State"
    let otherChannel = "testHereNow_MultiChannel_State_Other"

    let performHereNow = {
      // Here Now Test
      client.hereNow(on: [testChannel, otherChannel], also: true) { result in
        switch result {
        case let .success(response):
          let channel = response.channels[testChannel]
          XCTAssertNotNil(channel)
          XCTAssertEqual(channel?.occupants[configuration.uuid], ["StateKey": "StateValue"])
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    listener.didReceivePresence = { event in
      if event.channel == testChannel, event.actions.isJoin, event.actions.uuid == configuration.uuid {
        performHereNow()
      }
    }
    client.add(listener)

    client.subscribe(to: [testChannel], withPresence: true, setting: [testChannel: ["StateKey": "StateValue"]])

    defer { listener.cancel() }
    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_MultiChannel_EmptyPresence() {
    let hereNowExpect = expectation(description: "Here Now Response")

    var configuration = PubNubConfiguration(from: testsBundle)
    configuration.durationUntilTimeout = 11
    let client = PubNub(configuration: configuration)
    let testChannel = "testHereNow_MultiChannel_EmptyPresence"
    let otherChannel = "testHereNow_MultiChannel_EmptyPresence_Other"

    client.hereNow(on: [testChannel, otherChannel], also: true) { result in
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
