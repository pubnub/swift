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
import PubNubSDK

class PushIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: PushIntegrationTests.self)
  let pushToken = Data(hexEncodedString: "7a043aa0085d31422cab58101d9237ad8ce6d77283d68639c6e71924c39fc5f8")!
  let channel = "SwiftPushITest"
  let pushTopic = "SwiftPushITest"

  func testModifyChannels() {
    let addExpect = expectation(description: "Adding Channel")
    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))
    
    client.managePushChannelRegistrations(
      byRemoving: [],
      thenAdding: ["foo1", "foo2"],
      for: pushToken
    ) { result in
      switch result {
      case let .success(channels):
        print("Added APNS to \(channels)")
      case let .failure(error):
        print("Could not add APNS on channels: \(self.channel). ERROR: \(error.localizedDescription)")
      }
      addExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeAllPushChannelRegistrations(
          for: pushToken,
          completion: $0
        )
      }
    }

    wait(for: [addExpect], timeout: 10.0)
  }

  func testListAPNSChannels() {
    let addExpect = expectation(description: "Adding Channel")
    let listExpect = expectation(description: "Listing Channels")
    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))

    // Add a channel
    client.manageAPNSDevicesOnChannels(
      byRemoving: [],
      thenAdding: [channel],
      device: pushToken,
      on: pushTopic
    ) { [unowned self, unowned client] result in
      // List Channels
      client.listAPNSPushChannelRegistrations(for: pushToken, on: pushTopic) { result in
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
    
    defer {
      waitForCompletion {
        client.removeAllAPNSPushDevice(
          for: pushToken,
          on: pushTopic,
          completion: $0
        )
      }
    }

    wait(for: [addExpect, listExpect], timeout: 10.0)
  }
  
  func testAddAPNSDevicesOnChannels() {
    let addExpect = expectation(description: "Adding Channel")
    let listExpect = expectation(description: "Listing Channels")
    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))

    // Add a channel
    client.addAPNSDevicesOnChannels(
      [channel],
      device: pushToken,
      on: pushTopic
    ) { [unowned self, unowned client] result in
      // List Channels
      client.listAPNSPushChannelRegistrations(for: pushToken, on: pushTopic) { result in
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
    
    defer {
      waitForCompletion {
        client.removeAllAPNSPushDevice(
          for: pushToken,
          on: pushTopic,
          completion: $0
        )
      }
    }

    wait(for: [addExpect, listExpect], timeout: 10.0)
  }

  func testRemoveAllAPNSChannels() {
    let addExpect = expectation(description: "Adding Channel")
    let removeAll = expectation(description: "Remove All Channel")
    let listExpect = expectation(description: "Listing Channels")
    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))

    // Add a channel
    client.manageAPNSDevicesOnChannels(
      byRemoving: [],
      thenAdding: [channel],
      device: pushToken,
      on: pushTopic
    ) { [unowned self, unowned client] result in
      client.removeAllAPNSPushDevice(for: pushToken, on: self.pushTopic) { _ in
        client.listAPNSPushChannelRegistrations(for: self.pushToken, on: self.pushTopic) { result in
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

  func testListPushChannelRegistrations() {
    let addExpect = expectation(description: "Adding Channel")
    let listExpect = expectation(description: "Listing Channels")
    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))

    // Add a channel
    client.managePushChannelRegistrations(
      byRemoving: [],
      thenAdding: [channel],
      for: pushToken
    ) { [unowned self, unowned client] result in
      // List Channels
      client.listPushChannelRegistrations(for: pushToken) { result in
        switch result {
        case let .success(channels):
          XCTAssertEqual(channels.first, self.channel)
        case let .failure(error):
          XCTFail("List push registrations call failed due to \(error.localizedDescription)")
        }
        listExpect.fulfill()
      }
      addExpect.fulfill()
    }
        
    defer {
      waitForCompletion {
        client.removeAllPushChannelRegistrations(
          for: pushToken,
          completion: $0
        )
      }
    }

    wait(for: [addExpect, listExpect], timeout: 10.0)
  }

  func testManageMultiplePushChannels() {
    let initialAddExpect = expectation(description: "Initial Channel Addition")
    let manageExpect = expectation(description: "Managing Channels")
    let listExpect = expectation(description: "Listing Channels")
    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))

    // First add initial channels
    client.managePushChannelRegistrations(
      byRemoving: [],
      thenAdding: ["c1", "c2", "c3", "c4"],
      for: pushToken
    ) { [unowned self, unowned client] result in
      // Then remove some and add new ones
      client.managePushChannelRegistrations(
        byRemoving: ["c1", "c2"],
        thenAdding: ["c5", "c6"],
        for: pushToken
      ) { result in
        // List final channels
        client.listPushChannelRegistrations(for: self.pushToken) { result in
          switch result {
          case let .success(channels):
            XCTAssertEqual(Set(channels), Set(["c3", "c4", "c5", "c6"]))
          case let .failure(error):
            XCTFail("List push registrations call failed due to \(error.localizedDescription)")
          }
          listExpect.fulfill()
        }
        manageExpect.fulfill()
      }
      initialAddExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeAllPushChannelRegistrations(
          for: pushToken,
          completion: $0
        )
      }
    }

    wait(for: [initialAddExpect, manageExpect, listExpect], timeout: 10.0)
  }

  func testManageMultipleAPNSChannels() {
    let initialAddExpect = expectation(description: "Initial Channel Addition")
    let manageExpect = expectation(description: "Managing Channels")
    let listExpect = expectation(description: "Listing Channels")
    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))

    // First add initial channels
    client.manageAPNSDevicesOnChannels(
      byRemoving: [],
      thenAdding: ["c1", "c2", "c3", "c4"],
      device: pushToken,
      on: pushTopic
    ) { [unowned self, unowned client] result in
      // Then remove some and add new ones
      client.manageAPNSDevicesOnChannels(
        byRemoving: ["c1", "c2"],
        thenAdding: ["c5", "c6"],
        device: pushToken,
        on: pushTopic
      ) { result in
        // List final channels
        client.listAPNSPushChannelRegistrations(for: self.pushToken, on: self.pushTopic) { result in
          switch result {
          case let .success(channels):
            XCTAssertEqual(Set(channels), Set(["c3", "c4", "c5", "c6"]))
          case let .failure(error):
            XCTFail("List APNS call failed due to \(error.localizedDescription)")
          }
          listExpect.fulfill()
        }
        manageExpect.fulfill()
      }
      initialAddExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeAllAPNSPushDevice(
          for: pushToken,
          on: pushTopic,
          completion: $0
        )
      }
    }

    wait(for: [initialAddExpect, manageExpect, listExpect], timeout: 10.0)
  }

  func testRemovePushChannelRegistrations() {
    let addExpect = expectation(description: "Adding Channels")
    let removeExpect = expectation(description: "Removing Channels")
    let listExpect = expectation(description: "Listing Channels")
    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))

    // First add channels
    client.managePushChannelRegistrations(
      byRemoving: [],
      thenAdding: ["c1", "c2", "c3"],
      for: pushToken
    ) { [unowned self, unowned client] result in
      // Then remove specific channels
      client.removePushChannelRegistrations(["c1", "c2"], for: pushToken) { result in
        // List remaining channels
        client.listPushChannelRegistrations(for: self.pushToken) { result in
          switch result {
          case let .success(channels):
            XCTAssertEqual(Set(channels), Set(["c3"]))
          case let .failure(error):
            XCTFail("List push registrations call failed due to \(error.localizedDescription)")
          }
          listExpect.fulfill()
        }
        removeExpect.fulfill()
      }
      addExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeAllPushChannelRegistrations(
          for: pushToken,
          completion: $0
        )
      }
    }

    wait(for: [addExpect, removeExpect, listExpect], timeout: 10.0)
  }

  func testAddPushChannelRegistrations() {
    let addExpect = expectation(description: "Adding Channels")
    let listExpect = expectation(description: "Listing Channels")
    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))

    // Add multiple channels at once
    client.addPushChannelRegistrations(["c1", "c2", "c3"], for: pushToken) { [unowned self, unowned client] result in
      // List added channels
      client.listPushChannelRegistrations(for: pushToken) { result in
        switch result {
        case let .success(channels):
          XCTAssertEqual(Set(channels), Set(["c1", "c2", "c3"]))
        case let .failure(error):
          XCTFail("List push registrations call failed due to \(error.localizedDescription)")
        }
        listExpect.fulfill()
      }
      addExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeAllPushChannelRegistrations(
          for: pushToken,
          completion: $0
        )
      }
    }

    wait(for: [addExpect, listExpect], timeout: 10.0)
  }

  func testRemoveAllPushChannelRegistrations() {
    let addExpect = expectation(description: "Adding Channels")
    let removeAllExpect = expectation(description: "Removing All Channels")
    let listExpect = expectation(description: "Listing Channels")
    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))

    // First add some channels
    client.managePushChannelRegistrations(
      byRemoving: [],
      thenAdding: ["c1", "c2", "c3"],
      for: pushToken
    ) { [unowned self, unowned client] result in
      // Then remove all channels
      client.removeAllPushChannelRegistrations(for: pushToken) { result in
        // List remaining channels (should be empty)
        client.listPushChannelRegistrations(for: self.pushToken) { result in
          switch result {
          case let .success(channels):
            XCTAssertTrue(channels.isEmpty)
          case let .failure(error):
            XCTFail("List push registrations call failed due to \(error.localizedDescription)")
          }
          listExpect.fulfill()
        }
        removeAllExpect.fulfill()
      }
      addExpect.fulfill()
    }

    wait(for: [addExpect, removeAllExpect, listExpect], timeout: 10.0)
  }

  func testRemoveAPNSDevicesOnChannels() {
    let addExpect = expectation(description: "Adding Channels")
    let removeExpect = expectation(description: "Removing Channels")
    let listExpect = expectation(description: "Listing Channels")
    let client = PubNub(configuration: PubNubConfiguration(from: testsBundle))

    // First add some channels
    client.manageAPNSDevicesOnChannels(
      byRemoving: [],
      thenAdding: ["c1", "c2", "c3"],
      device: pushToken,
      on: pushTopic
    ) { [unowned self, unowned client] result in
      // Then remove specific channels
      client.removeAPNSDevicesOnChannels(
        ["c1", "c2"],
        device: pushToken,
        on: pushTopic
      ) { result in
        // List remaining channels
        client.listAPNSPushChannelRegistrations(for: self.pushToken, on: self.pushTopic) { result in
          switch result {
          case let .success(channels):
            XCTAssertEqual(Set(channels), Set(["c3"]))
          case let .failure(error):
            XCTFail("List APNS call failed due to \(error.localizedDescription)")
          }
          listExpect.fulfill()
        }
        removeExpect.fulfill()
      }
      addExpect.fulfill()
    }
    
    defer {
      waitForCompletion {
        client.removeAllAPNSPushDevice(
          for: pushToken,
          on: pushTopic,
          completion: $0
        )
      }
    }

    wait(for: [addExpect, removeExpect, listExpect], timeout: 10.0)
  }
}
