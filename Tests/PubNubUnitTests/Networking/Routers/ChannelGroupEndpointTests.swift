//
//  ChannelGroupEndpointTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class ChannelGroupsRouterTests: XCTestCase {
  let subKey = "FakeSub"
  let pubKey = "FakePub"
  let config = TestPubNubFactory.makeConfig(publishKey: "FakePub", subscribeKey: "FakeSub")
  let testChannels = ["TestChannel", "OtherChannel"]
  let testGroupName = "TestGroup"
}

// MARK: - List Channel Groups

extension ChannelGroupsRouterTests {
  func test_GroupListRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = ChannelGroupsRouter(.channelGroups, configuration: config)

    XCTAssertEqual(router.endpoint.description, "Group List")
    XCTAssertEqual(router.category, "Group List")
    XCTAssertEqual(router.service, .channelGroup)
    XCTAssertEqual(router.pamVersion, .none)
  }

  func test_GroupList_WithValidConfig_ReturnsNoValidationError() {
    let router = ChannelGroupsRouter(.channelGroups, configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError, nil)
  }

  func test_GroupList_WithValidConfig_ReturnsGroups() throws {
    let expectation = self.expectation(description: "Group List Response Received")
    let sessions = try MockURLSession.mockSession(for: ["groups_list_success"])
    let pubnub = TestPubNubFactory.make(publishKey: "FakePub", subscribeKey: "FakeSub", session: sessions.session)

    pubnub.listChannelGroups { result in
      switch result {
      case let .success(groups):
        XCTAssertFalse(groups.isEmpty)
      case let .failure(error):
        XCTFail("Group List request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_GroupList_WithNoGroups_ReturnsEmptyGroups() throws {
    let expectation = self.expectation(description: "Group List Response Received")
    let sessions = try MockURLSession.mockSession(for: ["groups_list_success_empty"])
    let pubnub = TestPubNubFactory.make(publishKey: "FakePub", subscribeKey: "FakeSub", session: sessions.session)

    pubnub.listChannelGroups { result in
      switch result {
      case let .success(groups):
        XCTAssertTrue(groups.isEmpty)
      case let .failure(error):
        XCTFail("Group List request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Delete Group

extension ChannelGroupsRouterTests {
  func test_GroupDeleteRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = ChannelGroupsRouter(.deleteGroup(group: testGroupName), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Group Delete")
    XCTAssertEqual(router.category, "Group Delete")
    XCTAssertEqual(router.service, .channelGroup)
  }

  func test_GroupDelete_WhenGroupEmpty_ReturnsValidationError() {
    let router = ChannelGroupsRouter(.deleteGroup(group: ""), configuration: config)

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.emptyGroupString
    )
  }

  func test_GroupDelete_WithValidGroup_ReturnsSuccess() throws {
    let expectation = self.expectation(description: "Group Delete Response Received")
    let sessions = try MockURLSession.mockSession(for: ["groups_delete_success"])
    let pubnub = TestPubNubFactory.make(publishKey: "FakePub", subscribeKey: "FakeSub", session: sessions.session)

    pubnub.remove(channelGroup: testGroupName) { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Group Delete request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - List Channels For Group

extension ChannelGroupsRouterTests {
  func test_ChannelsForGroupRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = ChannelGroupsRouter(.channelsForGroup(group: testGroupName), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Group Channels List")
    XCTAssertEqual(router.category, "Group Channels List")
    XCTAssertEqual(router.service, .channelGroup)
    XCTAssertEqual(router.pamVersion, .version2)
  }

  func test_ChannelsForGroup_WhenGroupEmpty_ReturnsValidationError() {
    let router = ChannelGroupsRouter(.channelsForGroup(group: ""), configuration: config)

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.emptyGroupString
    )
  }

  func test_GroupChannelsList_WithValidGroup_ReturnsChannels() throws {
    let expectation = self.expectation(description: "Group Channels List Response Received")
    let sessions = try MockURLSession.mockSession(for: ["groups_channels_list_success"])
    let pubnub = TestPubNubFactory.make(publishKey: "FakePub", subscribeKey: "FakeSub", session: sessions.session)

    pubnub.listChannels(for: testGroupName) { result in
      switch result {
      case let .success(response):
        XCTAssertEqual(response.group, self.testGroupName)
        XCTAssertFalse(response.channels.isEmpty)
      case let .failure(error):
        XCTFail("Group Channels List request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_GroupChannelsList_WithValidGroupNoChannels_ReturnsEmptyChannels() throws {
    let expectation = self.expectation(description: "Group Channels List Response Received")
    let sessions = try MockURLSession.mockSession(for: ["groups_channels_list_success_empty"])
    let pubnub = TestPubNubFactory.make(publishKey: "FakePub", subscribeKey: "FakeSub", session: sessions.session)

    pubnub.listChannels(for: testGroupName) { result in
      switch result {
      case let .success(response):
        XCTAssertEqual(response.group, self.testGroupName)
        XCTAssertTrue(response.channels.isEmpty)
      case let .failure(error):
        XCTFail("Group Channels List request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Add Channel to Group

extension ChannelGroupsRouterTests {
  func test_AddChannelsForGroupRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = ChannelGroupsRouter(
      .addChannelsToGroup(
        group: testGroupName,
        channels: testChannels
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Group Channels Add")
    XCTAssertEqual(router.category, "Group Channels Add")
    XCTAssertEqual(router.service, .channelGroup)
  }

  func test_AddChannelsForGroup_WhenGroupEmpty_ReturnsValidationError() {
    let router = ChannelGroupsRouter(.addChannelsToGroup(group: "", channels: testChannels), configuration: config)

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.emptyGroupString
    )
  }

  func test_AddChannelsForGroup_WhenChannelsEmpty_ReturnsValidationError() {
    let router = ChannelGroupsRouter(
      .addChannelsToGroup(
        group: testGroupName,
        channels: []
      ),
      configuration: config
    )

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.emptyChannelArray
    )
  }

  func test_GroupChannelsAdd_WithValidChannels_ReturnsSuccess() throws {
    let expectation = self.expectation(description: "Group Channels Add Response Received")
    let sessions = try MockURLSession.mockSession(for: ["groups_channels_add_success"])
    let pubnub = TestPubNubFactory.make(publishKey: "FakePub", subscribeKey: "FakeSub", session: sessions.session)

    pubnub.add(channels: testChannels, to: testGroupName) { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Group Channels Add request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_AddChannels_WhenGroupCountExceeded_ReturnsMaxCountExceededError() throws {
    let expectation = self.expectation(description: "Add Channel Response Received")
    let sessions = try MockURLSession.mockSession(for: ["maximumChannelCountExceeded_Message"])
    let pubnub = TestPubNubFactory.make(publishKey: "FakePub", subscribeKey: "FakeSub", session: sessions.session)

    pubnub.add(channels: testChannels, to: testGroupName) { result in
      switch result {
      case .success:
        XCTFail("Add Channel request should fail")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.maxChannelGroupCountExceeded))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func test_AddChannels_WhenInvalidCharacter_ReturnsInvalidCharacterError() throws {
    let expectation = self.expectation(description: "Add Channel Response Received")
    let sessions = try MockURLSession.mockSession(for: ["invalidCharacter_Message"])
    let pubnub = TestPubNubFactory.make(publishKey: "FakePub", subscribeKey: "FakeSub", session: sessions.session)

    pubnub.add(channels: testChannels, to: testGroupName) { result in
      switch result {
      case .success:
        XCTFail("Add Channel request should fail")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.invalidCharacter))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Remove Channel from Group

extension ChannelGroupsRouterTests {
  func test_RemoveChannelsForGroupRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = ChannelGroupsRouter(
      .removeChannelsForGroup(
        group: testGroupName,
        channels: testChannels
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Group Channels Remove")
    XCTAssertEqual(router.category, "Group Channels Remove")
    XCTAssertEqual(router.service, .channelGroup)
  }

  func test_RemoveChannelsForGroup_WhenGroupEmpty_ReturnsValidationError() {
    let router = ChannelGroupsRouter(
      .removeChannelsForGroup(
        group: "",
        channels: testChannels
      ),
      configuration: config
    )

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.emptyGroupString
    )
  }

  func test_RemoveChannelsForGroup_WhenChannelsEmpty_ReturnsValidationError() {
    let router = ChannelGroupsRouter(
      .removeChannelsForGroup(
        group: testGroupName,
        channels: []
      ), configuration: config
    )

    XCTAssertEqual(
      router.validationError?.pubNubError?.details.first,
      ErrorDescription.emptyChannelArray
    )
  }

  func test_GroupChannelsRemove_WithValidChannels_ReturnsSuccess() throws {
    let expectation = self.expectation(description: "Group Channels Remove Response Received")
    let sessions = try MockURLSession.mockSession(for: ["groups_channels_remove_success"])
    let pubnub = TestPubNubFactory.make(publishKey: "FakePub", subscribeKey: "FakeSub", session: sessions.session)

    pubnub.remove(channels: testChannels, from: testGroupName) { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Group Channels Remove request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
