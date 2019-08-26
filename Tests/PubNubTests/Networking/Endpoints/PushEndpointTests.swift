//
//  PushEndpointTests.swift
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

final class PushEndpointTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  let testChannels = ["TestChannel", "OtherChannel"]

  let hexString = "815ee724ccb0a6a84dc303be8ccbaa00d1c84dde6bcae6721b08f92100951113"

  // MARK: - List Push Channels

  func testListPushProvisions_Endpoint() {
    guard let data = Data(hexEncodedString: "A1B2") else {
      return XCTFail("Could not encode Data from hex string")
    }
    let endpoint = Endpoint.listPushChannels(pushToken: data, pushType: .apns)

    XCTAssertEqual(endpoint.description, "List Push Channels")
    XCTAssertEqual(endpoint.rawValue, .listPushChannels)
    XCTAssertEqual(endpoint.operationCategory, .push)
    XCTAssertNil(endpoint.validationError)
  }

  func testListPushProvisions_Endpoint_ValidationError() {
    let endpoint = Endpoint.listPushChannels(pushToken: Data(), pushType: .apns)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PNError.invalidEndpointType(endpoint))
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
          guard let task = sessions.mockSession.tasks.first else {
            return XCTFail("Could not get task")
          }

          let countExceededError = PNError.convert(endpoint: .unknown,
                                                   generalError: .init(message: .pushNotEnabled,
                                                                       service: .unknown(message: ""),
                                                                       status: .forbidden,
                                                                       error: true),
                                                   request: task.mockRequest,
                                                   response: task.mockResponse)

          XCTAssertEqual(error.pubNubError, countExceededError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Modify Push Channels Tests

  func testModifyPushChannels_Endpoint() {
    guard let data = Data(hexEncodedString: "A1B2") else {
      return XCTFail("Could not encode Data from hex string")
    }
    let endpoint = Endpoint.modifyPushChannels(pushToken: data,
                                               pushType: .apns,
                                               addChannels: testChannels,
                                               removeChannels: [])

    XCTAssertEqual(endpoint.description, "Modify Push Channels")
    XCTAssertEqual(endpoint.rawValue, .modifyPushChannels)
    XCTAssertEqual(endpoint.operationCategory, .push)
    XCTAssertNil(endpoint.validationError)
  }

  func testListModifyPushChannels_Endpoint_ValidationError() {
    let endpoint = Endpoint.modifyPushChannels(pushToken: Data(),
                                               pushType: .apns,
                                               addChannels: [],
                                               removeChannels: [])

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PNError.invalidEndpointType(endpoint))
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
          guard let task = sessions.mockSession.tasks.first else {
            return XCTFail("Could not get task")
          }

          let countExceededError = PNError.convert(endpoint: .unknown,
                                                   generalError: .init(message: .pushNotEnabled,
                                                                       service: .unknown(message: ""),
                                                                       status: .forbidden,
                                                                       error: true),
                                                   request: task.mockRequest,
                                                   response: task.mockResponse)

          XCTAssertEqual(error.pubNubError, countExceededError)
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
          guard let task = sessions.mockSession.tasks.first else {
            return XCTFail("Could not get task")
          }

          let countExceededError = PNError.convert(endpoint: .unknown,
                                                   generalError: .init(message: .invalidDeviceToken,
                                                                       service: .unknown(message: ""),
                                                                       status: .badRequest,
                                                                       error: true),
                                                   request: task.mockRequest,
                                                   response: task.mockResponse)

          XCTAssertEqual(error.pubNubError, countExceededError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - Remove All Push Channels Tests

  func testRemoveAllPushChannels_Endpoint() {
    guard let data = Data(hexEncodedString: "A1B2") else {
      return XCTFail("Could not encode Data from hex string")
    }
    let endpoint = Endpoint.removeAllPushChannels(pushToken: data, pushType: .apns)

    XCTAssertEqual(endpoint.description, "Remove All Push Channels")
    XCTAssertEqual(endpoint.rawValue, .removeAllPushChannels)
  }

  func testRemoveAllPushChannels_Endpoint_ValidationError() {
    let endpoint = Endpoint.removeAllPushChannels(pushToken: Data(), pushType: .apns)

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PNError.invalidEndpointType(endpoint))
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
