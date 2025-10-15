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

  func testHereNow_SingleChannel_Stateless() {
    let hereNowExpect = expectation(description: "Here Now Response")
    let testChannel = "testHereNow_SingleChannel_Statelesssss"
    let client = PubNub(configuration: presenceConfiguration())

    let performHereNow = {
      client.hereNow(on: [testChannel], includeState: true) { result in
        switch result {
        case let .success(presenceByChannel):
          XCTAssertNotNil(presenceByChannel[testChannel])
          XCTAssertGreaterThan(presenceByChannel.totalChannels, 0)
          XCTAssertGreaterThan(presenceByChannel.totalOccupancy, 0)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = waitOnPresence(
      client: client,
      channel: testChannel,
      completion: performHereNow
    )
    client.subscribe(
      to: [testChannel],
      withPresence: true
    )

    defer { listener.cancel() }
    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_SingleChannel_State() {
    let hereNowExpect = expectation(description: "Here Now Response")
    let setStateExpect = expectation(description: "Set State Response")
    let testChannel = "testHereNow_SingleChannel_State"
    let client = PubNub(configuration: presenceConfiguration())

    let performHereNow = { [unowned client] in
      client.hereNow(on: [testChannel], includeState: true) { result in
        switch result {
        case let .success(presenceByChannel):
          XCTAssertNotNil(presenceByChannel[testChannel])
          XCTAssertEqual(presenceByChannel[testChannel]?.occupantsState[client.configuration.userId]?.codableValue, ["StateKey": "StateValue"])
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

    let listener = waitOnPresence(
      client: client,
      channel: testChannel,
      completion: performSetState
    )
    client.subscribe(
      to: [testChannel],
      withPresence: true
    )

    defer { listener.cancel() }
    wait(for: [setStateExpect, hereNowExpect], timeout: 10.0)
  }

  func testHereNow_SingleChannel_EmptyPresence() {
    let hereNowExpect = expectation(description: "Here Now Response")
    let testChannel = "testHereNow_SingleChannel_EmptyPresence"
    let client = PubNub(configuration: presenceConfiguration())

    client.hereNow(on: [testChannel], includeState: true) { result in
      switch result {
      case let .success(presenceByChannel):
        XCTAssertNotNil(presenceByChannel[testChannel])
        XCTAssertEqual(presenceByChannel.totalOccupancy, 0)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      hereNowExpect.fulfill()
    }

    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_MultiChannel_Stateless() {
    let hereNowExpect = expectation(description: "Here Now Response")
    let testChannel = "testHereNow_MultiChannel_Stateless"
    let otherChannel = "testHereNow_MultiChannel_Stateless_Other"
    let client = PubNub(configuration: presenceConfiguration())

    let performHereNow = {
      client.hereNow(on: [testChannel, otherChannel]) { result in
        switch result {
        case let .success(presenceByChannel):
          XCTAssertNotNil(presenceByChannel[testChannel])
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = waitOnPresence(
      client: client,
      channel: testChannel, 
      completion: performHereNow
    )
    client.subscribe(
      to: [testChannel],
      withPresence: true
    )

    defer { listener.cancel() }
    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_MultiChannel_State() {
    let hereNowExpect = expectation(description: "Here Now Response")
    let setStateExpect = expectation(description: "Set State Response")
    let testChannel = "testHereNow_MultiChannel_State"
    let otherChannel = "testHereNow_MultiChannel_State_Other"
    let client = PubNub(configuration: presenceConfiguration())

    let performHereNow = {
      client.hereNow(on: [testChannel, otherChannel], includeState: true) { result in
        switch result {
        case let .success(presenceByChannel):
          XCTAssertNotNil(presenceByChannel[testChannel])
          XCTAssertEqual(presenceByChannel[testChannel]?.occupantsState[client.configuration.userId]?.codableValue, ["StateKey": "StateValue"])
          XCTAssertEqual(presenceByChannel[otherChannel]?.occupantsState[client.configuration.userId]?.codableValue, ["StateKey": "StateValue"])
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

    let listener = waitOnPresence(
      client: client,
      channel: testChannel,
      completion: performSetState
    )
    client.subscribe(
      to: [testChannel, otherChannel],
      withPresence: true
    )

    defer { listener.cancel() }
    wait(for: [setStateExpect, hereNowExpect], timeout: 10.0)
  }

  func testHereNow_MultiChannel_EmptyPresence() {
    let hereNowExpect = expectation(description: "Here Now Response")
    let testChannel = "testHereNow_MultiChannel_EmptyPresence"
    let otherChannel = "testHereNow_MultiChannel_EmptyPresence_Other"
    let client = PubNub(configuration: presenceConfiguration())

    client.hereNow(on: [testChannel, otherChannel], includeState: true) { result in
      switch result {
      case let .success(presenceByChannel):
        XCTAssertTrue(presenceByChannel.isEmpty)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      hereNowExpect.fulfill()
    }

    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_MultiChannel_Limit() {
    let hereNowExpect = expectation(description: "Here Now Limit Response")
    let testChannel = "testHereNow_Limit"

    // Create 4 clients
    let clientA = PubNub(configuration: presenceConfiguration())
    let clientB = PubNub(configuration: presenceConfiguration())
    let clientC = PubNub(configuration: presenceConfiguration())
    let clientD = PubNub(configuration: presenceConfiguration())

    // Expected users to join the channel
    let expectedUsers = Set([
      clientA.configuration.userId, 
      clientB.configuration.userId,
      clientC.configuration.userId, 
      clientD.configuration.userId
    ])

    let performHereNow = {
      clientA.hereNow(on: [testChannel], limit: 2) { result in
        switch result {
        case let .success(response):
          XCTAssertEqual((response[testChannel]?.occupants ?? []).count, 2)
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
        hereNowExpect.fulfill()
      }
    }

    let listener = waitOnPresence(
      client: clientA,
      channel: testChannel,
      userIds: expectedUsers,
      completion: performHereNow
    )
    
    clientA.subscribe(to: [testChannel], withPresence: true)
    clientB.subscribe(to: [testChannel], withPresence: true)
    clientC.subscribe(to: [testChannel], withPresence: true)
    clientD.subscribe(to: [testChannel], withPresence: true)

    defer { listener.cancel() }
    wait(for: [hereNowExpect], timeout: 30.0)
  }

  func testWhereNow() {
    let whereNowExpect = expectation(description: "Where Now Response")
    let testChannel1 = "testWhereNowChannel1"
    let testChannel2 = "testWhereNowChannel2"
    let client = PubNub(configuration: presenceConfiguration())

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
    
    let listener = waitOnPresence(
      client: client, 
      channel: testChannel2, 
      completion: performWhereNow
    )
    client.subscribe(
      to: [testChannel1, testChannel2],
      withPresence: true
    )
    
    defer { listener.cancel() }
    wait(for: [whereNowExpect], timeout: 10.0)
  }
}

// MARK: - Presence Helper Methods

private extension PresenceEndpointIntegrationTests {
  func presenceConfiguration(userId: String = randomString()) -> PubNubConfiguration {
    PubNubConfiguration(
      publishKey: PubNubConfiguration(from: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(from: testsBundle).subscribeKey,
      userId: randomString(),
      durationUntilTimeout: 11
    )
  }
}

private extension PresenceEndpointIntegrationTests {
  func waitOnPresence(client: PubNub, channel: String, userIds: Set<String>? = nil, completion: @escaping () -> Void) -> SubscriptionListener {
    let listener = SubscriptionListener()
    let expectedUsers = userIds ?? Set([client.configuration.userId])
    var joinedUsers: Set<String> = Set<String>()
    var hasCompleted = false

    listener.didReceivePresence = { event in
      guard !hasCompleted, event.channel == channel else {
        return
      }
      
      for action in event.actions {
        if case let .join(uuids) = action {
          joinedUsers.formUnion(uuids.filter { expectedUsers.contains($0) })
        }
      }

      // Check if all expected users have joined the channel
      if joinedUsers == expectedUsers {
        hasCompleted = true
        completion()
      }
    }

    // Add listener to client
    client.add(listener)
    
    // Return listener to be able to cancel it when the test is done
    return listener
  }
}
