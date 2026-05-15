//
//  PresenceRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class PresenceRouterTests: XCTestCase {
  let config = TestPubNubFactory.makeConfig()

  let channelName = "TestChannel"
  let otherChannel = "OtherTestChannel"
}

// MARK: - HereNow Tests

extension PresenceRouterTests {
  func test_HereNowRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = PresenceRouter(
      .hereNow(channels: [channelName], groups: [], includeUUIDs: true, includeState: true, limit: 1000, offset: 0),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Here Now")
    XCTAssertEqual(router.category, "Here Now")
    XCTAssertEqual(router.service, .presence)
  }

  func test_HereNow_WhenChannelsAndGroupsEmpty_ReturnsValidationError() {
    let router = PresenceRouter(
      .hereNow(channels: [], groups: [], includeUUIDs: true, includeState: true, limit: 1000, offset: 0),
      configuration: config
    )

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.missingChannelsAnyGroups
    )
  }

  func test_HereNowRouter_WithChannels_ReturnsExpectedChannels() {
    let router = PresenceRouter(
      .hereNow(channels: [channelName], groups: [], includeUUIDs: true, includeState: true, limit: 1000, offset: 0),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.channels, [channelName])
  }

  func test_HereNowRouter_WithGroups_ReturnsExpectedGroups() {
    let router = PresenceRouter(
      .hereNow(channels: [], groups: [channelName], includeUUIDs: true, includeState: true, limit: 1000, offset: 0),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.groups, [channelName])
  }

  // Single Channel
  func test_HereNow_WithSingleChannel_ReturnsOccupancy() throws {
    let expectation = self.expectation(description: "HereNow Response Received")

    let sessions = try MockURLSession.mockSession(for: ["herenow_singleChannel_success"])

    let testChannel = channelName
    let presence = PubNubPresenceBase(channel: testChannel, occupancy: 1, occupants: ["pn-12"], occupantsState: [:])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.hereNow(on: [testChannel]) { result in
      switch result {
      case let .success(presenceByChannel):
        XCTAssertEqual(presenceByChannel.compactMapValues { try? $0.transcode() }, [testChannel: presence])
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_HereNow_WithSingleChannelStateful_ReturnsOccupantsState() throws {
    let expectation = self.expectation(description: "HereNow Response Received")

    let sessions = try MockURLSession.mockSession(for: ["herenow_singleChannel_success_stateful"])

    let testChannel = channelName
    let presence = PubNubPresenceBase(
      channel: testChannel, occupancy: 1, occupants: ["pn-12"],
      occupantsState: ["pn-12": ["SubKey": "SubValue"]]
    )

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.hereNow(on: [testChannel], includeUUIDs: true, includeState: true) { result in
      switch result {
      case let .success(presenceByChannel):
        XCTAssertEqual(presenceByChannel.compactMapValues { try? $0.transcode() }, [testChannel: presence])
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_HereNow_WithSingleChannelNoOccupants_ReturnsEmptyPresence() throws {
    let expectation = self.expectation(description: "HereNow Response Received")

    let sessions = try MockURLSession.mockSession(for: ["herenow_singleChannel_success_empty"])

    let testChannel = channelName
    let presence = PubNubPresenceBase(
      channel: testChannel, occupancy: 0, occupants: [], occupantsState: [:]
    )

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.hereNow(on: [testChannel], includeUUIDs: true, includeState: true) { result in
      switch result {
      case let .success(presenceByChannel):
        XCTAssertEqual(presenceByChannel.compactMapValues { try? $0.transcode() }, [testChannel: presence])
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // Multi Channel

  func test_HereNow_WithMultipleChannels_ReturnsPresenceByChannel() throws {
    let expectation = self.expectation(description: "HereNow Response Received")

    let sessions = try MockURLSession.mockSession(for: ["herenow_success"])

    let presence = PubNubPresenceBase(channel: "TestChannel", occupancy: 1, occupants: ["pn-12"], occupantsState: [:])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.hereNow(on: [channelName, otherChannel], includeUUIDs: true, includeState: true) { result in
      switch result {
      case let .success(presenceByChannel):
        XCTAssertEqual(presenceByChannel.compactMapValues { try? $0.transcode() }, ["TestChannel": presence])
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_HereNow_WithMultipleChannelsStateful_ReturnsPresenceWithState() throws {
    let expectation = self.expectation(description: "HereNow Response Received")

    let sessions = try MockURLSession.mockSession(for: ["herenow_success_stateful"])

    let presence = PubNubPresenceBase(
      channel: "TestChannel", occupancy: 1,
      occupants: ["pn-12"], occupantsState: ["pn-12": ["SubKey": "SubValue"]]
    )

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.hereNow(on: [channelName, otherChannel], includeUUIDs: true, includeState: true) { result in
      switch result {
      case let .success(presenceByChannel):
        XCTAssertEqual(presenceByChannel.compactMapValues { try? $0.transcode() }, ["TestChannel": presence])
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_HereNow_WithMultipleChannelsEmpty_ReturnsEmptyPresence() throws {
    let expectation = self.expectation(description: "HereNow Response Received")

    let sessions = try MockURLSession.mockSession(for: ["herenow_success_empty"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.hereNow(on: [channelName, otherChannel], includeUUIDs: true, includeState: true) { result in
      switch result {
      case let .success(presenceByChannel):
        XCTAssertTrue(presenceByChannel.isEmpty)
        XCTAssertEqual(presenceByChannel.totalChannels, 0)
        XCTAssertEqual(presenceByChannel.totalOccupancy, 0)
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_HereNow_WithUUIDsDisabled_ReturnsOccupancyWithoutUUIDs() throws {
    let expectation = self.expectation(description: "HereNow Response Received")

    let sessions = try MockURLSession.mockSession(for: ["herenow_success_disableUUID"])

    let channelName = "TestChannel"

    let presence = PubNubPresenceBase(
      channel: "TestChannel", occupancy: 2,
      occupants: [], occupantsState: [:]
    )

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.hereNow(on: [channelName, otherChannel], includeUUIDs: false, includeState: true) { result in
      switch result {
      case let .success(presenceByChannel):
        XCTAssertEqual(presenceByChannel.compactMapValues { try? $0.transcode() }, ["TestChannel": presence])
        XCTAssertEqual(presenceByChannel.totalChannels, 1)
        XCTAssertEqual(presenceByChannel.totalOccupancy, 2)
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Global HereNow Tests

extension PresenceRouterTests {
  func test_HereNowGlobalRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = PresenceRouter(.hereNowGlobal(includeUUIDs: true, includeState: true), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Global Here Now")
    XCTAssertEqual(router.category, "Global Here Now")
    XCTAssertEqual(router.service, .presence)
  }

  func test_HereNowGlobal_WithValidConfig_ReturnsNoValidationError() {
    let router = PresenceRouter(.hereNowGlobal(includeUUIDs: true, includeState: true), configuration: config)
    XCTAssertNil(router.validationError)
  }

  func test_HereNowGlobalRouter_WithNoChannels_ReturnsEmptyChannels() {
    let router = PresenceRouter(.hereNowGlobal(includeUUIDs: true, includeState: true), configuration: config)
    XCTAssertEqual(router.endpoint.channels, [])
  }

  func test_HereNowGlobalRouter_WithNoGroups_ReturnsEmptyGroups() {
    let router = PresenceRouter(.hereNowGlobal(includeUUIDs: true, includeState: true), configuration: config)
    XCTAssertEqual(router.endpoint.groups, [])
  }

  func test_HereNowGlobal_WithNoChannels_ReturnsGlobalPresence() throws {
    let expectation = self.expectation(description: "HereNowGlobal Response Received")

    let sessions = try MockURLSession.mockSession(for: ["herenow_success"])

    let presence = PubNubPresenceBase(
      channel: "TestChannel", occupancy: 1,
      occupants: ["pn-12"], occupantsState: [:]
    )

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.hereNow(on: [], includeUUIDs: true, includeState: true) { result in
      switch result {
      case let .success(presenceByChannel):
        XCTAssertEqual(presenceByChannel.compactMapValues { try? $0.transcode() }, ["TestChannel": presence])
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - WhereNow Tests

extension PresenceRouterTests {
  func test_WhereNowRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = PresenceRouter(.whereNow(uuid: "Something"), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Where Now")
    XCTAssertEqual(router.category, "Where Now")
    XCTAssertEqual(router.service, .presence)
  }

  func test_WhereNow_WhenUUIDEmpty_ReturnsValidationError() {
    let router = PresenceRouter(.whereNow(uuid: ""), configuration: config)

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.emptyUUIDString
    )
  }

  func test_WhereNowRouter_WithValidUUID_ReturnsEmptyChannels() {
    let router = PresenceRouter(.whereNow(uuid: "Something"), configuration: config)
    XCTAssertEqual(router.endpoint.channels, [])
  }

  func test_WhereNowRouter_WithValidUUID_ReturnsEmptyGroups() {
    let router = PresenceRouter(.whereNow(uuid: "Something"), configuration: config)
    XCTAssertEqual(router.endpoint.groups, [])
  }

  func test_WhereNow_WithUserNoChannels_ReturnsEmptyChannels() throws {
    let expectation = self.expectation(description: "WhereNow Response Received")

    let sessions = try MockURLSession.mockSession(for: ["wherenow_success_empty"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.whereNow(for: "testUser") { result in
      switch result {
      case let .success(channelsByGroupId):
        XCTAssertTrue(channelsByGroupId["testUser"]?.isEmpty ?? false)
      case let .failure(error):
        XCTFail("Where Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_WhereNow_WithActiveUser_ReturnsChannels() throws {
    let expectation = self.expectation(description: "WhereNow Response Received")

    let sessions = try MockURLSession.mockSession(for: ["wherenow_success"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)
    pubnub.whereNow(for: "testUser") { result in
      switch result {
      case let .success(channels):
        XCTAssertEqual(channels.count, 1)
      case let .failure(error):
        XCTFail("Where Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Heartbeat Tests

extension PresenceRouterTests {
  func test_HeartbeatRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = PresenceRouter(
      .heartbeat(
        channels: [channelName], groups: [],
        channelStates: [:], presenceTimeout: nil
      ), configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Heartbeat")
    XCTAssertEqual(router.category, "Heartbeat")
    XCTAssertEqual(router.service, .presence)
  }

  func test_Heartbeat_WhenChannelsAndGroupsEmpty_ReturnsValidationError() {
    let router = PresenceRouter(
      .heartbeat(
        channels: [], groups: [],
        channelStates: [:], presenceTimeout: nil
      ), configuration: config
    )

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.missingChannelsAnyGroups
    )
  }

  func test_HeartbeatRouter_WithChannels_ReturnsExpectedChannels() {
    let router = PresenceRouter(
      .heartbeat(
        channels: [channelName],
        groups: [],
        channelStates: [:],
        presenceTimeout: nil
      ), configuration: config
    )

    XCTAssertEqual(router.endpoint.channels, [channelName])
  }

  func test_HeartbeatRouter_WithGroups_ReturnsExpectedGroups() {
    let router = PresenceRouter(
      .heartbeat(
        channels: [],
        groups: [channelName],
        channelStates: [:],
        presenceTimeout: nil
      ), configuration: config
    )

    XCTAssertEqual(router.endpoint.groups, [channelName])
  }

  func test_Heartbeat_WithEventEngineEnabled_IncludesStateAndEEParams() throws {
    let stateContainer = PubNubPresenceStateContainer()
    stateContainer.registerState(["x": 1], forChannels: ["c1"])
    stateContainer.registerState(["a": "someText"], forChannels: ["c2"])

    let endpoint = PresenceRouter.Endpoint.heartbeat(
      channels: ["c1", "c2"],
      groups: ["group-1", "group-2"],
      channelStates: stateContainer.getStates(forChannels: ["c1", "c2"]),
      presenceTimeout: 30
    )
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "someId",
      enableEventEngine: true,
      maintainPresenceState: true
    )
    let router = PresenceRouter(
      endpoint,
      configuration: config
    )

    let queryItems = try router.queryItems.get()

    // There's no guaranteed order of returned states.
    // Therefore, these are two possible and valid combinations:
    let expStateValues = [
      "{\"c1\":{\"x\":1},\"c2\":{\"a\":\"someText\"}}",
      "{\"c2\":{\"a\":\"someText\"},\"c1\":{\"x\":1}}"
    ]

    XCTAssertTrue(queryItems.count == 6)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value?.contains("group-1,group-2") == true })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value == "30" })
    XCTAssertTrue(queryItems.contains { $0.name == "ee" && $0.value == nil })
    XCTAssertTrue(queryItems.contains { $0.name == "state" && $0.value.map { expStateValues.contains($0) } == true })
  }

  func test_Heartbeat_WithEventEngineDisabled_ExcludesStateAndEEParams() throws {
    let stateContainer = PubNubPresenceStateContainer()
    stateContainer.registerState(["x": 1], forChannels: ["c1"])
    stateContainer.registerState(["a": "someText"], forChannels: ["c2"])

    let endpoint = PresenceRouter.Endpoint.heartbeat(
      channels: ["c1", "c2"],
      groups: ["group-1", "group-2"],
      channelStates: stateContainer.getStates(forChannels: ["c1", "c2"]),
      presenceTimeout: 30
    )
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "someId",
      enableEventEngine: false,
      maintainPresenceState: true
    )

    let router = PresenceRouter(
      endpoint,
      configuration: config
    )
    let queryItems = try router.queryItems.get()

    XCTAssertTrue(queryItems.count == 4)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value?.contains("group-1,group-2") == true })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value == "30" })
  }

  func test_Heartbeat_WithMaintainPresenceStateDisabled_ExcludesStateParam() throws {
    let stateContainer = PubNubPresenceStateContainer()
    stateContainer.registerState(["x": 1], forChannels: ["c1"])
    stateContainer.registerState(["a": "someText"], forChannels: ["c2"])

    let endpoint = PresenceRouter.Endpoint.heartbeat(
      channels: ["c1", "c2"],
      groups: ["group-1", "group-2"],
      channelStates: stateContainer.getStates(forChannels: ["c1", "c2"]),
      presenceTimeout: 30
    )
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "someId",
      enableEventEngine: true,
      maintainPresenceState: false
    )
    let router = PresenceRouter(
      endpoint,
      configuration: config
    )
    let queryItems = try router.queryItems.get()

    XCTAssertTrue(queryItems.count == 5)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value?.contains("group-1,group-2") == true })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value == "30" })
    XCTAssertTrue(queryItems.contains { $0.name == "ee" && $0.value == nil })
  }

  func test_Heartbeat_WithEmptyPresenceStates_ExcludesStateParam() throws {
    let endpoint = PresenceRouter.Endpoint.heartbeat(
      channels: ["c1", "c2"],
      groups: ["group-1", "group-2"],
      channelStates: [:],
      presenceTimeout: 30
    )
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "someId",
      enableEventEngine: true,
      maintainPresenceState: true
    )
    let router = PresenceRouter(
      endpoint,
      configuration: config
    )
    let queryItems = try router.queryItems.get()

    XCTAssertTrue(queryItems.count == 5)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value?.contains("group-1,group-2") == true })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value == "30" })
    XCTAssertTrue(queryItems.contains { $0.name == "ee" && $0.value == nil })
  }
}

// MARK: - Leave Tests

extension PresenceRouterTests {
  func test_LeaveRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = PresenceRouter(.leave(channels: [channelName], groups: []), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Leave")
    XCTAssertEqual(router.category, "Leave")
    XCTAssertEqual(router.service, .presence)
  }

  func test_Leave_WhenChannelsAndGroupsEmpty_ReturnsValidationError() {
    let router = PresenceRouter(.leave(channels: [], groups: []), configuration: config)

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.missingChannelsAnyGroups
    )
  }

  func test_LeaveRouter_WithChannels_ReturnsExpectedChannels() {
    let router = PresenceRouter(.leave(channels: [channelName], groups: []), configuration: config)
    XCTAssertEqual(router.endpoint.channels, [channelName])
  }

  func test_LeaveRouter_WithGroups_ReturnsExpectedGroups() {
    let router = PresenceRouter(.leave(channels: [], groups: [channelName]), configuration: config)
    XCTAssertEqual(router.endpoint.groups, [channelName])
  }
}

// MARK: - Get State Tests

extension PresenceRouterTests {
  func test_GetStateRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = PresenceRouter(.getState(uuid: "TestUUID", channels: [channelName], groups: []), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Get Presence State")
    XCTAssertEqual(router.category, "Get Presence State")
    XCTAssertEqual(router.service, .presence)
  }

  func test_GetState_WhenUUIDOrChannelsInvalid_ReturnsValidationError() {
    let router = PresenceRouter(.getState(uuid: "", channels: [channelName], groups: []), configuration: config)
    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.emptyUUIDString
    )

    let missingChannelsGroups = PresenceRouter(
      .getState(uuid: "TestUUID", channels: [], groups: []),
      configuration: config
    )
    XCTAssertEqual(
      missingChannelsGroups.validationError?.pubNubError?.details.first,
      ErrorDescription.missingChannelsAnyGroups
    )
  }

  func test_GetStateRouter_WithChannels_ReturnsExpectedChannels() {
    let router = PresenceRouter(.getState(uuid: "TestUUID", channels: [channelName], groups: []), configuration: config)
    XCTAssertEqual(router.endpoint.channels, [channelName])
  }

  func test_GetStateRouter_WithGroups_ReturnsExpectedGroups() {
    let router = PresenceRouter(.getState(uuid: "TestUUID", channels: [], groups: [channelName]), configuration: config)
    XCTAssertEqual(router.endpoint.groups, [channelName])
  }
}

// MARK: - Set State Tests

extension PresenceRouterTests {
  func test_SetStateRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = PresenceRouter(.setState(channels: [channelName], groups: [], state: [:]), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Set Presence State")
    XCTAssertEqual(router.category, "Set Presence State")
    XCTAssertEqual(router.service, .presence)
  }

  func test_SetState_WhenChannelsAndGroupsEmpty_ReturnsValidationError() {
    let router = PresenceRouter(.setState(channels: [], groups: [], state: [:]), configuration: config)

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.missingChannelsAnyGroups
    )
  }

  func test_SetStateRouter_WithChannels_ReturnsExpectedChannels() {
    let router = PresenceRouter(.setState(channels: [channelName], groups: [], state: [:]), configuration: config)
    XCTAssertEqual(router.endpoint.channels, [channelName])
  }

  func test_SetStateRouter_WithGroups_ReturnsExpectedGroups() {
    let router = PresenceRouter(.setState(channels: [], groups: [channelName], state: [:]), configuration: config)
    XCTAssertEqual(router.endpoint.groups, [channelName])
  }
}
