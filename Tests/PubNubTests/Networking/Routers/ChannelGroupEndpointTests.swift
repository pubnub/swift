//
//  ChannelGroupEndpointTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class ChannelGroupsRouterTests: XCTestCase {
  var pubnub: PubNub!

  let subKey = "FakeSub"
  let pubKey = "FakePub"
  let config = PubNubConfiguration(publishKey: "FakePub", subscribeKey: "FakeSub", userId: UUID().uuidString)

  let testChannels = ["TestChannel", "OtherChannel"]
  let testGroupName = "TestGroup"
}

// MARK: - List Channel Groups

extension ChannelGroupsRouterTests {
  func testGroupList_Router() {
    let router = ChannelGroupsRouter(.channelGroups, configuration: config)

    XCTAssertEqual(router.endpoint.description, "Group List")
    XCTAssertEqual(router.category, "Group List")
    XCTAssertEqual(router.service, .channelGroup)
    XCTAssertEqual(router.pamVersion, .none)
  }

  func testGroupList_Router_ValidationError() {
    let router = ChannelGroupsRouter(.channelGroups, configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError, nil)
  }

  func testGroupList_Success() {
    let expectation = self.expectation(description: "Group List Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["groups_list_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testGroupList_Success_EmptyClasses() {
    let expectation = self.expectation(description: "Group List Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["groups_list_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub
      .listChannelGroups { result in
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
  func testGroupDelete_Router() {
    let router = ChannelGroupsRouter(.deleteGroup(group: testGroupName), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Group Delete")
    XCTAssertEqual(router.category, "Group Delete")
    XCTAssertEqual(router.service, .channelGroup)
  }

  func testGroupDelete_Router_ValidationError() {
    let router = ChannelGroupsRouter(.deleteGroup(group: ""), configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyGroupString)
  }

  func testGroupDelete_Success() {
    let expectation = self.expectation(description: "Group Delete Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["groups_delete_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.remove(channelGroup: testGroupName) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case let .failure(error):
        XCTFail("Group Delete request failed with error: \(error.localizedDescription)")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - List Channels For Group

extension ChannelGroupsRouterTests {
  func testChannelsForGroup_Router() {
    let router = ChannelGroupsRouter(.channelsForGroup(group: testGroupName), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Group Channels List")
    XCTAssertEqual(router.category, "Group Channels List")
    XCTAssertEqual(router.service, .channelGroup)
    XCTAssertEqual(router.pamVersion, .version2)
  }

  func testChannelsForGroup_Router_ValidationError() {
    let router = ChannelGroupsRouter(.channelsForGroup(group: ""), configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyGroupString)
  }

  func testGroupChannelsList_Success() {
    let expectation = self.expectation(description: "Group Channels List Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["groups_channels_list_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testGroupChannelsList_EmptyClasses() {
    let expectation = self.expectation(description: "Group Channels List Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["groups_channels_list_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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
  func test_AddChannelsForGroup_Router() {
    let router = ChannelGroupsRouter(.addChannelsToGroup(group: testGroupName, channels: testChannels),
                                     configuration: config)

    XCTAssertEqual(router.endpoint.description, "Group Channels Add")
    XCTAssertEqual(router.category, "Group Channels Add")
    XCTAssertEqual(router.service, .channelGroup)
  }

  func test_AddChannelsForGroup_Router_ValidationError() {
    let router = ChannelGroupsRouter(.addChannelsToGroup(group: "", channels: testChannels), configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyGroupString)

    let emptyChannel = ChannelGroupsRouter(.addChannelsToGroup(group: testGroupName, channels: []),
                                           configuration: config)

    XCTAssertEqual(emptyChannel.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelArray)
  }

  func testGroupChannels_Add_Success() {
    let expectation = self.expectation(description: "Group Channels Add Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["groups_channels_add_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.add(channels: testChannels, to: testGroupName) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case let .failure(error):
        XCTFail("Group Channels Add request failed with error: \(error.localizedDescription)")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testAddChannels_Error_ExceedGroupCount() {
    let expectation = self.expectation(description: "Add Channel Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["maximumChannelCountExceeded_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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

  func testAddChannels_Error_InvalidCharacter() {
    let expectation = self.expectation(description: "Add Channel Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["invalidCharacter_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
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
  func test_RemoveChannelsForGroup_Router() {
    let router = ChannelGroupsRouter(.removeChannelsForGroup(group: testGroupName, channels: testChannels),
                                     configuration: config)

    XCTAssertEqual(router.endpoint.description, "Group Channels Remove")
    XCTAssertEqual(router.category, "Group Channels Remove")
    XCTAssertEqual(router.service, .channelGroup)
  }

  func test_RemoveChannelsForGroup_Router_ValidationError() {
    let router = ChannelGroupsRouter(.removeChannelsForGroup(group: "", channels: testChannels), configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyGroupString)

    let emptyChannels = ChannelGroupsRouter(.removeChannelsForGroup(group: testGroupName, channels: []),
                                            configuration: config)

    XCTAssertEqual(emptyChannels.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyChannelArray)
  }

  func testGroupChannels_Remove_Success() {
    let expectation = self.expectation(description: "Group Channels Remove Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["groups_channels_remove_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.remove(channels: testChannels, from: testGroupName) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case let .failure(error):
        XCTFail("Group Channels Remove request failed with error: \(error.localizedDescription)")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
