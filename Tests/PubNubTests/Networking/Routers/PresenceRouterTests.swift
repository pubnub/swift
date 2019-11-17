//
//  PresenceRouterTests.swift
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

final class PresenceRouterTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  let channelName = "TestChannel"
  let otherChannel = "OtherTestChannel"
}

// MARK: - HereNow Tests

extension PresenceRouterTests {
  func testHereNow_Router() {
    let router = PresenceRouter(
      .hereNow(channels: [channelName], groups: [], includeUUIDs: true, includeState: true), configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Here Now")
    XCTAssertEqual(router.category, "Here Now")
    XCTAssertEqual(router.service, .presence)
  }

  func testHereNow_Router_ValidationError() {
    let router = PresenceRouter(
      .hereNow(channels: [], groups: [], includeUUIDs: true, includeState: true), configuration: config
    )

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.missingChannelsAnyGroups)
  }

  func testHereNow_Router_Channels() {
    let router = PresenceRouter(
      .hereNow(channels: [channelName], groups: [], includeUUIDs: true, includeState: true), configuration: config
    )

    XCTAssertEqual(router.endpoint.channels, [channelName])
  }

  func testHereNow_Router_Groups() {
    let router = PresenceRouter(
      .hereNow(channels: [], groups: [channelName], includeUUIDs: true, includeState: true), configuration: config
    )

    XCTAssertEqual(router.endpoint.groups, [channelName])
  }

  // Single Channel
  func testHereNow_Success_SingleChannel() {
    let expectation = self.expectation(description: "HereNow Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["herenow_singleChannel_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .hereNow(on: [channelName]) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.totalChannels, 1)
          XCTAssertEqual(payload.channels.count, payload.totalChannels)
          XCTAssertEqual(payload.channels.first?.key, self.channelName)
          XCTAssertEqual(payload.channels.first?.value.occupancy, payload.totalOccupancy)
          XCTAssertEqual(payload.channels.first?.value.uuids.count,
                         payload.channels.first?.value.occupancy)
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

    PubNub(configuration: config, session: sessions.session)
      .hereNow(on: [channelName], includeUUIDs: true, also: true) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.totalChannels, 1)
          XCTAssertEqual(payload.channels.count, payload.totalChannels)
          XCTAssertEqual(payload.channels.first?.key, self.channelName)
          XCTAssertEqual(payload.channels.first?.value.occupancy, payload.totalOccupancy)
          XCTAssertEqual(payload.channels.first?.value.uuids.count,
                         payload.channels.first?.value.occupancy)
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

    PubNub(configuration: config, session: sessions.session)
      .hereNow(on: [channelName], includeUUIDs: true, also: true) { result in
        switch result {
        case let .success(payload):
          XCTAssertTrue(payload.channels.isEmpty)
          XCTAssertEqual(payload.totalChannels, 0)
          XCTAssertEqual(payload.totalOccupancy, 0)
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

    PubNub(configuration: config, session: sessions.session)
      .hereNow(on: [channelName, otherChannel], includeUUIDs: true, also: true) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.totalChannels, 1)
          XCTAssertEqual(payload.channels.count, payload.totalChannels)
          XCTAssertEqual(payload.channels.first?.key, self.channelName)
          XCTAssertEqual(payload.channels.first?.value.occupancy, payload.totalOccupancy)
          XCTAssertEqual(payload.channels.first?.value.uuids.count,
                         payload.channels.first?.value.occupancy)
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

    PubNub(configuration: config, session: sessions.session)
      .hereNow(on: [channelName, otherChannel], includeUUIDs: true, also: true) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.totalChannels, 1)
          XCTAssertEqual(payload.channels.count, payload.totalChannels)
          XCTAssertEqual(payload.channels.first?.key, self.channelName)
          XCTAssertEqual(payload.channels.first?.value.occupancy, payload.totalOccupancy)
          XCTAssertEqual(payload.channels.first?.value.uuids.count,
                         payload.channels.first?.value.occupancy)
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

    PubNub(configuration: config, session: sessions.session)
      .hereNow(on: [channelName, otherChannel], includeUUIDs: true, also: true) { result in
        switch result {
        case let .success(payload):
          XCTAssertTrue(payload.channels.isEmpty)
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

    PubNub(configuration: config, session: sessions.session)
      .hereNow(on: [channelName, otherChannel], includeUUIDs: false, also: true) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.totalChannels, 1)
          XCTAssertEqual(payload.channels.count, payload.totalChannels)
          XCTAssertEqual(payload.channels.first?.key, channelName)
          XCTAssertEqual(payload.channels.first?.value.occupancy, payload.totalOccupancy)
          XCTAssertEqual(payload.channels.first?.value.uuids.count, 0)
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

    PubNub(configuration: config, session: sessions.session)
      .hereNow(on: [], includeUUIDs: true, also: true) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.totalChannels, 1)
          XCTAssertEqual(payload.channels.count, payload.totalChannels)
          XCTAssertEqual(payload.channels.first?.key, self.channelName)
          XCTAssertEqual(payload.channels.first?.value.occupancy, payload.totalOccupancy)
          XCTAssertEqual(payload.channels.first?.value.uuids.count,
                         payload.channels.first?.value.occupancy)
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

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyUUIDString)
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

    PubNub(configuration: config, session: sessions.session)
      .whereNow(for: "testUser") { result in
        switch result {
        case let .success(payload):
          XCTAssertTrue(payload.channels.isEmpty)
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

    PubNub(configuration: config, session: sessions.session)
      .whereNow(for: "testUser") { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.channels.count, 1)
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
    let router = PresenceRouter(.heartbeat(channels: [channelName], groups: [], presenceTimeout: nil),
                                configuration: config)

    XCTAssertEqual(router.endpoint.description, "Heartbeat")
    XCTAssertEqual(router.category, "Heartbeat")
    XCTAssertEqual(router.service, .presence)
  }

  func testHeartbeat_Router_ValidationError() {
    let router = PresenceRouter(.heartbeat(channels: [], groups: [], presenceTimeout: nil), configuration: config)

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.missingChannelsAnyGroups)
  }

  func testHeartbeat_Router_Channels() {
    let router = PresenceRouter(.heartbeat(channels: [channelName], groups: [], presenceTimeout: nil),
                                configuration: config)

    XCTAssertEqual(router.endpoint.channels, [channelName])
  }

  func testHeartbeat_Router_Groups() {
    let router = PresenceRouter(.heartbeat(channels: [], groups: [channelName], presenceTimeout: nil),
                                configuration: config)

    XCTAssertEqual(router.endpoint.groups, [channelName])
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

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.missingChannelsAnyGroups)
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
    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.emptyUUIDString)

    let missingChannelsGroups = PresenceRouter(.getState(uuid: "TestUUID", channels: [], groups: []),
                                               configuration: config)
    XCTAssertEqual(missingChannelsGroups.validationError?.pubNubError?.details.first,
                   ErrorDescription.missingChannelsAnyGroups)
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

    XCTAssertEqual(router.validationError?.pubNubError?.details.first,
                   ErrorDescription.missingChannelsAnyGroups)
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
