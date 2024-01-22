//
//  PresenceRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class PresenceRouterTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString", userId: UUID().uuidString)

  let channelName = "TestChannel"
  let otherChannel = "OtherTestChannel"
}

// MARK: - HereNow Tests

extension PresenceRouterTests {
  func testHereNow_Router() {
    let router = PresenceRouter(
      .hereNow(channels: [channelName], groups: [], includeUUIDs: true, includeState: true),
      configuration: config
    )
    
    XCTAssertEqual(router.endpoint.description, "Here Now")
    XCTAssertEqual(router.category, "Here Now")
    XCTAssertEqual(router.service, .presence)
  }

  func testHereNow_Router_ValidationError() {
    let router = PresenceRouter(
      .hereNow(channels: [], groups: [], includeUUIDs: true, includeState: true),
      configuration: config
    )
    
    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.missingChannelsAnyGroups
    )
  }

  func testHereNow_Router_Channels() {
    let router = PresenceRouter(
      .hereNow(channels: [channelName], groups: [], includeUUIDs: true, includeState: true),
      configuration: config
    )
    
    XCTAssertEqual(router.endpoint.channels, [channelName])
  }

  func testHereNow_Router_Groups() {
    let router = PresenceRouter(
      .hereNow(channels: [], groups: [channelName], includeUUIDs: true, includeState: true),
      configuration: config
    )
    
    XCTAssertEqual(router.endpoint.groups, [channelName])
  }

  // Single Channel
  func testHereNow_Success_SingleChannel() {
    let expectation = self.expectation(description: "HereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["herenow_singleChannel_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let testChannel = channelName
    let presence = PubNubPresenceBase(channel: testChannel, occupancy: 1, occupants: ["pn-12"], occupantsState: [:])

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.hereNow(on: [testChannel]) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.compactMapValues { try? $0.transcode() }, [testChannel: presence])
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testHereNow_Success_SingleChannel_Stateful() {
    let expectation = self.expectation(description: "HereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["herenow_singleChannel_success_stateful"]) else {
      return XCTFail("Could not create mock url session")
    }

    let testChannel = channelName
    let presence = PubNubPresenceBase(
      channel: testChannel, occupancy: 1, occupants: ["pn-12"],
      occupantsState: ["pn-12": ["SubKey": "SubValue"]]
    )

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.hereNow(on: [testChannel], includeUUIDs: true, includeState: true) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.compactMapValues { try? $0.transcode() }, [testChannel: presence])
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testHereNow_Success_SingleChannel_EmptyPresence() {
    let expectation = self.expectation(description: "HereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["herenow_singleChannel_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    let testChannel = channelName
    let presence = PubNubPresenceBase(
      channel: testChannel, occupancy: 0, occupants: [], occupantsState: [:]
    )

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.hereNow(on: [testChannel], includeUUIDs: true, includeState: true) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.compactMapValues { try? $0.transcode() }, [testChannel: presence])
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // Multi Channel

  func testHereNow_Success() {
    let expectation = self.expectation(description: "HereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["herenow_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let presence = PubNubPresenceBase(channel: "TestChannel", occupancy: 1, occupants: ["pn-12"], occupantsState: [:])

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.hereNow(on: [channelName, otherChannel], includeUUIDs: true, includeState: true) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.compactMapValues { try? $0.transcode() }, ["TestChannel": presence])
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testHereNow_Success_Stateful() {
    let expectation = self.expectation(description: "HereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["herenow_success_stateful"]) else {
      return XCTFail("Could not create mock url session")
    }

    let presence = PubNubPresenceBase(
      channel: "TestChannel", occupancy: 1,
      occupants: ["pn-12"], occupantsState: ["pn-12": ["SubKey": "SubValue"]]
    )

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.hereNow(on: [channelName, otherChannel], includeUUIDs: true, includeState: true) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.compactMapValues { try? $0.transcode() }, ["TestChannel": presence])
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testHereNow_Success_EmptyPresence() {
    let expectation = self.expectation(description: "HereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["herenow_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.hereNow(on: [channelName, otherChannel], includeUUIDs: true, includeState: true) { result in
      switch result {
      case let .success(payload):
        XCTAssertTrue(payload.isEmpty)
        XCTAssertEqual(payload.totalChannels, 0)
        XCTAssertEqual(payload.totalOccupancy, 0)
      case let .failure(error):
        XCTFail("Here Now request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testHereNow_Success_DisableUUID() {
    let expectation = self.expectation(description: "HereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["herenow_success_disableUUID"]) else {
      return XCTFail("Could not create mock url session")
    }

    let channelName = "TestChannel"

    let presence = PubNubPresenceBase(
      channel: "TestChannel", occupancy: 2,
      occupants: [], occupantsState: [:]
    )

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.hereNow(on: [channelName, otherChannel], includeUUIDs: false, includeState: true) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.compactMapValues { try? $0.transcode() }, ["TestChannel": presence])
        XCTAssertEqual(payload.totalChannels, 1)
        XCTAssertEqual(payload.totalOccupancy, 2)
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
  func testHereNowGlobal_Router() {
    let router = PresenceRouter(.hereNowGlobal(includeUUIDs: true, includeState: true), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Global Here Now")
    XCTAssertEqual(router.category, "Global Here Now")
    XCTAssertEqual(router.service, .presence)
  }

  func testHereNowGlobal_Router_ValidationError() {
    let router = PresenceRouter(.hereNowGlobal(includeUUIDs: true, includeState: true), configuration: config)
    XCTAssertNil(router.validationError)
  }

  func testHereNowGlobal_Router_Channels() {
    let router = PresenceRouter(.hereNowGlobal(includeUUIDs: true, includeState: true), configuration: config)
    XCTAssertEqual(router.endpoint.channels, [])
  }

  func testHereNowGlobal_Router_Groups() {
    let router = PresenceRouter(.hereNowGlobal(includeUUIDs: true, includeState: true), configuration: config)
    XCTAssertEqual(router.endpoint.groups, [])
  }

  func testHereNowGlobal_Success() {
    let expectation = self.expectation(description: "HereNowGlobal Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["herenow_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let presence = PubNubPresenceBase(
      channel: "TestChannel", occupancy: 1,
      occupants: ["pn-12"], occupantsState: [:]
    )

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.hereNow(on: [], includeUUIDs: true, includeState: true) { result in
      switch result {
      case let .success(payload):
        XCTAssertEqual(payload.compactMapValues { try? $0.transcode() }, ["TestChannel": presence])
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
  func testWhereNow_Router() {
    let router = PresenceRouter(.whereNow(uuid: "Something"), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Where Now")
    XCTAssertEqual(router.category, "Where Now")
    XCTAssertEqual(router.service, .presence)
  }

  func testWhereNow_Router_ValidationError() {
    let router = PresenceRouter(.whereNow(uuid: ""), configuration: config)

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.emptyUUIDString
    )
  }

  func testWhereNow_Router_Channels() {
    let router = PresenceRouter(.whereNow(uuid: "Something"), configuration: config)
    XCTAssertEqual(router.endpoint.channels, [])
  }

  func testWhereNow_Router_Groups() {
    let router = PresenceRouter(.whereNow(uuid: "Something"), configuration: config)
    XCTAssertEqual(router.endpoint.groups, [])
  }

  func testWhereNow_Success_EmptyClasses() {
    let expectation = self.expectation(description: "WhereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["wherenow_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testWhereNow_Success() {
    let expectation = self.expectation(description: "WhereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["wherenow_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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
  func testHeartbeat_Router() {
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

  func testHeartbeat_Router_ValidationError() {
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

  func testHeartbeat_Router_Channels() {
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

  func testHeartbeat_Router_Groups() {
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
  
  func testHeartbeat_QueryParamsWithEventEngineEnabled() {
    let stateContainer = PubNubPresenceStateContainer.shared
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
    
    let queryItems = (try? router.queryItems.get()) ?? []
    
    // There's no guaranteed order of returned states.
    // Therefore, these are two possible and valid combinations:
    let expStateValues = [
      "{\"c1\":{\"x\":1},\"c2\":{\"a\":\"someText\"}}",
      "{\"c2\":{\"a\":\"someText\"},\"c1\":{\"x\":1}}"
    ]
    
    XCTAssertTrue(queryItems.count == 6)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value!.contains("group-1,group-2") })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value! == "30" })
    XCTAssertTrue(queryItems.contains { $0.name == "ee" && $0.value == nil })
    XCTAssertTrue(queryItems.contains { $0.name == "state" && expStateValues.contains($0.value!) })
  }
  
  func testHeartbeat_QueryParamsWithEventEngineDisabled() {
    let stateContainer = PubNubPresenceStateContainer.shared
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
    let queryItems = (try? router.queryItems.get()) ?? []

    XCTAssertTrue(queryItems.count == 4)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value!.contains("group-1,group-2") })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value! == "30" })
  }
  
  func testHeartbeat_QueryParamsWithMaintainPresenceStateDisabled() {
    let stateContainer = PubNubPresenceStateContainer.shared
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
    let queryItems = (try? router.queryItems.get()) ?? []

    XCTAssertTrue(queryItems.count == 5)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value!.contains("group-1,group-2") })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value! == "30" })
    XCTAssertTrue(queryItems.contains { $0.name == "ee" && $0.value == nil })
  }
  
  func testHeartbeat_QueryParamsWithEmptyPresenceStates() {
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
    let queryItems = (try? router.queryItems.get()) ?? []
    
    XCTAssertTrue(queryItems.count == 5)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value!.contains("group-1,group-2") })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value! == "30" })
    XCTAssertTrue(queryItems.contains { $0.name == "ee" && $0.value == nil })
  }
}

// MARK: - Leave Tests

extension PresenceRouterTests {
  func testLeave_Router() {
    let router = PresenceRouter(.leave(channels: [channelName], groups: []), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Leave")
    XCTAssertEqual(router.category, "Leave")
    XCTAssertEqual(router.service, .presence)
  }

  func testLeave_Router_ValidationError() {
    let router = PresenceRouter(.leave(channels: [], groups: []), configuration: config)

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.missingChannelsAnyGroups
    )
  }

  func testLeave_Router_Channels() {
    let router = PresenceRouter(.leave(channels: [channelName], groups: []), configuration: config)
    XCTAssertEqual(router.endpoint.channels, [channelName])
  }

  func testLeave_Router_Groups() {
    let router = PresenceRouter(.leave(channels: [], groups: [channelName]), configuration: config)
    XCTAssertEqual(router.endpoint.groups, [channelName])
  }
}

// MARK: - Get State Tests

extension PresenceRouterTests {
  func testGetState_Router() {
    let router = PresenceRouter(.getState(uuid: "TestUUID", channels: [channelName], groups: []), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Get Presence State")
    XCTAssertEqual(router.category, "Get Presence State")
    XCTAssertEqual(router.service, .presence)
  }

  func testGetState_Router_ValidationError() {
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

  func testGetState_Router_Channels() {
    let router = PresenceRouter(.getState(uuid: "TestUUID", channels: [channelName], groups: []), configuration: config)
    XCTAssertEqual(router.endpoint.channels, [channelName])
  }

  func testGetState_Router_Groups() {
    let router = PresenceRouter(.getState(uuid: "TestUUID", channels: [], groups: [channelName]), configuration: config)
    XCTAssertEqual(router.endpoint.groups, [channelName])
  }
}

// MARK: - Set State Tests

extension PresenceRouterTests {
  func testSetState_Router() {
    let router = PresenceRouter(.setState(channels: [channelName], groups: [], state: [:]), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Set Presence State")
    XCTAssertEqual(router.category, "Set Presence State")
    XCTAssertEqual(router.service, .presence)
  }

  func testSetState_Router_ValidationError() {
    let router = PresenceRouter(.setState(channels: [], groups: [], state: [:]), configuration: config)

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.missingChannelsAnyGroups
    )
  }

  func testSetState_Router_Channels() {
    let router = PresenceRouter(.setState(channels: [channelName], groups: [], state: [:]), configuration: config)
    XCTAssertEqual(router.endpoint.channels, [channelName])
  }

  func testSetState_Router_Groups() {
    let router = PresenceRouter(.setState(channels: [], groups: [channelName], state: [:]), configuration: config)
    XCTAssertEqual(router.endpoint.groups, [channelName])
  }

  // swiftlint:disable:next file_length
}
