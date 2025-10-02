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
    let client = PubNub(configuration: presenceConfiguration())

    let performHereNow = {
      client.hereNow(on: [testChannel], includeState: true) { result in
        switch result {
        case let .success(response):
          XCTAssertNotNil(response.presenceByChannel[testChannel])
          XCTAssertGreaterThan(response.presenceByChannel.totalChannels, 0)
          XCTAssertGreaterThan(response.presenceByChannel.totalOccupancy, 0)
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
        case let .success(response):
          XCTAssertNotNil(response.presenceByChannel[testChannel])
          XCTAssertEqual(response.presenceByChannel[testChannel]?.occupantsState[client.configuration.userId]?.codableValue, ["StateKey": "StateValue"])
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
      case let .success(response):
        XCTAssertNotNil(response.presenceByChannel[testChannel])
        XCTAssertEqual(response.presenceByChannel.totalOccupancy, 0)
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
    let client = PubNub(configuration: presenceConfiguration())

    let performHereNow = {
      client.hereNow(on: [testChannel, otherChannel]) { result in
        switch result {
        case let .success(response):
          XCTAssertNotNil(response.presenceByChannel[testChannel])
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
        case let .success(response):
          XCTAssertNotNil(response.presenceByChannel[testChannel])
          XCTAssertEqual(response.presenceByChannel[testChannel]?.occupantsState[client.configuration.userId]?.codableValue, ["StateKey": "StateValue"])
          XCTAssertEqual(response.presenceByChannel[otherChannel]?.occupantsState[client.configuration.userId]?.codableValue, ["StateKey": "StateValue"])
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
      case let .success(response):
        XCTAssertTrue(response.presenceByChannel.isEmpty)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      hereNowExpect.fulfill()
    }

    wait(for: [hereNowExpect], timeout: 10.0)
  }

  func testHereNow_WithOffsetAndLimit() {
    let hereNowExpect = expectation(description: "Here Now Pagination Response")
    let testChannel = "testHereNow_WithPageAndLimit"
    
    let client = PubNub(configuration: presenceConfiguration())
    let anotherClient = PubNub(configuration: presenceConfiguration())
    let expectedUsers = Set([client.configuration.userId, anotherClient.configuration.userId])

    let performHereNow = {
      client.hereNow(on: [testChannel], includeState: true, limit: 1) { result in
        switch result {
        case let .success(firstResponse):
          XCTAssertEqual(firstResponse.presenceByChannel.totalChannels, 1)
          XCTAssertEqual(firstResponse.presenceByChannel.totalOccupancy, 2)
          client.hereNow(on: [testChannel], includeState: true, offset: firstResponse.nextOffset) { secondResult in
            switch secondResult {
            case let .success(secondResponse):
              XCTAssertEqual(secondResponse.presenceByChannel.totalChannels, 1)
              XCTAssertEqual(secondResponse.presenceByChannel.totalOccupancy, 2)
              let firstPageOccupants = firstResponse.presenceByChannel.values.map(\.occupants).flatMap { $0 }
              let secondPageOccupants = secondResponse.presenceByChannel.values.map(\.occupants).flatMap { $0 }
              XCTAssertEqual(expectedUsers, Set(firstPageOccupants + secondPageOccupants))
            case let .failure(error):
              XCTFail("Failed due to error: \(error)")
            }
            hereNowExpect.fulfill()
          }
        case let .failure(error):
          XCTFail("Failed due to error: \(error)")
        }
      }
    }
    
    let listener = waitOnPresence(
      client: client,
      channel: testChannel,
      userIds: expectedUsers,
      completion: performHereNow
    )

    client.subscribe(
      to: [testChannel],
      withPresence: true
    )
    anotherClient.subscribe(
      to: [testChannel],
      withPresence: true
    )

    defer { listener.cancel() }
    wait(for: [hereNowExpect], timeout: 125.0)
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

// MARK: - Presence Helper Methods

private extension PresenceEndpointIntegrationTests {
  func waitOnPresence(client: PubNub, channel: String, userIds: Set<String>? = nil, completion: @escaping () -> Void) -> SubscriptionListener {
    let listener = SubscriptionListener()
    let expectedUsers = userIds ?? Set([client.configuration.userId])
    var joinedUsers = Set<String>()
    var hasCompleted = false
    
    listener.didReceivePresence = { event in
      if event.channel == channel && !hasCompleted {
        // Extract user IDs from join actions
        for action in event.actions {
          if case let .join(uuids) = action {
            for userId in uuids {
              if expectedUsers.contains(userId) {
                joinedUsers.insert(userId)
              }
            }
          }
        }
        
        // Call completion when all expected users have joined
        if joinedUsers == expectedUsers {
          hasCompleted = true
          completion()
        }
      }
    }
    
    client.add(listener)
    // Return the listener to be able to cancel the subscription
    return listener
  }
}
