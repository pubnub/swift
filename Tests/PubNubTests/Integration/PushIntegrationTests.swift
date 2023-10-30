//
//  PushIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
import XCTest

import PubNub

class PushIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: PushIntegrationTests.self)
  let pushToken = Data(hexEncodedString: "7a043aa0085d31422cab58101d9237ad8ce6d77283d68639c6e71924c39fc5f8")

  let channel = "SwiftPushITest"
  let pushTopic = "SwiftPushITest"

  func testModifyChannels() {
    let addExpect = expectation(description: "Adding Channel")

    guard let token = pushToken else {
      return XCTFail("Could not create push data")
    }

    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))
    client.managePushChannelRegistrations(byRemoving: [], thenAdding: ["foo1", "foo2"], for: token) { result in
      switch result {
      case let .success(channels):

        print("Added APNS to \(channels)")

      case let .failure(error):
        print("Could not add APNS on channels: \(self.channel). ERROR: \(error.localizedDescription)")
      }
      addExpect.fulfill()
    }

    wait(for: [addExpect], timeout: 10.0)
  }

  func testListAPNSChannels() {
    let addExpect = expectation(description: "Adding Channel")
    let listExpect = expectation(description: "Listing Channels")

    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))

    guard let token = pushToken else {
      return XCTFail("Could not create push data")
    }

    // Add a channel
    client.manageAPNSDevicesOnChannels(
      byRemoving: [], thenAdding: [channel], device: token, on: pushTopic
    ) { [unowned self] result in

      // List Channels
      client.listAPNSPushChannelRegistrations(for: token, on: self.pushTopic) { result in
        switch result {
        case let .success(channels):
          XCTAssertEqual(channels.first, self.channel)
        case let .failure(error):
          XCTFail("List APNS call failed due to \(error.localizedDescription)")
        }
        listExpect.fulfill()
      }
      addExpect.fulfill()
    }

    wait(for: [addExpect, listExpect], timeout: 10.0)
  }

  func testRemoveAllAPNSChannels() {
    let addExpect = expectation(description: "Adding Channel")
    let removeAll = expectation(description: "Remove All Channel")
    let listExpect = expectation(description: "Listing Channels")

    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))

    guard let token = pushToken else {
      return XCTFail("Could not create push data")
    }

    // Add a channel
    client.manageAPNSDevicesOnChannels(
      byRemoving: [], thenAdding: [channel], device: token, on: pushTopic
    ) { [unowned self] result in
      client.removeAllAPNSPushDevice(for: token, on: self.pushTopic) { _ in
        client.listAPNSPushChannelRegistrations(for: token, on: self.pushTopic) { result in
          switch result {
          case let .success(channels):
            XCTAssertEqual(channels.isEmpty, true)
          case let .failure(error):
            XCTFail("List APNS call failed due to \(error.localizedDescription)")
          }
          listExpect.fulfill()
        }
        removeAll.fulfill()
      }
      addExpect.fulfill()
    }

    wait(for: [addExpect, removeAll, listExpect], timeout: 10.0)
  }
}
