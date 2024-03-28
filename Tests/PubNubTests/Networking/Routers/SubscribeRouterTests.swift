//
//  SubscribeRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest

@testable import PubNub

final class SubscribeRouterTests: XCTestCase {
  let config = PubNubConfiguration(
    publishKey: "FakeTestString",
    subscribeKey: "FakeTestString",
    userId: UUID().uuidString,
    enableEventEngine: false
  )
  let eeEnabledConfig = PubNubConfiguration(
    publishKey: "FakeTestString",
    subscribeKey: "FakeTestString",
    userId: UUID().uuidString,
    enableEventEngine: true
  )
  let testAction = PubNubMessageActionBase(
    actionType: "reaction", actionValue: "winky_face",
    actionTimetoken: 15_725_459_793_173_220, messageTimetoken: 15_725_459_448_096_144,
    publisher: "SomeUser", channel: "TestChannel", published: 15_725_459_794_105_070
  )
  let testChannel = "TestChannel"
  
  // MARK: - Endpoint Tests
  
  func testSubscribe_Router() {
    let router = SubscribeRouter(.subscribe(
      channels: ["TestChannel"], groups: [], channelStates: [:],
      timetoken: 0, region: nil, heartbeat: nil, filter: nil
    ), configuration: config)
    
    XCTAssertEqual(router.endpoint.description, "Subscribe")
    XCTAssertEqual(router.category, "Subscribe")
    XCTAssertEqual(router.service, .subscribe)
  }
  
  func testSubscribe_Router_ValidationError() {
    let router = SubscribeRouter(.subscribe(
      channels: [], groups: [], channelStates: [:],
      timetoken: 0, region: nil, heartbeat: nil, filter: nil
    ), configuration: config)
    
    XCTAssertNotEqual(
      router.validationError?.pubNubError,
      PubNubError(.invalidEndpointType, router: router)
    )
  }
}

// MARK: - Subscribe Query Params

extension SubscribeRouterTests {
  func testSubscribeRouter_QueryParamsWithEventEngineEnabled() {
    let config = PubNubConfiguration(
      publishKey: "FakeTestString",
      subscribeKey: "FakeTestString",
      userId: "someId",
      enableEventEngine: true,
      maintainPresenceState: true
    )
    let channelStates: [String: JSONCodable] = [
      "c1": ["x": 1],
      "c2": ["a": "someText"]
    ]
    let endpoint = SubscribeRouter.Endpoint.subscribe(
      channels: ["c1"], groups: ["group-1", "group-2"], channelStates: channelStates,
      timetoken: 123456, region: "42", heartbeat: 30, filter: nil
    )
    let router = SubscribeRouter(
      endpoint,
      configuration: config
    )
    
    // There's no guaranteed order of returned states.
    // Therefore, these are two possible and valid combinations:
    let expStateValues = [
      "{\"c1\":{\"x\":1},\"c2\":{\"a\":\"someText\"}}",
      "{\"c2\":{\"a\":\"someText\"},\"c1\":{\"x\":1}}"
    ]
    let queryItems = (try? router.queryItems.get()) ?? []
    
    XCTAssertTrue(queryItems.count == 8)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value == "30" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value == "group-1,group-2" })
    XCTAssertTrue(queryItems.contains { $0.name == "tt" && $0.value == "123456" })
    XCTAssertTrue(queryItems.contains { $0.name == "tr" && $0.value == "42" })
    XCTAssertTrue(queryItems.contains { $0.name == "ee" && $0.value == nil })
    XCTAssertTrue(queryItems.contains { $0.name == "state" && expStateValues.contains($0.value!) })
  }
  
  func testSubscribeRouter_QueryParamsWithEventEngineDisabled() {
    let config = PubNubConfiguration(
      publishKey: "FakeTestString",
      subscribeKey: "FakeTestString",
      userId: "someId",
      enableEventEngine: false,
      maintainPresenceState: true
    )
    let channelStates: [String: JSONCodable] = [
      "c1": ["x": 1],
      "c2": ["a": "someText"]
    ]
    let endpoint = SubscribeRouter.Endpoint.subscribe(
      channels: ["c1"], groups: ["group-1", "group-2"], channelStates: channelStates,
      timetoken: 123456, region: "42", heartbeat: 30, filter: nil
    )
    
    let router = SubscribeRouter(endpoint, configuration: config)
    let queryItems = (try? router.queryItems.get()) ?? []
    
    XCTAssertTrue(queryItems.count == 6)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value == "30" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value == "group-1,group-2" })
    XCTAssertTrue(queryItems.contains { $0.name == "tt" && $0.value == "123456" })
    XCTAssertTrue(queryItems.contains { $0.name == "tr" && $0.value == "42" })
  }
  
  func testSubscribeRouter_QueryParamsWithMaintainPresenceStateDisabled() {
    let config = PubNubConfiguration(
      publishKey: "FakeTestString",
      subscribeKey: "FakeTestString",
      userId: "someId",
      enableEventEngine: true,
      maintainPresenceState: false
    )
    let channelStates: [String: JSONCodable] = [
      "c1": ["x": 1],
      "c2": ["a": "someText"]
    ]
    let endpoint = SubscribeRouter.Endpoint.subscribe(
      channels: ["c1"], groups: ["group-1", "group-2"], channelStates: channelStates,
      timetoken: 123456, region: "42", heartbeat: 30, filter: nil
    )
    
    let router = SubscribeRouter(endpoint, configuration: config)
    let queryItems = (try? router.queryItems.get()) ?? []
    
    XCTAssertTrue(queryItems.count == 7)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value == "30" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value == "group-1,group-2" })
    XCTAssertTrue(queryItems.contains { $0.name == "tt" && $0.value == "123456" })
    XCTAssertTrue(queryItems.contains { $0.name == "tr" && $0.value == "42" })
    XCTAssertTrue(queryItems.contains { $0.name == "ee" && $0.value == nil })
  }
  
  func testSubscribeRouter_QueryParamsWithEmptyPresenceStates() {
    let config = PubNubConfiguration(
      publishKey: "FakeTestString",
      subscribeKey: "FakeTestString",
      userId: "someId",
      enableEventEngine: true,
      maintainPresenceState: true
    )
    let endpoint = SubscribeRouter.Endpoint.subscribe(
      channels: ["c1"], groups: ["group-1", "group-2"], channelStates: [:],
      timetoken: 123456, region: "42", heartbeat: 30, filter: nil
    )
    let router = SubscribeRouter(endpoint, configuration: config)
    let queryItems = (try? router.queryItems.get()) ?? []
    
    XCTAssertTrue(queryItems.count == 7)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value == "30" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value == "group-1,group-2" })
    XCTAssertTrue(queryItems.contains { $0.name == "tt" && $0.value == "123456" })
    XCTAssertTrue(queryItems.contains { $0.name == "tr" && $0.value == "42" })
    XCTAssertTrue(queryItems.contains { $0.name == "ee" && $0.value == nil })
  }
}

// MARK: - Mock HTTP session

fileprivate extension SubscribeRouterTests {
  typealias MockResult = (
    subscriptionSession: SubscriptionSession,
    listener: SubscriptionListener
  )
  
  func mockSubscriptionSession(
    with responses: [String],
    raw dataResource: [Data] = [],
    and configuration: PubNubConfiguration
  ) -> MockResult {
    // Creates a container to resolve SubscriptionSession
    let container = DependencyContainer(configuration: configuration)
    let listener = SubscriptionListener()
    
    // Registers mock URL session before retrieving SubscriptionSession
    container.register(
      value: try! MockURLSession.mockSession(for: responses, raw: dataResource).session!,
      forKey: HTTPSubscribeSessionDependencyKey.self
    )
    
    // Adds a single listener and returns the output to perform further tests
    let resolvedSession = container.subscriptionSession
    resolvedSession.add(listener)
    
    return MockResult(
      subscriptionSession: resolvedSession,
      listener: listener
    )
  }
}

// MARK: - Message Response

extension SubscribeRouterTests {
  func testSubscribe_Message() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let messageExpect = XCTestExpectation(description: "Message Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        let mockResponses = ["subscription_handshake_success", "subscription_message_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        
        mockResult.listener.didReceiveMessage = { [weak self, mockResult] message in
          XCTAssertEqual(message.channel, self?.testChannel)
          XCTAssertEqual(message.payload.stringOptional, "Test Message")
          mockResult.subscriptionSession.unsubscribeAll()
          messageExpect.fulfill()
        }
        mockResult.listener.didReceiveStatus = { status in
          if let status = try? status.get(), status == .disconnected {
            statusExpect.fulfill()
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [messageExpect, statusExpect], timeout: 1.0)
      }
    }
  }
}

// MARK: - Presence Response

extension SubscribeRouterTests {
  func testSubscribe_Presence() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let mockResponses = ["subscription_handshake_success", "subscription_presence_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        let presenceExpect = XCTestExpectation(description: "Presence Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        
        mockResult.listener.didReceivePresence = { [weak self, mockResult] presence in
          XCTAssertEqual(presence.channel, self?.testChannel)
          XCTAssertEqual(presence.actions, [
            .join(uuids: ["db9c5e39-7c95-40f5-8d71-125765b6f561", "vqwqvae39-7c95-40f5-8d71-25234165142"]),
            .leave(uuids: ["234vq2343-7c95-40f5-8d71-125765b6f561", "42vvsge39-7c95-40f5-8d71-25234165142"])
          ])
          mockResult.subscriptionSession.unsubscribeAll()
          presenceExpect.fulfill()
        }
        mockResult.listener.didReceiveStatus = { status in
          if let status = try? status.get(), status == .disconnected {
            statusExpect.fulfill()
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [presenceExpect, statusExpect], timeout: 1.0)
      }
    }
  }
}

// MARK: - Signal Response

extension SubscribeRouterTests {
  func testSubscribe_Signal() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let mockResponses = ["subscription_handshake_success", "subscription_signal_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        let signalExpect = XCTestExpectation(description: "Signal Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        
        mockResult.listener.didReceiveSignal = { [weak self, mockResult] signal in
          XCTAssertEqual(signal.channel, self?.testChannel)
          XCTAssertEqual(signal.publisher, "TestUser")
          XCTAssertEqual(signal.payload.stringOptional, "Test Signal")
          mockResult.subscriptionSession.unsubscribeAll()
          signalExpect.fulfill()
        }
        mockResult.listener.didReceiveStatus = { status in
          if let status = try? status.get(), status == .disconnected {
            statusExpect.fulfill()
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [signalExpect, statusExpect], timeout: 1.0)
      }
    }
  }
}

// MARK: - User Object Response

extension SubscribeRouterTests {
  // swiftlint:disable:next function_body_length cyclomatic_complexity
  func testSubscribe_UUIDMetadata_Set() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let mockResponses = ["subscription_handshake_success", "subscription_uuidSet_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        let objectExpect = XCTestExpectation(description: "Object Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")
        
        let baseUser = PubNubUUIDMetadataBase(
          metadataId: "TestUserID",
          name: "Not Real Name"
        )
        let patchedObjectUser = PubNubUUIDMetadataBase(
          metadataId: "TestUserID",
          name: "Test Name", type: "Test Type", status: "Test Status",
          updated: DateFormatter.iso8601.date(from: "2019-10-06T01:55:50.645685Z"),
          eTag: "UserUpdateEtag"
        )
        
        mockResult.listener.didReceiveSubscription = { event in
          switch event {
          case let .connectionStatusChanged(status):
            if status == .disconnected {
              statusExpect.fulfill()
            }
          case let .uuidMetadataSet(changeset):
            XCTAssertEqual(try? changeset.apply(to: baseUser).transcode(), patchedObjectUser)
            objectExpect.fulfill()
          case let .subscriptionChanged(change):
            switch change {
            case let .subscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self.testChannel)
            case .responseHeader:
              break
            case let .unsubscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self.testChannel)
            }
          default:
            XCTFail("Incorrect Event Received \(event)")
          }
        }
        mockResult.listener.didReceiveObjectMetadataEvent = { [mockResult] event in
          switch event {
          case let .setUUID(changeset):
            XCTAssertEqual(changeset.metadataId, "TestUserID")
            mockResult.subscriptionSession.unsubscribeAll()
            objectListenerExpect.fulfill()
          default:
            XCTFail("Incorrect Event Received")
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
      }
    }
  }
  
  // swiftlint:disable:next cyclomatic_complexity
  func testSubscribe_UUIDMetadata_Removed() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let objectExpect = XCTestExpectation(description: "Object Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")
        let mockResponses = ["subscription_handshake_success", "subscription_uuidRemove_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        
        mockResult.listener.didReceiveSubscription = { event in
          switch event {
          case let .connectionStatusChanged(status):
            if status == .disconnected {
              statusExpect.fulfill()
            }
          case let .uuidMetadataRemoved(metadataId):
            XCTAssertEqual(metadataId, "TestUserID")
            objectExpect.fulfill()
          case let .subscriptionChanged(change):
            switch change {
            case let .subscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self.testChannel)
            case .responseHeader:
              break
            case let .unsubscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self.testChannel)
            }
          default:
            XCTFail("Incorrect Event Received")
          }
        }
        mockResult.listener.didReceiveObjectMetadataEvent = { [mockResult] event in
          switch event {
          case let .removedUUID(metadataId):
            XCTAssertEqual(metadataId, "TestUserID")
            mockResult.subscriptionSession.unsubscribeAll()
            objectListenerExpect.fulfill()
          default:
            XCTFail("Incorrect Event Received")
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
      }
    }
  }
  
  // swiftlint:disable:next function_body_length
  func testSubscribe_ChannelMetadata_Set() {
    for configuration in [config, eeEnabledConfig] {
      let mockResponses = ["subscription_handshake_success", "subscription_channelSet_success", "cancelled"]
      let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
      
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let objectExpect = XCTestExpectation(description: "Object Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")
        
        let baseChannel = PubNubChannelMetadataBase(
          metadataId: "TestSpaceID",
          name: "Not Real Name",
          type: "someType"
        )
        let patchedChannel = PubNubChannelMetadataBase(
          metadataId: "TestSpaceID",
          name: "Test Name",
          type: "Test Type", status: "Test Status",
          updated: DateFormatter.iso8601.date(from: "2019-10-06T01:55:50.645685Z"),
          eTag: "SpaceUpdateEtag"
        )
        
        mockResult.listener.didReceiveSubscription = { event in
          switch event {
          case let .connectionStatusChanged(status):
            if status == .disconnected {
              statusExpect.fulfill()
            }
          case let .channelMetadataSet(changeset):
            XCTAssertEqual(try? changeset.apply(to: baseChannel).transcode(), patchedChannel)
            objectExpect.fulfill()
          case let .subscriptionChanged(change):
            break
          default:
            XCTFail("Incorrect Event Received")
          }
        }
        mockResult.listener.didReceiveObjectMetadataEvent = { [mockResult] event in
          switch event {
          case let .setChannel(changeset):
            XCTAssertEqual(changeset.metadataId, "TestSpaceID")
            mockResult.subscriptionSession.unsubscribeAll()
            objectListenerExpect.fulfill()
          default:
            XCTFail("Incorrect Event Received")
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
      }
    }
  }
  
  // swiftlint:disable:next cyclomatic_complexity
  func testSubscribe_ChannelMetadata_Removed() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let mockResponses = ["subscription_handshake_success", "subscription_channelRemove_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        let objectExpect = XCTestExpectation(description: "Object Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")
        
        mockResult.listener.didReceiveSubscription = { event in
          switch event {
          case let .connectionStatusChanged(status):
            if status == .disconnected {
              statusExpect.fulfill()
            }
          case let .channelMetadataRemoved(metadataId):
            XCTAssertEqual(metadataId, "TestSpaceID")
            objectExpect.fulfill()
          case let .subscriptionChanged(change):
            switch change {
            case let .subscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self.testChannel)
            case .responseHeader:
              break
            case let .unsubscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self.testChannel)
            }
          default:
            XCTFail("Incorrect Event Received")
          }
        }
        mockResult.listener.didReceiveObjectMetadataEvent = { [mockResult] event in
          switch event {
          case let .removedChannel(metadataId: metadataId):
            XCTAssertEqual(metadataId, "TestSpaceID")
            mockResult.subscriptionSession.unsubscribeAll()
            objectListenerExpect.fulfill()
          default:
            XCTFail("Incorrect Event Received")
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
      }
    }
  }
  
  // swiftlint:disable:next function_body_length cyclomatic_complexity
  func testSubscribe_Membership_Set() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let mockResponses = ["subscription_handshake_success", "subscription_membershipSet_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        let objectExpect = XCTestExpectation(description: "Object Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")
        
        let channel = PubNubChannelMetadataBase(metadataId: "TestSpaceID")
        let uuid = PubNubUUIDMetadataBase(metadataId: "TestUserID")
        
        let testMembership = PubNubMembershipMetadataBase(
          uuidMetadataId: "TestUserID",
          channelMetadataId: "TestSpaceID",
          uuid: uuid, channel: channel,
          custom: ["something": true],
          updated: DateFormatter.iso8601.date(from: "2019-10-05T23:35:38.457823306Z"), eTag: "TestETag"
        )
        
        mockResult.listener.didReceiveSubscription = { [unowned self] event in
          switch event {
          case let .connectionStatusChanged(status):
            if status == .disconnected {
              statusExpect.fulfill()
            }
          case let .membershipMetadataSet(membership):
            XCTAssertEqual(try? membership.transcode(), testMembership)
            objectExpect.fulfill()
          case let .subscriptionChanged(change):
            switch change {
            case let .subscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self.testChannel)
            case .responseHeader:
              break
            case let .unsubscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self.testChannel)
            }
          default:
            XCTFail("Incorrect Event Received \(event)")
          }
        }
        mockResult.listener.didReceiveObjectMetadataEvent = { [mockResult] event in
          switch event {
          case let .setMembership(membership):
            XCTAssertEqual(try? membership.transcode(), testMembership)
            mockResult.subscriptionSession.unsubscribeAll()
            objectListenerExpect.fulfill()
          default:
            XCTFail("Incorrect Event Received \(event)")
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
      }
    }
  }
  
  // swiftlint:disable:next function_body_length cyclomatic_complexity
  func testSubscribe_Membership_Removed() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let mockResponses = ["subscription_handshake_success", "subscription_membershipRemove_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        let objectExpect = XCTestExpectation(description: "Object Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        let objectListenerExpect = XCTestExpectation(description: "Object Listener Event")
        let channel = PubNubChannelMetadataBase(metadataId: "TestSpaceID")
        let uuid = PubNubUUIDMetadataBase(metadataId: "TestUserID")
        
        let testMembership = PubNubMembershipMetadataBase(
          uuidMetadataId: "TestUserID", channelMetadataId: "TestSpaceID",
          uuid: uuid, channel: channel,
          updated: DateFormatter.iso8601.date(from: "2019-10-05T23:35:38.457823306Z"), eTag: "TestETag"
        )
        
        mockResult.listener.didReceiveSubscription = { [weak self] event in
          switch event {
          case let .connectionStatusChanged(status):
            if status == .disconnected {
              statusExpect.fulfill()
            }
          case let .membershipMetadataRemoved(membership):
            XCTAssertEqual(try? membership.transcode(), testMembership)
            objectExpect.fulfill()
          case let .subscriptionChanged(change):
            switch change {
            case let .subscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self?.testChannel)
            case .responseHeader:
              break
            case let .unsubscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self?.testChannel)
            }
          default:
            XCTFail("Incorrect Event Received \(event)")
          }
        }
        mockResult.listener.didReceiveObjectMetadataEvent = { [mockResult] event in
          switch event {
          case let .removedMembership(membership):
            XCTAssertEqual(try? membership.transcode(), testMembership)
            mockResult.subscriptionSession.unsubscribeAll()
            objectListenerExpect.fulfill()
          default:
            XCTFail("Incorrect Event Received \(event)")
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [objectExpect, statusExpect, objectListenerExpect], timeout: 1.0)
      }
    }
  }
}

// MARK: - Message Action

extension SubscribeRouterTests {
  // swiftlint:disable:next cyclomatic_complexity
  func testSubscribe_MessageAction_Added() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let actionExpect = XCTestExpectation(description: "Message Action Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        let actionListenerExpect = XCTestExpectation(description: "Action Listener Event")
        let mockResponses = ["subscription_handshake_success", "subscription_addMessageAction_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        
        mockResult.listener.didReceiveSubscription = { [weak self] event in
          switch event {
          case let .connectionStatusChanged(status):
            if status == .disconnected {
              statusExpect.fulfill()
            }
          case let .messageActionAdded(action):
            XCTAssertEqual(try? action.transcode(), self?.testAction)
            actionExpect.fulfill()
          case let .subscriptionChanged(change):
            switch change {
            case let .subscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self?.testChannel)
            case .responseHeader:
              break
            case let .unsubscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self?.testChannel)
            }
          default:
            XCTFail("Incorrect Event Received \(event)")
          }
        }
        mockResult.listener.didReceiveMessageAction = { [weak self, mockResult] event in
          switch event {
          case let .added(action):
            XCTAssertEqual(try? action.transcode(), self?.testAction)
            mockResult.subscriptionSession.unsubscribeAll()
            actionListenerExpect.fulfill()
          default:
            XCTFail("Incorrect Event Received")
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [actionExpect, statusExpect, actionListenerExpect], timeout: 1.0)
      }
    }
  }
  
  // swiftlint:disable:next cyclomatic_complexity function_body_length
  func testSubscribe_MessageAction_Removed() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let mockResponses = ["subscription_handshake_success", "subscription_removeMessageAction_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        let actionExpect = XCTestExpectation(description: "Message Action Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        let actionListenerExpect = XCTestExpectation(description: "Action Listener Event")
        
        mockResult.listener.didReceiveSubscription = { [weak self] event in
          switch event {
          case let .connectionStatusChanged(status):
            if status == .disconnected {
              statusExpect.fulfill()
            }
          case let .messageActionRemoved(action):
            XCTAssertEqual(try? action.transcode(), self?.testAction)
            actionExpect.fulfill()
          case let .subscriptionChanged(change):
            switch change {
            case let .subscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self?.testChannel)
            case .responseHeader:
              break
            case let .unsubscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self?.testChannel)
            }
          default:
            XCTFail("Incorrect Event Received")
          }
        }
        mockResult.listener.didReceiveMessageAction = { [weak self, mockResult] event in
          switch event {
          case let .removed(action):
            XCTAssertEqual(try? action.transcode(), self?.testAction)
            mockResult.subscriptionSession.unsubscribeAll()
            actionListenerExpect.fulfill()
          default:
            XCTFail("Incorrect Event Received")
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [actionExpect, statusExpect, actionListenerExpect], timeout: 1.0)
      }
    }
  }
}

// MARK: - Mixed Response

extension SubscribeRouterTests {
  func testSubscribe_Mixed() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let mockResponses = ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        let messageExpect = XCTestExpectation(description: "Message Event")
        let presenceExpect = XCTestExpectation(description: "Presence Event")
        let signalExpect = XCTestExpectation(description: "Signal Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        var payloadCount = 0
        
        mockResult.listener.didReceiveSubscription = { [mockResult] _ in
          payloadCount += 1
          if payloadCount == 7 {
            mockResult.subscriptionSession.unsubscribeAll()
          }
        }
        mockResult.listener.didReceiveMessage = { [weak self] message in
          XCTAssertEqual(message.channel, self?.testChannel)
          XCTAssertEqual(message.payload.stringOptional, "Test Message")
          messageExpect.fulfill()
        }
        mockResult.listener.didReceivePresence = { [weak self] presence in
          XCTAssertEqual(presence.channel, self?.testChannel)
          XCTAssertEqual(presence.actions, [.join(uuids: ["db9c5e39-7c95-40f5-8d71-125765b6f561"])])
          presenceExpect.fulfill()
        }
        mockResult.listener.didReceiveSignal = { [weak self] signal in
          XCTAssertEqual(signal.channel, self?.testChannel)
          XCTAssertEqual(signal.payload.stringOptional, "Test Signal")
          signalExpect.fulfill()
        }
        mockResult.listener.didReceiveStatus = { status in
          if let status = try? status.get(), status == .disconnected {
            statusExpect.fulfill()
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [signalExpect, statusExpect], timeout: 1.0)
      }
    }
  }
}

// MARK: - Error Handling

extension SubscribeRouterTests {
  func testInvalidJSONResponse() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        // swiftlint:disable:next line_length
        let corruptBase64Response = "eyJ0Ijp7InQiOiIxNTkxMjE4MzQ0MTUyNjM1MCIsInIiOjF9LCJtIjpbeyJhIjoiMyIsImYiOjUxMiwicCI6eyJ0IjoiMTU5MTIxODM0NDE1NTQyMDAiLCJyIjoxfSwiayI6ImRlbW8tMzYiLCJjIjoic3dpZnRJbnZhbGlkSlNPTi7/IiwiZCI6ImhlbGxvIiwiYiI6InN3aWZ0SW52YWxpZEpTT04uKiJ9XX0="
        
        guard let corruptedData = Data(base64Encoded: corruptBase64Response) else {
          return XCTFail("Could not create Data from String")
        }
        
        let mockResponses = ["subscription_handshake_success", "subscription_invalid_json", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, raw: [corruptedData], and: configuration)
        let errorExpect = XCTestExpectation(description: "Error Event")
        let statusExpect = XCTestExpectation(description: "Status Event")
        
        mockResult.listener.didReceiveSubscription = { [mockResult] event in
          switch event {
          case .subscriptionChanged:
            break
          case let .connectionStatusChanged(connection):
            if connection == .disconnected {
              statusExpect.fulfill()
            }
          case let .subscribeError(error):
            XCTAssertEqual(error.reason, .jsonDataDecodingFailure)
            mockResult.subscriptionSession.unsubscribeAll()
            errorExpect.fulfill()
          default:
            XCTFail("Unexpected event received \(event)")
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [errorExpect, statusExpect], timeout: 1.0, enforceOrder: true)
      }
    }
  }
}

// MARK: - Unsubscribe

extension SubscribeRouterTests {
  func testUnsubscribe() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let mockResponses = ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        let statusExpect = XCTestExpectation(description: "Status Event")
        statusExpect.expectedFulfillmentCount = 2
        statusExpect.assertForOverFulfill = true
        
        mockResult.listener.didReceiveSubscription = { [unowned self, mockResult] event in
          switch event {
          case let .subscriptionChanged(change):
            switch change {
            case let .subscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self.testChannel)
            case .responseHeader:
              break
            case let .unsubscribed(channels, _):
              XCTAssertEqual(channels.first?.id, self.testChannel)
            }
          case let .connectionStatusChanged(status):
            switch status {
            case .connected:
              mockResult.subscriptionSession.unsubscribe(from: [self.testChannel])
              XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [])
              statusExpect.fulfill()
            case .disconnected:
              statusExpect.fulfill()
            default:
              break
            }
          default:
            break
          }
        }
        mockResult.subscriptionSession.subscribe(to: [testChannel])
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])
        
        defer { mockResult.listener.cancel() }
        wait(for: [statusExpect], timeout: 1.0)
      }
    }
  }
  
  func testUnsubscribeAll() {
    for configuration in [config, eeEnabledConfig] {
      XCTContext.runActivity(named: "Testing with enableEventEngine=\(configuration.enableEventEngine)") { _ in
        let mockResponses = ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
        let mockResult = mockSubscriptionSession(with: mockResponses, and: configuration)
        let statusExpect = XCTestExpectation(description: "Status Event")
        let otherChannel = "OtherChannel"
        
        mockResult.listener.didReceiveSubscription = { [weak self, mockResult] event in
          switch event {
          case let .subscriptionChanged(change):
            switch change {
            case let .subscribed(channels, _):
              XCTAssertTrue(channels.contains(where: { $0.id == self?.testChannel }))
              XCTAssertTrue(channels.contains(where: { $0.id == otherChannel }))
            case .responseHeader:
              break
            case let .unsubscribed(channels, _):
              XCTAssertTrue(channels.contains(where: { $0.id == self?.testChannel }))
              XCTAssertTrue(channels.contains(where: { $0.id == otherChannel }))
            }
          case let .connectionStatusChanged(status):
            switch status {
            case .connected:
              mockResult.subscriptionSession.unsubscribeAll()
              XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [])
              statusExpect.fulfill()
            case .disconnected:
              statusExpect.fulfill()
            default:
              break
            }
          default:
            break
          }
        }
        
        mockResult.subscriptionSession.subscribe(to: [testChannel, otherChannel])
        XCTAssertTrue(mockResult.subscriptionSession.subscribedChannels.contains(testChannel))
        XCTAssertTrue(mockResult.subscriptionSession.subscribedChannels.contains(otherChannel))
        mockResult.subscriptionSession.unsubscribeAll()
        XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [])
        
        defer { mockResult.listener.cancel() }
        wait(for: [statusExpect], timeout: 1.0)
      }
    }
  }
}

// MARK: - Subscription with CryptoModule enabled

extension SubscribeRouterTests {
  func testSubscribe_DecryptNonEncryptedMessage() {
    let messageExpect = XCTestExpectation(description: "Message Event")
    messageExpect.assertForOverFulfill = true
    messageExpect.expectedFulfillmentCount = 1
    
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "pubnubenigma")
    )
    let mockResponses = [
      "subscription_handshake_success",
      "subscription_message_success",
      "cancelled"
    ]
    let container = DependencyContainer(configuration: config).register(
      value: try! MockURLSession.mockSession(for: mockResponses).session,
      forKey: HTTPSubscribeSessionDependencyKey.self
    )

    let pubnub = PubNub(container: container)
    let listener = SubscriptionListener()
        
    listener.didReceiveMessage = { [weak self, unowned pubnub] message in
      XCTAssertEqual(message.channel, self?.testChannel)
      XCTAssertEqual(message.payload.stringOptional, "Test Message")
      XCTAssertTrue(message.error?.reason == .decryptionFailure)
      pubnub.unsubscribeAll()
      messageExpect.fulfill()
    }
    
    pubnub.add(listener)
    pubnub.subscribe(to: [testChannel])

    defer { listener.cancel() }
    wait(for: [messageExpect], timeout: 1.0)
  }
  
  func testSubscribe_DecryptEncryptedMessage() {
    let messageExpect = XCTestExpectation(description: "Message Event")
    messageExpect.assertForOverFulfill = true
    messageExpect.expectedFulfillmentCount = 1
    
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "pubnubenigma")
    )
    let mockResponses = [
      "subscription_handshake_success",
      "subscription_encrypted_message_success",
      "cancelled"
    ]
    let container = DependencyContainer(configuration: config).register(
      value: try! MockURLSession.mockSession(for: mockResponses).session,
      forKey: HTTPSubscribeSessionDependencyKey.self
    )
    
    let pubnub = PubNub(container: container)
    let listener = SubscriptionListener()
        
    listener.didReceiveMessage = { [weak self, unowned pubnub] message in
      XCTAssertEqual(message.channel, self?.testChannel)
      XCTAssertEqual(message.payload.stringOptional, "Test Message")
      XCTAssertNil(message.error)
      pubnub.unsubscribeAll()
      messageExpect.fulfill()
    }
    
    pubnub.add(listener)
    pubnub.subscribe(to: [testChannel])

    defer { listener.cancel() }
    wait(for: [messageExpect], timeout: 1.0)
  }
  
  func testSubscribe_DecryptEncryptedMessageWithMismatchedKey() {
    let messageExpect = XCTestExpectation(description: "Message Event")
    messageExpect.assertForOverFulfill = true
    messageExpect.expectedFulfillmentCount = 1
    
    let config = PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "lorem-ipsum-dolor-sit-amet")
    )
    let mockResponses = [
      "subscription_handshake_success",
      "subscription_encrypted_message_success",
      "cancelled"
    ]
    let container = DependencyContainer(configuration: config).register(
      value: try! MockURLSession.mockSession(for: mockResponses).session,
      forKey: HTTPSubscribeSessionDependencyKey.self
    )

    let pubnub = PubNub(container: container)
    let listener = SubscriptionListener()
    
    listener.didReceiveMessage = { [weak self, unowned pubnub] message in
      XCTAssertEqual(message.channel, self?.testChannel)
      XCTAssertEqual(message.payload.stringOptional, "UE5FRAFBQ1JIEGOmGQMIMXD+91V+5hTxm7p7uEUhEEYohYLQz5fEGITC")
      XCTAssertTrue(message.error?.reason == .decryptionFailure)
      pubnub.unsubscribeAll()
      messageExpect.fulfill()
    }
    
    pubnub.add(listener)
    pubnub.subscribe(to: [testChannel])

    defer { listener.cancel() }
    wait(for: [messageExpect], timeout: 1.0)
  }
  
  // swiftlint:disable:next file_length
}
