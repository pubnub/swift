//
//  PushRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

final class PushRouterTests: XCTestCase {
  let testChannels = ["TestChannel", "OtherChannel"]

  let hexString = "815ee724ccb0a6a84dc303be8ccbaa00d1c84dde6bcae6721b08f92100951113"
}

// MARK: - List Push Channels

extension PushRouterTests {
  func test_ListFCMPushProvisions_WithValidConfig_SetsExpectedEndpoint() {
    let config = TestPubNubFactory.makeConfig()
    let data = Data("A1b2".utf8)
    let router = PushRouter(.listPushChannels(pushToken: data, pushType: .fcm), configuration: config)

    XCTAssertEqual(router.endpoint.description, "List Push Channels")
    XCTAssertEqual(router.endpoint.pushToken, "A1b2")
    XCTAssertEqual(router.category, "List Push Channels")
    XCTAssertEqual(router.service, .push)
  }

  func test_ListFCMPushProvisions_WhenTokenInvalid_ReturnsNilPushToken() throws {
    let config = TestPubNubFactory.makeConfig()
    let data = try XCTUnwrap(Data(hexEncodedString: "A1b2"))
    let router = PushRouter(.listPushChannels(pushToken: data, pushType: .fcm), configuration: config)

    XCTAssertEqual(router.endpoint.description, "List Push Channels")
    XCTAssertEqual(router.category, "List Push Channels")
    XCTAssertNil(router.endpoint.pushToken)
    XCTAssertEqual(router.service, .push)
  }

  func test_ListPushProvisions_WithValidAPNSConfig_SetsExpectedEndpoint() throws {
    let config = TestPubNubFactory.makeConfig()
    let data = try XCTUnwrap(Data(hexEncodedString: "A1B2"))
    let router = PushRouter(.listPushChannels(pushToken: data, pushType: .apns), configuration: config)

    XCTAssertEqual(router.endpoint.description, "List Push Channels")
    XCTAssertEqual(router.category, "List Push Channels")
    XCTAssertEqual(router.service, .push)
  }

  func test_ListPushProvisions_WhenTokenEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()
    let router = PushRouter(.listPushChannels(pushToken: Data(), pushType: .apns), configuration: config)

    XCTAssertNil(router.validationError)
  }

  func test_ListPushRegistration_WithValidToken_ReturnsChannels() throws {
    let expectation = self.expectation(description: "Push List Response Received")

    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_list_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_ListPushRegistration_WithValidToken_ReturnsEmptyChannels() throws {
    let expectation = self.expectation(description: "Push List Response Received")
    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_list_success_empty"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_ListPushRegistration_WhenPushNotEnabled_ReturnsPushNotEnabledError() throws {
    let expectation = self.expectation(description: "Push List Response Received")
    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_not_enabled_for_key_Message"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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
  func test_ModifyPushChannelsRouter_WithValidConfig_SetsExpectedEndpoint() throws {
    let config = TestPubNubFactory.makeConfig()
    let data = try XCTUnwrap(Data(hexEncodedString: "A1B2"))
    let router = PushRouter(
      .managePushChannels(
        pushToken: data,
        pushType: .apns,
        joining: testChannels,
        leaving: []
      ), configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Modify Push Channels")
    XCTAssertEqual(router.category, "Modify Push Channels")
    XCTAssertEqual(router.service, .push)
  }

  func test_ModifyPushChannels_WhenTokenAndChannelsEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()
    let router = PushRouter(
      .managePushChannels(
        pushToken: Data(),
        pushType: .apns,
        joining: [],
        leaving: []
      ), configuration: config
    )

    XCTAssertNil(router.validationError)
  }

  func test_ModifyPush_WithValidChannels_ReturnsRemovedChannels() throws {
    let expectation = self.expectation(description: "Modify Push Response Received")

    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_modify_success"])
    let testRemoved = testChannels
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_ModifyPush_WhenPushNotEnabled_ReturnsPushNotEnabledError() throws {
    let expectation = self.expectation(description: "Modify Push Response Received")
    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_not_enabled_for_key_Message"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_ModifyPush_WhenTokenInvalid_ReturnsInvalidDeviceTokenError() throws {
    let expectation = self.expectation(description: "Modify Push Response Received")
    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["invalid_device_token_Message"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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
  func test_RemoveAllPushChannelsRouter_WithValidConfig_SetsExpectedEndpoint() throws {
    let config = TestPubNubFactory.makeConfig()
    let data = try XCTUnwrap(Data(hexEncodedString: "A1B2"))
    let router = PushRouter(.removeAllPushChannels(pushToken: data, pushType: .apns), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Remove All Push Channels")
    XCTAssertEqual(router.category, "Remove All Push Channels")
    XCTAssertEqual(router.service, .push)
  }

  func test_RemoveAllPushChannels_WhenTokenEmpty_ReturnsValidationError() {
    let config = TestPubNubFactory.makeConfig()
    let router = PushRouter(.removeAllPushChannels(pushToken: Data(), pushType: .apns), configuration: config)

    XCTAssertNil(router.validationError)
  }

  func test_RemoveAllPush_WithValidToken_ReturnsSuccess() throws {
    let expectation = self.expectation(description: "Group List Response Received")

    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_remove_all_success"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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
  func test_ModifyAPNSRouter_WithValidConfig_SetsExpectedEndpoint() throws {
    let config = TestPubNubFactory.makeConfig()
    let data = try XCTUnwrap(Data(hexEncodedString: "A1B2"))

    let router = PushRouter(
      .manageAPNS(
        pushToken: data,
        environment: .development,
        topic: "TestTopic",
        adding: [],
        removing: []
      ), configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "List/Modify APNS Devices")
    XCTAssertEqual(router.category, "List/Modify APNS Devices")
    XCTAssertEqual(router.service, .push)
  }

  func test_ModifyAPNS_WhenTokenOrTopicEmpty_ReturnsValidationError() throws {
    let config = TestPubNubFactory.makeConfig()
    let router = PushRouter(
      .manageAPNS(
        pushToken: Data(),
        environment: .development,
        topic: "TestTopic",
        adding: [],
        removing: []
      ),
      configuration: config
    )

    XCTAssertNil(router.validationError)

    let data = try XCTUnwrap(Data(hexEncodedString: "A1B2"))
    let emptyTopic = PushRouter(
      .manageAPNS(
        pushToken: data,
        environment: .development,
        topic: "",
        adding: [],
        removing: []
      ),
      configuration: config
    )

    XCTAssertNotEqual(
      emptyTopic.validationError?.pubNubError,
      PubNubError(.invalidEndpointType, router: emptyTopic)
    )
  }

  func test_ModifyAPNSListChannels_WithValidToken_ReturnsChannels() throws {
    let expectation = self.expectation(description: "Push List Response Received")
    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_list_success"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_ModifyAPNSListChannels_WhenPushNotEnabled_ReturnsPushNotEnabledError() throws {
    let expectation = self.expectation(description: "Push List Response Received")
    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_not_enabled_for_key_Message"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_ModifyAPNSListChannels_WithValidToken_ReturnsEmptyChannels() throws {
    let expectation = self.expectation(description: "Push List Response Received")
    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_list_success_empty"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_ModifyAPNSAddRemove_WithValidChannels_ReturnsRemovedChannels() throws {
    let expectation = self.expectation(description: "Modify Push Response Received")
    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_modify_success"])
    let testRemoved = testChannels

    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.manageAPNSDevicesOnChannels(
      byRemoving: testChannels,
      thenAdding: [],
      device: hexData,
      on: "TestTopic"
    ) { result in
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

  func test_ModifyAPNSAddRemove_WhenBothEmpty_ReturnsMissingParameterError() throws {
    let expectation = self.expectation(description: "Modify Push Response Received")

    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_not_enabled_for_key_Message"])
    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_ModifyAPNSAddRemove_WhenPushNotEnabled_ReturnsPushNotEnabledError() throws {
    let expectation = self.expectation(description: "Modify Push Response Received")
    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_not_enabled_for_key_Message"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)

    pubnub.manageAPNSDevicesOnChannels(
      byRemoving: testChannels,
      thenAdding: [],
      device: hexData,
      on: "TestTopic"
    ) { result in
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
  func test_RemoveAllAPNSChannelsRouter_WithValidConfig_SetsExpectedEndpoint() throws {
    let config = TestPubNubFactory.makeConfig()
    let data = try XCTUnwrap(Data(hexEncodedString: "A1B2"))

    let router = PushRouter(
      .removeAllAPNS(
        pushToken: data,
        environment: .development,
        topic: "TestTopic"
      ),
      configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Remove all channels from APNS device")
    XCTAssertEqual(router.category, "Remove all channels from APNS device")
    XCTAssertEqual(router.service, .push)
  }

  func test_RemoveAllAPNSChannels_WhenTokenEmpty_ReturnsValidationError() throws {
    let config = TestPubNubFactory.makeConfig()
    let router = PushRouter(
      .removeAllAPNS(
        pushToken: Data(),
        environment: .development,
        topic: "TestTopic"
      ),
      configuration: config
    )

    XCTAssertNil(router.validationError)

    let data = try XCTUnwrap(Data(hexEncodedString: "A1B2"))
    let emptyTopic = PushRouter(
      .removeAllAPNS(
        pushToken: data,
        environment: .development,
        topic: "TestTopic"
      ), configuration: config
    )

    XCTAssertNotEqual(
      emptyTopic.validationError?.pubNubError,
      PubNubError(.invalidEndpointType, router: emptyTopic)
    )
  }

  func test_RemoveAllAPNSChannels_WithValidToken_ReturnsSuccess() throws {
    let expectation = self.expectation(description: "Group List Response Received")
    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_remove_all_success"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)

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

  func test_RemoveAllAPNSChannels_WhenPushNotEnabled_ReturnsPushNotEnabledError() throws {
    let expectation = self.expectation(description: "Push List Response Received")
    let hexData = try XCTUnwrap(Data(hexEncodedString: hexString))
    let sessions = try MockURLSession.mockSession(for: ["push_not_enabled_for_key_Message"])

    let pubnub = TestPubNubFactory.make(session: sessions.session)

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
}
