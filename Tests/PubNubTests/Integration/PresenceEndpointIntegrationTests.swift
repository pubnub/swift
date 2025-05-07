//
//  PresenceEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import XCTest

class PresenceEndpointIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: PresenceEndpointIntegrationTests.self)

  // MARK: - Here Now Single Channel

  func testHereNow_SingleChannel_Stateless() {
    let hereNowExpect = expectation(description: "Here Now Response")
    let testChannel = "testHereNow_SingleChannel_Statelesssss"
    let presenceConfig = presenceConfiguration()
    let client = PubNub(configuration: presenceConfig)

    let performHereNow = {
      client.hereNow(on: [testChannel], includeState: true) { result in
        switch result {
        case let .success(channels):
          XCTAssertNotNil(channels[testChannel])
          XCTAssertGreaterThan(channels.totalChannels, 0)
          XCTAssertGreaterThan(channels.totalOccupancy, 0)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    
    listener.didReceivePresence = { event in
      if event.channel == testChannel, event.actions.join(contains: presenceConfig.userId) {
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
    let setStateExpect = expectation(description: "Set State Response")
    let testChannel = "testHereNow_SingleChannel_State"
    let presenceConfig = presenceConfiguration()
    let client = PubNub(configuration: presenceConfig)

    let performHereNow = {
      client.hereNow(on: [testChannel], includeState: true) { result in
        switch result {
        case let .success(channels):
          XCTAssertNotNil(channels[testChannel])
          XCTAssertEqual(
            channels[testChannel]?.occupantsState[presenceConfig.userId]?.codableValue,
            ["StateKey": "StateValue"]
          )
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }
    let performSetState = {
      client.setPresence(state: ["StateKey": "StateValue"], on: [testChannel]) { result in
        switch result {
        case let .success(channels):
          XCTAssertEqual(channels.codableValue[rawValue: "StateKey"] as? String, "StateValue")
          performHereNow()
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        setStateExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    
    listener.didReceivePresence = { event in
      if event.channel == testChannel, event.actions.join(contains: presenceConfig.userId) {
        performSetState()
      }
    }
    
    client.add(listener)
    client.subscribe(to: [testChannel], withPresence: true)

    defer { listener.cancel() }
    wait(for: [setStateExpect, hereNowExpect], timeout: 10.0)
  }

  func testHereNow_SingleChannel_EmptyPresence() {
    let hereNowExpect = expectation(description: "Here Now Response")
    let testChannel = "testHereNow_SingleChannel_EmptyPresence"
    let presenceConfig = presenceConfiguration()
    let client = PubNub(configuration: presenceConfig)

    client.hereNow(on: [testChannel], includeState: true) { result in
      switch result {
      case let .success(channels):
        XCTAssertNotNil(channels[testChannel])
        XCTAssertEqual(channels.totalOccupancy, 0)
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
    let testChannel = "testHereNow_MultiChannel_Stateless"
    let otherChannel = "testHereNow_MultiChannel_Stateless_Other"
    let presenceConfig = presenceConfiguration()
    let client = PubNub(configuration: presenceConfig)

    let performHereNow = {
      client.hereNow(on: [testChannel, otherChannel]) { result in
        switch result {
        case let .success(channels):
          XCTAssertNotNil(channels[testChannel])
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    
    listener.didReceivePresence = { event in
      if event.channel == testChannel, event.actions.join(contains: presenceConfig.userId) {
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
    let setStateExpect = expectation(description: "Set State Response")
    let testChannel = "testHereNow_MultiChannel_State"
    let otherChannel = "testHereNow_MultiChannel_State_Other"
    let presenceConfig = presenceConfiguration()
    let client = PubNub(configuration: presenceConfig)

    let performHereNow = {
      client.hereNow(on: [testChannel, otherChannel], includeState: true) { result in
        switch result {
        case let .success(channels):
          XCTAssertNotNil(channels[testChannel])
          XCTAssertEqual(
            channels[testChannel]?.occupantsState[presenceConfig.userId]?.codableValue,
            ["StateKey": "StateValue"]
          )
          XCTAssertEqual(
            channels[otherChannel]?.occupantsState[presenceConfig.userId]?.codableValue,
            ["StateKey": "StateValue"]
          )
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }
    
    let performSetState = {
      client.setPresence(state: ["StateKey": "StateValue"], on: [testChannel, otherChannel]) { result in
        switch result {
        case let .success(channels):
          XCTAssertEqual(channels.codableValue[rawValue: "StateKey"] as? String, "StateValue")
          performHereNow()
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        setStateExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    
    listener.didReceivePresence = { event in
      if event.channel == testChannel, event.actions.join(contains: presenceConfig.userId) {
        performSetState()
      }
    }
    
    client.add(listener)
    client.subscribe(to: [testChannel, otherChannel], withPresence: true)

    defer { listener.cancel() }
    wait(for: [setStateExpect, hereNowExpect], timeout: 10.0)
  }

  func testHereNow_MultiChannel_EmptyPresence() {
    let hereNowExpect = expectation(description: "Here Now Response")
    let testChannel = "testHereNow_MultiChannel_EmptyPresence"
    let otherChannel = "testHereNow_MultiChannel_EmptyPresence_Other"
    let presenceConfig = presenceConfiguration()
    let client = PubNub(configuration: presenceConfig)

    client.hereNow(on: [testChannel, otherChannel], includeState: true) { result in
      switch result {
      case let .success(channels):
        XCTAssertTrue(channels.isEmpty)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      hereNowExpect.fulfill()
    }

    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testWhereNow() {
    let whereNowExpect = expectation(description: "Where Now Response")
    let testChannel1 = "testWhereNowChannel1"
    let testChannel2 = "testWhereNowChannel2"
    let presenceConfig = presenceConfiguration()
    let client = PubNub(configuration: presenceConfig)

    let performWhereNow = {
      client.whereNow(for: client.configuration.userId) { result in
        switch result {
        case let .success(channels):
          let channelsByUserId  = channels[client.configuration.userId] ?? []
          XCTAssertEqual(channelsByUserId.count, 2)
          XCTAssertEqual(Set(channelsByUserId), Set([testChannel1, testChannel2]))
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        whereNowExpect.fulfill()
      }
    }
    
    let listener = SubscriptionListener()
    
    listener.didReceivePresence = { event in
      if event.channel == testChannel2, event.actions.join(contains: presenceConfig.userId) {
        performWhereNow()
      }
    }
    
    client.add(listener)
    client.subscribe(to: [testChannel1, testChannel2], withPresence: true)
    
    defer { listener.cancel() }
    wait(for: [whereNowExpect], timeout: 30.0)
  }
}

private extension PresenceEndpointIntegrationTests {
  func presenceConfiguration() -> PubNubConfiguration {
    PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: randomString(),
      durationUntilTimeout: 11
    )
  }
}
