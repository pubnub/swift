//
//  ChannelGroupEndpointTests.swift
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

@testable import PubNub
import XCTest

final class ChannelGroupsEndpointTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  let testChannels = ["TestChannel", "OtherChannel"]
  let testGroupName = "TestGroup"

  // MARK: - List Groups

  func testGroupList_Endpoint() {
    let endpoint = Endpoint.channelGroups

    XCTAssertEqual(endpoint.description, "Group List")
    XCTAssertEqual(endpoint.category, .channelGroups)
    XCTAssertEqual(endpoint.operationCategory, .channelGroup)
    XCTAssertNil(endpoint.validationError)
  }

  func testGroupList_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.channelGroups

    XCTAssertTrue(endpoint.associatedValue.isEmpty)
  }

  func testGroupList_Success() {
    let expectation = self.expectation(description: "Group List Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["groups_list_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session).listChannelGroups { result in
      switch result {
      case let .success(payload):
        XCTAssertFalse(payload.groups.isEmpty)
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

    PubNub(configuration: config, session: sessions.session).listChannelGroups { result in
      switch result {
      case let .success(payload):
        XCTAssertTrue(payload.groups.isEmpty)
      case let .failure(error):
        XCTFail("Group List request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Delete Group

  func testGroupDelete_Endpoint() {
    let endpoint = Endpoint.deleteGroup(group: testGroupName)

    XCTAssertEqual(endpoint.description, "Group Delete")
    XCTAssertEqual(endpoint.category, .deleteGroup)
    XCTAssertEqual(endpoint.operationCategory, .channelGroup)
    XCTAssertNil(endpoint.validationError)
  }

  func testGroupDelete_Endpoint_ValidationError() {
    let endpoint = Endpoint.deleteGroup(group: "")

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testGroupDelete_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.deleteGroup(group: "Some Group")

    XCTAssertEqual(endpoint.associatedValue["group"] as? String, "Some Group")
  }

  func testGroupDelete_Success() {
    let expectation = self.expectation(description: "Group Delete Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["groups_delete_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .delete(channelGroup: testGroupName) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.message, EndpointResponseMessage.acknowledge)
        case let .failure(error):
          XCTFail("Group Delete request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - List Group Channels

  func testChannelsForGroup_Endpoint() {
    let endpoint = Endpoint.channelsForGroup(group: testGroupName)

    XCTAssertEqual(endpoint.description, "Group Channels List")
    XCTAssertEqual(endpoint.category, .channelsForGroup)
    XCTAssertEqual(endpoint.operationCategory, .channelGroup)
    XCTAssertNil(endpoint.validationError)
  }

  func testChannelsForGroup_Endpoint_ValidationError() {
    let endpoint = Endpoint.channelsForGroup(group: "")

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testChannelsForGroup_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.channelsForGroup(group: "Some Group")

    XCTAssertEqual(endpoint.associatedValue["group"] as? String, "Some Group")
  }

  func testGroupChannelsList_Success() {
    let expectation = self.expectation(description: "Group Channels List Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["groups_channels_list_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .listChannels(for: testGroupName) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.group, self.testGroupName)
          XCTAssertFalse(payload.channels.isEmpty)
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

    PubNub(configuration: config, session: sessions.session)
      .listChannels(for: testGroupName) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.group, self.testGroupName)
          XCTAssertTrue(payload.channels.isEmpty)
        case let .failure(error):
          XCTFail("Group Channels List request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Add Group Channel

  func testGroupChannelsAdd_Endpoint() {
    let endpoint = Endpoint.addChannelsForGroup(group: testGroupName, channels: testChannels)

    XCTAssertEqual(endpoint.description, "Group Channels Add")
    XCTAssertEqual(endpoint.category, .addChannelsForGroup)
    XCTAssertEqual(endpoint.operationCategory, .channelGroup)
    XCTAssertNil(endpoint.validationError)
  }

  func testGroupChannelAdd_Endpoint_ValidationError() {
    let endpoint = Endpoint.addChannelsForGroup(group: "", channels: [])

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testAddChannelsForGroup_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.addChannelsForGroup(group: "GroupName", channels: ["Channels"])

    XCTAssertEqual(endpoint.associatedValue["group"] as? String, "GroupName")
    XCTAssertEqual(endpoint.associatedValue["channels"] as? [String], ["Channels"])
  }

  func testGroupChannels_Add_Success() {
    let expectation = self.expectation(description: "Group Channels Add Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["groups_channels_add_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .add(channels: testChannels, to: testGroupName) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.message, EndpointResponseMessage.acknowledge)
        case let .failure(error):
          XCTFail("Group Channels Add request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testAddChannels_Error_ExceedGroupCount() {
    let expectation = self.expectation(description: "Add Channel Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["maximumChannelCountExceeded_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .add(channels: testChannels, to: testGroupName) { result in
        print(result)
        switch result {
        case .success:
          XCTFail("Add Channel request should fail")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .maxChannelGroupCountExceeded))
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

    PubNub(configuration: config, session: sessions.session)
      .add(channels: testChannels, to: testGroupName) { result in
        print("Result: \(result)")
        switch result {
        case .success:
          XCTFail("Add Channel request should fail")
        case let .failure(error):
          XCTAssertEqual(error.pubNubError, PubNubError(reason: .invalidCharacter))
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Group Channel Remove

  func testGroupChannelsRemove_Endpoint() {
    let endpoint = Endpoint.removeChannelsForGroup(group: testGroupName, channels: testChannels)

    XCTAssertEqual(endpoint.description, "Group Channels Remove")
    XCTAssertEqual(endpoint.category, .removeChannelsForGroup)
    XCTAssertEqual(endpoint.operationCategory, .channelGroup)
    XCTAssertNil(endpoint.validationError)
  }

  func testGroupChannelRemove_Endpoint_ValidationError() {
    let endpoint = Endpoint.removeChannelsForGroup(group: "", channels: [])

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PubNubError(.invalidEndpointType, endpoint: endpoint))
  }

  func testGroupChannelRemove_Endpoint_AssociatedValues() {
    let endpoint = Endpoint.removeChannelsForGroup(group: "GroupName", channels: ["ChannelName"])

    XCTAssertEqual(endpoint.associatedValue["group"] as? String, "GroupName")
    XCTAssertEqual(endpoint.associatedValue["channels"] as? [String], ["ChannelName"])
  }

  func testGroupChannels_Remove_Success() {
    let expectation = self.expectation(description: "Group Channels Remove Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["groups_channels_remove_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .remove(channels: testChannels, from: testGroupName) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.message, EndpointResponseMessage.acknowledge)
        case let .failure(error):
          XCTFail("Group Channels Remove request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }
}
