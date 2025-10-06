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

  func testHereNow_MultiChannel_OffsetAndLimit() {
    let hereNowExpect = expectation(description: "Here Now Pagination Response")
    let lobbyChannel = "lobby"
    let generalChannel = "general"
    let vipChannel = "vip"

    // Create 5 clients
    let clientA = PubNub(configuration: presenceConfiguration())
    let clientB = PubNub(configuration: presenceConfiguration())
    let clientC = PubNub(configuration: presenceConfiguration())
    let clientD = PubNub(configuration: presenceConfiguration())

    // Expected users per channel
    let lobbyUsers = Set([clientA.configuration.userId, clientB.configuration.userId, clientC.configuration.userId, clientD.configuration.userId])
    let generalUsers = Set([clientA.configuration.userId, clientB.configuration.userId, clientC.configuration.userId])
    let vipUsers = Set([clientA.configuration.userId, clientB.configuration.userId])

    let performHereNow = {
      clientA.hereNow(on: [lobbyChannel, generalChannel, vipChannel], limit: 2) { [unowned clientA] result in
        switch result {
        case let .success(firstPage):
          // Verify total channels matches the number of channels and total occupancy matches the number of users
          XCTAssertEqual(firstPage.presenceByChannel.totalChannels, 3)
          XCTAssertEqual(firstPage.presenceByChannel.totalOccupancy, 9)
          
          // Verify occupancy for each provided channel
          XCTAssertEqual(firstPage.presenceByChannel[lobbyChannel]?.occupancy, 4)
          XCTAssertEqual(firstPage.presenceByChannel[generalChannel]?.occupancy, 3)
          XCTAssertEqual(firstPage.presenceByChannel[vipChannel]?.occupancy, 2)

          let firstPageLobby = firstPage.presenceByChannel[lobbyChannel]?.occupants ?? []
          let firstPageGeneral = firstPage.presenceByChannel[generalChannel]?.occupants ?? []
          let firstPageVip = firstPage.presenceByChannel[vipChannel]?.occupants ?? []

          // Verify channel occupants don't exceed the limit
          XCTAssertEqual(firstPageLobby.count, 2)
          XCTAssertEqual(firstPageGeneral.count, 2)
          XCTAssertEqual(firstPageVip.count, 2)

          // Fetch second page using offset
          clientA.hereNow(on: [lobbyChannel, generalChannel, vipChannel], offset: firstPage.nextOffset) { secondResult in
            switch secondResult {
            case let .success(secondPage):
              let secondPageLobby = secondPage.presenceByChannel[lobbyChannel]?.occupants ?? []
              let secondPageGeneral = secondPage.presenceByChannel[generalChannel]?.occupants ?? []
              let secondPageVip = secondPage.presenceByChannel[vipChannel]?.occupants ?? []

              // Verify pagination - lobby channel should have 2 more users (4 total)
              let allLobbyUsers = Set(firstPageLobby + secondPageLobby)
              XCTAssertEqual(secondPageLobby.count, 2)
              XCTAssertEqual(allLobbyUsers, lobbyUsers)

              // Verify pagination - general channel should have 1 more user (3 total)
              let allGeneralUsers = Set(firstPageGeneral + secondPageGeneral)
              XCTAssertEqual(secondPageGeneral.count, 1)
              XCTAssertEqual(allGeneralUsers, generalUsers)

              // Verify pagination - vip channel should have 0 more users (2 total from first page)
              let allVipUsers = Set(firstPageVip + secondPageVip)
              XCTAssertEqual(secondPageVip.count, 0)
              XCTAssertEqual(allVipUsers, vipUsers)

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

    let listener = waitOnMultiChannelPresence(
      client: clientA,
      channelUsers: [lobbyChannel: lobbyUsers, generalChannel: generalUsers, vipChannel: vipUsers],
      completion: performHereNow
    )
    
    clientA.subscribe(to: [lobbyChannel, generalChannel, vipChannel], withPresence: true)
    clientB.subscribe(to: [lobbyChannel, generalChannel, vipChannel], withPresence: true)
    clientC.subscribe(to: [lobbyChannel, generalChannel], withPresence: true)
    clientD.subscribe(to: [lobbyChannel], withPresence: true)

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
  func waitOnMultiChannelPresence(
    client: PubNub,
    channelUsers: [String: Set<String>],
    completion: @escaping () -> Void
  ) -> SubscriptionListener {
    let listener = SubscriptionListener()
    var joinedUsersByChannel: [String: Set<String>] = channelUsers.mapValues { _ in Set<String>() }
    var hasCompleted = false

    listener.didReceivePresence = { event in
      guard !hasCompleted, let expectedUsers = channelUsers[event.channel] else {
        return
      }
      
      for action in event.actions {
        if case let .join(uuids) = action {
          joinedUsersByChannel[event.channel]?.formUnion(uuids.filter { expectedUsers.contains($0) })
        }
      }

      // Check if all expected users have joined all channels
      let allJoined = channelUsers.allSatisfy { channel, expectedUsers in
        joinedUsersByChannel[channel] == expectedUsers
      }

      if allJoined {
        hasCompleted = true
        completion()
      }
    }

    // Add listener to client
    client.add(listener)
    
    // Return listener to be able to cancel it when the test is done
    return listener
  }

  func waitOnPresence(client: PubNub, channel: String, userIds: Set<String>? = nil, completion: @escaping () -> Void) -> SubscriptionListener {
    waitOnMultiChannelPresence(
      client: client,
      channelUsers: [channel: userIds ?? Set([client.configuration.userId])],
      completion: completion
    )
  }
}
