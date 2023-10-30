//
//  PushRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNub
import XCTest

final class PushRouterTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString", userId: UUID().uuidString)

  let testChannels = ["TestChannel", "OtherChannel"]

  let hexString = "815ee724ccb0a6a84dc303be8ccbaa00d1c84dde6bcae6721b08f92100951113"
}

// MARK: - List Push Channels

extension PushRouterTests {
  func testListFCMPushProvisions_Router() {
    let data = "A1b2".data(using: .utf8)!
    let router = PushRouter(.listPushChannels(pushToken: data, pushType: .gcm), configuration: config)

    XCTAssertEqual(router.endpoint.description, "List Push Channels")
    XCTAssertEqual(router.endpoint.pushToken, "A1b2")
    XCTAssertEqual(router.category, "List Push Channels")
    XCTAssertEqual(router.service, .push)
  }

  func testListFCMPushProvisions_Router_TokenError() {
    guard let data = Data(hexEncodedString: "A1b2") else {
      return XCTFail("Could not encode Data from hex string")
    }
    let router = PushRouter(.listPushChannels(pushToken: data, pushType: .gcm), configuration: config)

    XCTAssertEqual(router.endpoint.description, "List Push Channels")
    XCTAssertEqual(router.category, "List Push Channels")
    XCTAssertNil(router.endpoint.pushToken)
    XCTAssertEqual(router.service, .push)
  }

  func testListPushProvisions_Router() {
    guard let data = Data(hexEncodedString: "A1B2") else {
      return XCTFail("Could not encode Data from hex string")
    }
    let router = PushRouter(.listPushChannels(pushToken: data, pushType: .apns), configuration: config)

    XCTAssertEqual(router.endpoint.description, "List Push Channels")
    XCTAssertEqual(router.category, "List Push Channels")
    XCTAssertEqual(router.service, .push)
  }

  func testListPushProvisions_Router_ValidationError() {
    let router = PushRouter(.listPushChannels(pushToken: Data(), pushType: .apns), configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))
  }

  func testListPushRegistration_Success() {
    let expectation = self.expectation(description: "Push List Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_list_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.listPushChannelRegistrations(for: hexData) { result in
      switch result {
      case let .success(channels):
        XCTAssertFalse(channels.isEmpty)
      case let .failure(error):
        XCTFail("Push List request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testListPushRegistration_Success_Empty() {
    let expectation = self.expectation(description: "Push List Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_list_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.listPushChannelRegistrations(for: hexData) { result in
      switch result {
      case let .success(channels):
        XCTAssertTrue(channels.isEmpty)
      case let .failure(error):
        XCTFail("Push List request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testListPushRegistration_Fail_NotEnabled() {
    let expectation = self.expectation(description: "Push List Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_not_enabled_for_key_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.listPushChannelRegistrations(for: hexData) { result in
      switch result {
      case .success:
        XCTFail("This should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.pushNotEnabled))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Modify Push Channels Tests

extension PushRouterTests {
  func testModifyPushChannels_Router() {
    guard let data = Data(hexEncodedString: "A1B2") else {
      return XCTFail("Could not encode Data from hex string")
    }

    let router = PushRouter(
      .managePushChannels(pushToken: data, pushType: .apns, joining: testChannels, leaving: []), configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Modify Push Channels")
    XCTAssertEqual(router.category, "Modify Push Channels")
    XCTAssertEqual(router.service, .push)
  }

  func testListModifyPushChannels_Router_ValidationError() {
    let router = PushRouter(
      .managePushChannels(pushToken: Data(), pushType: .apns, joining: [], leaving: []), configuration: config
    )

    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))
  }

  func testModifyPush_Success() {
    let expectation = self.expectation(description: "Modify Push Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_modify_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let testRemoved = testChannels

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.managePushChannelRegistrations(byRemoving: testChannels, thenAdding: [], for: hexData) { result in
      switch result {
      case let .success(response):
        XCTAssertEqual(response.removed, testRemoved)
      case let .failure(error):
        XCTFail("Modify Push request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testModifyPush_Fail_NotEnabled() {
    let expectation = self.expectation(description: "Modify Push Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_not_enabled_for_key_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.managePushChannelRegistrations(byRemoving: testChannels, thenAdding: [], for: hexData) { result in
      switch result {
      case .success:
        XCTFail("This should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.pushNotEnabled))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testModifyPush_Fail_InvalidToken() {
    let expectation = self.expectation(description: "Modify Push Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["invalid_device_token_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.managePushChannelRegistrations(byRemoving: testChannels, thenAdding: [], for: hexData) { result in
      switch result {
      case .success:
        XCTFail("This should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.invalidDevicePushToken))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Remove All Push Channels Tests

extension PushRouterTests {
  func testRemoveAllPushChannels_Router() {
    guard let data = Data(hexEncodedString: "A1B2") else {
      return XCTFail("Could not encode Data from hex string")
    }

    let router = PushRouter(.removeAllPushChannels(pushToken: data, pushType: .apns), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Remove All Push Channels")
    XCTAssertEqual(router.category, "Remove All Push Channels")
    XCTAssertEqual(router.service, .push)
  }

  func testRemoveAllPushChannels_Router_ValidationError() {
    let router = PushRouter(.removeAllPushChannels(pushToken: Data(), pushType: .apns), configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))
  }

  func testRemoveAllPush_Success() {
    let expectation = self.expectation(description: "Group List Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_remove_all_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.removeAllPushChannelRegistrations(for: hexData) { result in
      switch result {
      case .success:
        expectation.fulfill()
      case let .failure(error):
        XCTFail("Group List request failed with error: \(error.localizedDescription)")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Remove All Push Channels Tests

extension PushRouterTests {
  func testModifyAPNS_Router() {
    guard let data = Data(hexEncodedString: "A1B2") else {
      return XCTFail("Could not encode Data from hex string")
    }

    let router = PushRouter(.manageAPNS(pushToken: data, environment: .development,
                                        topic: "TestTopic", adding: [], removing: []), configuration: config)

    XCTAssertEqual(router.endpoint.description, "List/Modify APNS Devices")
    XCTAssertEqual(router.category, "List/Modify APNS Devices")
    XCTAssertEqual(router.service, .push)
  }

  func testModifyAPNS_Router_ValidationError() {
    let router = PushRouter(.manageAPNS(pushToken: Data(), environment: .development,
                                        topic: "TestTopic", adding: [], removing: []),
                            configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))

    guard let data = Data(hexEncodedString: "A1B2") else {
      return XCTFail("Could not encode Data from hex string")
    }

    let emptyTopic = PushRouter(.manageAPNS(pushToken: data, environment: .development,
                                            topic: "", adding: [], removing: []),
                                configuration: config)

    XCTAssertNotEqual(emptyTopic.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: emptyTopic))
  }

  func testModifyAPNS_ListChannels_Success() {
    let expectation = self.expectation(description: "Push List Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_list_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.listAPNSPushChannelRegistrations(for: hexData, on: "TestTopic") { result in
      switch result {
      case let .success(channels):
        XCTAssertFalse(channels.isEmpty)
      case let .failure(error):
        XCTFail("Push List request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testModifyAPNS_ListChannels_Fail_NotEnabled() {
    let expectation = self.expectation(description: "Push List Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_not_enabled_for_key_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.listAPNSPushChannelRegistrations(for: hexData, on: "TestTopic") { result in
      switch result {
      case .success:
        XCTFail("This should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.pushNotEnabled))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testModifyAPNS_ListChannels_Success_Empty() {
    let expectation = self.expectation(description: "Push List Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_list_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.listAPNSPushChannelRegistrations(for: hexData, on: "TestTopic") { result in
      switch result {
      case let .success(channels):
        XCTAssertTrue(channels.isEmpty)
      case let .failure(error):
        XCTFail("Push List request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testModifyAPNS_AddRemove_Success() {
    let expectation = self.expectation(description: "Modify Push Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_modify_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let testRemoved = testChannels

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.manageAPNSDevicesOnChannels(byRemoving: testChannels, thenAdding: [],
                                       device: hexData, on: "TestTopic") { result in
      switch result {
      case let .success(response):
        XCTAssertEqual(response.removed, testRemoved)
      case let .failure(error):
        XCTFail("Modify Push request failed with error: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testModifyAPNS_AddRemove_Fail_EmptyAddRemove() {
    let expectation = self.expectation(description: "Modify Push Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_not_enabled_for_key_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.manageAPNSDevicesOnChannels(byRemoving: [], thenAdding: [], device: hexData, on: "TestTopic") { result in
      switch result {
      case .success:
        XCTFail("This should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.missingRequiredParameter))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testModifyAPNS_AddRemove_Fail_NotEnabled() {
    let expectation = self.expectation(description: "Modify Push Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_not_enabled_for_key_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.manageAPNSDevicesOnChannels(byRemoving: testChannels, thenAdding: [],
                                       device: hexData, on: "TestTopic") { result in
      switch result {
      case .success:
        XCTFail("This should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.pushNotEnabled))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Remove All APNS Channels Tests

extension PushRouterTests {
  func testRemoveAllAPNSChannels_Router() {
    guard let data = Data(hexEncodedString: "A1B2") else {
      return XCTFail("Could not encode Data from hex string")
    }

    let router = PushRouter(.removeAllAPNS(pushToken: data, environment: .development, topic: "TestTopic"),
                            configuration: config)

    XCTAssertEqual(router.endpoint.description, "Remove all channels from APNS device")
    XCTAssertEqual(router.category, "Remove all channels from APNS device")
    XCTAssertEqual(router.service, .push)
  }

  func testRemoveAllAPNSChannels_Router_ValidationError() {
    let router = PushRouter(.removeAllAPNS(pushToken: Data(), environment: .development, topic: "TestTopic"),
                            configuration: config)
    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))

    guard let data = Data(hexEncodedString: "A1B2") else {
      return XCTFail("Could not encode Data from hex string")
    }
    let emptyTopic = PushRouter(.removeAllAPNS(pushToken: data, environment: .development, topic: "TestTopic"),
                                configuration: config)
    XCTAssertNotEqual(emptyTopic.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: emptyTopic))
  }

  func testRemoveAllAPNSChannels_Success() {
    let expectation = self.expectation(description: "Group List Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_remove_all_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.removeAllAPNSPushDevice(for: hexData, on: "TestTopic") { result in
      switch result {
      case .success:
        expectation.fulfill()
      case let .failure(error):
        XCTFail("Group List request failed with error: \(error.localizedDescription)")
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testRemoveAllAPNSChannels_Fail_NotEnabled() {
    let expectation = self.expectation(description: "Push List Response Received")

    guard let hexData = Data(hexEncodedString: hexString) else {
      return XCTFail("Could not conver hex string to data")
    }

    guard let sessions = try? MockURLSession.mockSession(for: ["push_not_enabled_for_key_Message"]) else {
      return XCTFail("Could not create mock url session")
    }

    let pubnub = PubNub(configuration: config, session: sessions.session)
    pubnub.removeAllAPNSPushDevice(for: hexData, on: "TestTopic") { result in
      switch result {
      case .success:
        XCTFail("This should not succeed")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError, PubNubError(.pushNotEnabled))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // swiftlint:disable:next file_length
}
