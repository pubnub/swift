//
//  PushIntegrationTests.swift
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
