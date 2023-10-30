//
//  PresenceEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
    let testChannel = "testHereNow_SingleChannel_Statelesssss"

    let performHereNow = {
      // Here Now Test
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
      if event.channel == testChannel, event.actions.join(contains: configuration.uuid) {
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

    var configuration = PubNubConfiguration(from: testsBundle)
    configuration.durationUntilTimeout = 11
    let client = PubNub(configuration: configuration)
    let testChannel = "testHereNow_SingleChannel_State"

    let performHereNow = {
      // Here Now Test
      client.hereNow(on: [testChannel], includeState: true) { result in
        switch result {
        case let .success(channels):
          XCTAssertNotNil(channels[testChannel])
          XCTAssertEqual(
            channels[testChannel]?.occupantsState[configuration.uuid]?.codableValue,
            ["StateKey": "StateValue"]
          )
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }
    let performSetState = {
      // Here Now Test
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
      if event.channel == testChannel, event.actions.join(contains: configuration.uuid) {
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

    var configuration = PubNubConfiguration(from: testsBundle)
    configuration.durationUntilTimeout = 11
    let client = PubNub(configuration: configuration)
    let testChannel = "testHereNow_SingleChannel_EmptyPresence"

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

    var configuration = PubNubConfiguration(from: testsBundle)
    configuration.durationUntilTimeout = 11
    let client = PubNub(configuration: configuration)
    let testChannel = "testHereNow_MultiChannel_Stateless"
    let otherChannel = "testHereNow_MultiChannel_Stateless_Other"

    let performHereNow = {
      // Here Now Test
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
      if event.channel == testChannel, event.actions.join(contains: configuration.uuid) {
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

    var configuration = PubNubConfiguration(from: testsBundle)
    configuration.durationUntilTimeout = 11
    let client = PubNub(configuration: configuration)
    let testChannel = "testHereNow_MultiChannel_State"
    let otherChannel = "testHereNow_MultiChannel_State_Other"

    let performHereNow = {
      // Here Now Test
      client.hereNow(on: [testChannel, otherChannel], includeState: true) { result in
        switch result {
        case let .success(channels):
          XCTAssertNotNil(channels[testChannel])
          XCTAssertEqual(
            channels[testChannel]?.occupantsState[configuration.uuid]?.codableValue,
            ["StateKey": "StateValue"]
          )
          XCTAssertEqual(
            channels[otherChannel]?.occupantsState[configuration.uuid]?.codableValue,
            ["StateKey": "StateValue"]
          )
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }
    let performSetState = {
      // Here Now Test
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
      if event.channel == testChannel, event.actions.join(contains: configuration.uuid) {
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

    var configuration = PubNubConfiguration(from: testsBundle)
    configuration.durationUntilTimeout = 11
    let client = PubNub(configuration: configuration)
    let testChannel = "testHereNow_MultiChannel_EmptyPresence"
    let otherChannel = "testHereNow_MultiChannel_EmptyPresence_Other"

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
}
