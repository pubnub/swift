//
//  PushRouterTests.swift
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

final class PushRouterTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  let testChannels = ["TestChannel", "OtherChannel"]

  let hexString = "815ee724ccb0a6a84dc303be8ccbaa00d1c84dde6bcae6721b08f92100951113"
}

// MARK: - List Push Channels

extension PushRouterTests {
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

    PubNub(configuration: config, session: sessions.session)
      .listPushChannelRegistrations(for: hexData) { result in
        switch result {
        case let .success(payload):
          XCTAssertFalse(payload.channels.isEmpty)
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

    PubNub(configuration: config, session: sessions.session)
      .listPushChannelRegistrations(for: hexData) { result in
        switch result {
        case let .success(payload):
          XCTAssertTrue(payload.channels.isEmpty)
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

    PubNub(configuration: config, session: sessions.session)
      .listPushChannelRegistrations(for: hexData) { result in
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
      .modifyPushChannels(pushToken: data, pushType: .apns, joining: testChannels, leaving: []), configuration: config
    )

    XCTAssertEqual(router.endpoint.description, "Modify Push Channels")
    XCTAssertEqual(router.category, "Modify Push Channels")
    XCTAssertEqual(router.service, .push)
  }

  func testListModifyPushChannels_Router_ValidationError() {
    let router = PushRouter(
      .modifyPushChannels(pushToken: Data(), pushType: .apns, joining: [], leaving: []), configuration: config
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

    PubNub(configuration: config, session: sessions.session)
      .modifyPushChannelRegistrations(byRemoving: testChannels, thenAdding: [], for: hexData) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.message, .acknowledge)
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

    PubNub(configuration: config, session: sessions.session)
      .modifyPushChannelRegistrations(byRemoving: testChannels, thenAdding: [], for: hexData) { result in
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

    PubNub(configuration: config, session: sessions.session)
      .modifyPushChannelRegistrations(byRemoving: testChannels, thenAdding: [], for: hexData) { result in
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

    PubNub(configuration: config, session: sessions.session)
      .removeAllPushChannelRegistrations(for: hexData) { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.message, .acknowledge)
        case let .failure(error):
          XCTFail("Group List request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
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

    let router = PushRouter(.modifyAPNS(pushToken: data, environment: .production, topic: "TestTopic", adding: [], removing: []), configuration: config)

    XCTAssertEqual(router.endpoint.description, "List/Modify APNS Devices")
    XCTAssertEqual(router.category, "List/Modify APNS Devices")
    XCTAssertEqual(router.service, .push)
  }

  func testModifyAPNS_Router_ValidationError() {
    let router = PushRouter(.modifyAPNS(pushToken: Data(), environment: .production, topic: "TestTopic", adding: [], removing: []),
                            configuration: config)

    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))

    guard let data = Data(hexEncodedString: "A1B2") else {
      return XCTFail("Could not encode Data from hex string")
    }

    let emptyTopic = PushRouter(.modifyAPNS(pushToken: data, environment: .production, topic: "", adding: [], removing: []),
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

    PubNub(configuration: config, session: sessions.session)
      .listAPNSChannelsOnDevice(for: hexData, on: "TestTopic") { result in
        switch result {
        case let .success(payload):
          XCTAssertFalse(payload.channels.isEmpty)
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

    PubNub(configuration: config, session: sessions.session)
      .listAPNSChannelsOnDevice(for: hexData, on: "TestTopic") { result in
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

    PubNub(configuration: config, session: sessions.session)
      .listAPNSChannelsOnDevice(for: hexData, on: "TestTopic") { result in
        switch result {
        case let .success(payload):
          XCTAssertTrue(payload.channels.isEmpty)
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

    PubNub(configuration: config, session: sessions.session)
      .modifyAPNSDevicesOnChannels(byRemoving: testChannels, thenAdding: [], device: hexData, on: "TestTopic") { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.message, .acknowledge)
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

    PubNub(configuration: config, session: sessions.session)
      .modifyAPNSDevicesOnChannels(byRemoving: [], thenAdding: [], device: hexData, on: "TestTopic") { result in
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

    PubNub(configuration: config, session: sessions.session)
      .modifyAPNSDevicesOnChannels(byRemoving: testChannels, thenAdding: [], device: hexData, on: "TestTopic") { result in
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

    let router = PushRouter(.removeAllAPNS(pushToken: data, environment: .production, topic: "TestTopic"),
                            configuration: config)

    XCTAssertEqual(router.endpoint.description, "Remove all channels from APNS device")
    XCTAssertEqual(router.category, "Remove all channels from APNS device")
    XCTAssertEqual(router.service, .push)
  }

  func testRemoveAllAPNSChannels_Router_ValidationError() {
    let router = PushRouter(.removeAllAPNS(pushToken: Data(), environment: .production, topic: "TestTopic"),
                            configuration: config)
    XCTAssertNotEqual(router.validationError?.pubNubError, PubNubError(.invalidEndpointType, router: router))

    guard let data = Data(hexEncodedString: "A1B2") else {
      return XCTFail("Could not encode Data from hex string")
    }
    let emptyTopic = PushRouter(.removeAllAPNS(pushToken: data, environment: .production, topic: "TestTopic"),
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

    PubNub(configuration: config, session: sessions.session)
      .removeAPNSPushDevice(for: hexData, on: "TestTopic") { result in
        switch result {
        case let .success(payload):
          XCTAssertEqual(payload.message, .acknowledge)
        case let .failure(error):
          XCTFail("Group List request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
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

    PubNub(configuration: config, session: sessions.session)
      .removeAPNSPushDevice(for: hexData, on: "TestTopic") { result in
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
