//
//  DataSyncChannelEndpointIntegrationTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import XCTest

class DataSyncChannelEndpointIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: DataSyncChannelEndpointIntegrationTests.self)
  let channelClassVersion = 1

  func testCreateAndFetchChannel() {
    let fetchExpect = expectation(description: "Fetch Channel Expectation")
    let client = PubNub(configuration: dataSyncConfiguration())
    let channelId = randomString()

    let payload = TestChannelPayload(
      name: "Swift ITest Channel",
      channelDescription: "Created by the Swift integration tests"
    )

    client.dataSync.createChannel(
      classVersion: channelClassVersion,
      id: channelId,
      status: "active",
      payload: payload
    ) { [unowned client] createResult in
      switch createResult {
      case let .success(createdChannel):
        XCTAssertEqual(createdChannel.id, channelId)
        XCTAssertFalse(createdChannel.eTag.isEmpty)

        client.dataSync.getChannel(channelId) { fetchResult in
          switch fetchResult {
          case let .success(channel):
            XCTAssertEqual(channel.id, channelId)
            XCTAssertEqual(channel.status, "active")
            XCTAssertEqual(channel.classVersion, self.channelClassVersion)
            XCTAssertEqual(channel.eTag, createdChannel.eTag)
            XCTAssertPayload(channel.payload, equals: payload)
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          fetchExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        fetchExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.dataSync.removeChannel(
          channelId,
          completion: $0
        )
      }
    }

    wait(for: [fetchExpect], timeout: 10.0)
  }

  func testReplaceChannelReplacesPayloadWholesale() {
    let replaceExpect = expectation(description: "Replace Channel Expectation")
    let client = PubNub(configuration: dataSyncConfiguration())
    let channelId = randomString()

    client.dataSync.createChannel(
      classVersion: channelClassVersion,
      id: channelId,
      status: "active",
      payload: TestChannelPayload(name: "Swift ITest Channel", channelDescription: "Channel description")
    ) { [unowned client] createResult in
      switch createResult {
      case let .success(createdChannel):
        // The replacement omits `description`, which must therefore be cleared rather than preserved
        let replacementPayload = TestChannelPayload(name: "Swift ITest Channel Renamed")

        client.dataSync.replaceChannel(
          channelId,
          classVersion: self.channelClassVersion,
          status: "archived",
          payload: replacementPayload
        ) { replaceResult in
          switch replaceResult {
          case let .success(replacedChannel):
            XCTAssertEqual(replacedChannel.id, channelId)
            XCTAssertEqual(replacedChannel.status, "archived")
            XCTAssertPayload(replacedChannel.payload, equals: replacementPayload)
            XCTAssertNotEqual(replacedChannel.eTag, createdChannel.eTag)
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          replaceExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        replaceExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.dataSync.removeChannel(
          channelId,
          completion: $0
        )
      }
    }

    wait(for: [replaceExpect], timeout: 10.0)
  }

  func testPatchChannelAppliesOperationsAndKeepsUntouchedFields() {
    let patchExpect = expectation(description: "Patch Channel Expectation")
    let client = PubNub(configuration: dataSyncConfiguration())
    let channelId = randomString()

    client.dataSync.createChannel(
      classVersion: channelClassVersion,
      id: channelId,
      status: "inactive",
      payload: TestChannelPayload(
        name: "Swift ITest Channel",
        channelDescription: "Channel description"
      )
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        let expectedPayload = TestChannelPayload(
          name: "Swift ITest Channel",
          channelDescription: nil,
          topic: "integration-testing"
        )

        client.dataSync.patchChannel(
          channelId,
          operations: [
            .remove(path: "/payload/channelDescription"),
            .add(path: "/payload/topic", value: "integration-testing")
          ]
        ) { patchResult in
          switch patchResult {
          case let .success(patchedChannel):
            XCTAssertEqual(patchedChannel.status, "inactive")
            XCTAssertPayload(patchedChannel.payload, equals: expectedPayload)
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
          }
          patchExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        patchExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.dataSync.removeChannel(
          channelId,
          completion: $0
        )
      }
    }

    wait(for: [patchExpect], timeout: 10.0)
  }

  func testReplaceChannelWithStaleEtagFails() {
    let replaceExpect = expectation(description: "Replace Channel Expectation")
    let client = PubNub(configuration: dataSyncConfiguration())
    let channelId = randomString()

    client.dataSync.createChannel(
      classVersion: channelClassVersion,
      id: channelId,
      status: "active",
      payload: TestChannelPayload(
        name: "Swift ITest Channel",
        channelDescription: "Channel description"
      )
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        client.dataSync.replaceChannel(
          channelId,
          classVersion: self.channelClassVersion,
          status: "archived",
          payload: TestChannelPayload(name: "Swift ITest Channel Renamed"),
          ifMatchesEtag: "stale-etag"
        ) { replaceResult in
          switch replaceResult {
          case .success:
            XCTFail("Test should fail")
          case let .failure(error):
            XCTAssertNotNil(error.pubNubError)
            XCTAssertEqual(error.pubNubError?.reason, .preconditionFailed)
          }
          replaceExpect.fulfill()
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        replaceExpect.fulfill()
      }
    }

    defer {
      waitForCompletion {
        client.dataSync.removeChannel(
          channelId,
          completion: $0
        )
      }
    }

    wait(for: [replaceExpect], timeout: 10.0)
  }

  func testGetChannelsReturnsCreatedChannels() {
    let listExpect = expectation(description: "List Channels Expectation")
    let client = PubNub(configuration: dataSyncConfiguration())
    let channelIds = [randomString(), randomString(), randomString()]

    createChannels(
      client: client,
      channelIds: channelIds
    )

    client.dataSync.getChannels { result in
      switch result {
      case let .success((channels, _)):
        let fetchedIds = Set(channels.map { $0.id })
        XCTAssertTrue(Set(channelIds).isSubset(of: fetchedIds))
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      for channelId in channelIds {
        waitForCompletion {
          client.dataSync.removeChannel(
            channelId,
            completion: $0
          )
        }
      }
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testGetChannelsPagesWithCursor() {
    let listExpect = expectation(description: "List Channels Expectation")
    let client = PubNub(configuration: dataSyncConfiguration())
    let channelIds = [randomString(), randomString()]

    createChannels(
      client: client,
      channelIds: channelIds
    )

    client.dataSync.getChannels(limit: 1) { firstResult in
      switch firstResult {
      case let .success((firstPage, next)):
        XCTAssertEqual(firstPage.count, 1)
        XCTAssertEqual(next?.limit, 1)
        XCTAssertNotNil(next?.cursor)
        XCTAssertTrue(next?.hasNext ?? false)
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      listExpect.fulfill()
    }

    defer {
      for channelId in channelIds {
        waitForCompletion {
          client.dataSync.removeChannel(
            channelId,
            completion: $0
          )
        }
      }
    }

    wait(for: [listExpect], timeout: 20.0)
  }

  func testRemoveChannelThenFetchFails() {
    let removeExpect = expectation(description: "Remove Channel Expectation")
    let client = PubNub(configuration: dataSyncConfiguration())
    let channelId = randomString()

    client.dataSync.createChannel(
      classVersion: channelClassVersion,
      id: channelId,
      status: "active",
      payload: TestChannelPayload(
        name: "Swift ITest Channel",
        channelDescription: "Created by the Swift integration tests"
      )
    ) { [unowned client] createResult in
      switch createResult {
      case .success:
        client.dataSync.removeChannel(channelId) { removeResult in
          switch removeResult {
          case .success:
            client.dataSync.getChannel(channelId) { fetchResult in
              switch fetchResult {
              case .success:
                XCTFail("Test should fail")
              case let .failure(error):
                XCTAssertNotNil(error.pubNubError)
                XCTAssertEqual(error.pubNubError?.reason, .resourceNotFound)
              }
              removeExpect.fulfill()
            }
          case let .failure(error):
            XCTFail("Failed due to error: \(error)")
            removeExpect.fulfill()
          }
        }
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
        removeExpect.fulfill()
      }
    }

    // No cleanup: removing the channel is the subject of this test
    wait(for: [removeExpect], timeout: 10.0)
  }
}

// MARK: - Test Data

private struct TestChannelPayload: JSONCodable, Equatable {
  let name: String?
  let channelDescription: String?
  let topic: String?

  init(name: String? = nil, channelDescription: String? = nil, topic: String? = nil) {
    self.name = name
    self.channelDescription = channelDescription
    self.topic = topic
  }
}

private extension DataSyncChannelEndpointIntegrationTests {
  func dataSyncConfiguration() -> PubNubConfiguration {
    PubNubConfiguration(
      publishKey: PubNubConfiguration(bundle: testsBundle).publishKey,
      subscribeKey: PubNubConfiguration(bundle: testsBundle).subscribeKey,
      userId: randomString(),
      authToken: dataSyncUserChannelMembershipAuthToken
    )
  }

  func createChannels(client: PubNub, channelIds: [String]) {
    let setupExpect = expectation(description: "Create Test Channels Expectation")
    setupExpect.expectedFulfillmentCount = 1
    setupExpect.assertForOverFulfill = true

    func createNext(_ remainingIds: [String]) {
      guard let channelId = remainingIds.first else {
        setupExpect.fulfill(); return
      }

      client.dataSync.createChannel(
        classVersion: channelClassVersion,
        id: channelId,
        status: "active",
        payload: TestChannelPayload(
          name: channelId,
          channelDescription: "Created by the Swift integration tests"
        )
      ) { result in
        switch result {
        case .success:
          createNext(Array(remainingIds.dropFirst()))
        case let .failure(error):
          XCTFail("Failed to setup test channel \(channelId): \(error)")
        }
      }
    }

    createNext(channelIds)

    wait(for: [setupExpect], timeout: 15.0)
  }
}
