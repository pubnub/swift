//
//  SubscribeRouterTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK
import XCTest

final class SubscribeRouterTests: XCTestCase {
  let config = PubNubConfiguration(
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

  func test_SubscribeRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = SubscribeRouter(.subscribe(
      channels: ["TestChannel"], groups: [], channelStates: [:],
      timetoken: 0, region: nil, heartbeat: nil, filter: nil
    ), configuration: config)

    XCTAssertEqual(router.endpoint.description, "Subscribe")
    XCTAssertEqual(router.category, "Subscribe")
    XCTAssertEqual(router.service, .subscribe)
  }

  func test_Subscribe_WhenChannelsAndGroupsEmpty_ReturnsValidationError() {
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
  func test_SubscribeRouter_WithEventEngineEnabled_IncludesStateAndEEParams() {
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
    XCTAssertTrue(queryItems.contains { $0.name == "state" && $0.value.map { expStateValues.contains($0) } == true })
  }

  func test_SubscribeRouter_WithEventEngineDisabled_ExcludesStateAndEEParams() {
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

  func test_SubscribeRouter_WithMaintainPresenceStateDisabled_ExcludesStateParam() {
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

  func test_SubscribeRouter_WithEmptyPresenceStates_ExcludesStateParam() {
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

// MARK: - Mock HTTP Session & Helpers

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
    let container = DependencyContainer(configuration: configuration)
    let listener = SubscriptionListener()

    // swiftlint:disable:next force_try force_unwrapping
    let session = try! MockURLSession.mockSession(for: responses, raw: dataResource).session!

    container.register(
      value: session,
      forKey: HTTPSubscribeSessionDependencyKey.self
    )

    let resolvedSession = container.subscriptionSession
    resolvedSession.add(listener)

    return MockResult(
      subscriptionSession: resolvedSession,
      listener: listener
    )
  }

  func expectSubscriptionEvent(
    mockResponses: [String],
    rawData: [Data] = [],
    file: StaticString = #file,
    line: UInt = #line,
    onEvent: @escaping (SubscriptionEvent) -> Bool,
    configureListener: ((SubscriptionListener, XCTestExpectation, SubscriptionSession) -> Void)? = nil
  ) {
    let eventExpect = expectation(description: "Expected event")
    let statusExpect = expectation(description: "Disconnect")
    let listenerExpect = configureListener != nil ? expectation(description: "Listener event") : nil
    let mockResult = mockSubscriptionSession(with: mockResponses, raw: rawData, and: config)
    let pubnub = PubNub(configuration: config)

    mockResult.listener.didReceiveSubscription = { [mockResult] event in
      switch event {
      case let .connectionStatusChanged(status) where status == .disconnected:
        statusExpect.fulfill()
      case .subscriptionChanged:
        break
      default:
        if onEvent(event) {
          if configureListener == nil {
            mockResult.subscriptionSession.unsubscribeAll()
          }
          eventExpect.fulfill()
        }
      }
    }

    if let configureListener, let listenerExpect {
      configureListener(mockResult.listener, listenerExpect, mockResult.subscriptionSession)
    }

    mockResult.subscriptionSession.subscribe(to: [pubnub.channel(testChannel).subscription()])
    defer { mockResult.listener.cancel() }
    wait(for: [eventExpect, statusExpect, listenerExpect].compactMap { $0 }, timeout: 1.0)
  }
}

// MARK: - Message Response

extension SubscribeRouterTests {
  func test_Subscribe_WithMessageEvent_ReceivesExpectedMessage() {
    expectSubscriptionEvent(
      mockResponses: ["subscription_handshake_success", "subscription_message_success", "cancelled"]
    ) { [weak self] event in
      guard case let .messageReceived(message) = event else { return false }
      XCTAssertEqual(message.channel, self?.testChannel)
      XCTAssertEqual(message.payload.stringOptional, "Test Message")
      return true
    }
  }
}

// MARK: - Presence Response

extension SubscribeRouterTests {
  func test_Subscribe_WithPresenceEvent_ReceivesJoinAndLeaveActions() {
    expectSubscriptionEvent(
      mockResponses: ["subscription_handshake_success", "subscription_presence_success", "cancelled"]
    ) { [weak self] event in
      guard case let .presenceChanged(presence) = event else { return false }
      XCTAssertEqual(presence.channel, self?.testChannel)
      XCTAssertEqual(presence.actions, [
        .join(uuids: ["db9c5e39-7c95-40f5-8d71-125765b6f561", "vqwqvae39-7c95-40f5-8d71-25234165142"]),
        .leave(uuids: ["234vq2343-7c95-40f5-8d71-125765b6f561", "42vvsge39-7c95-40f5-8d71-25234165142"])
      ])
      return true
    }
  }
}

// MARK: - Signal Response

extension SubscribeRouterTests {
  func test_Subscribe_WithSignalEvent_ReceivesExpectedSignal() {
    expectSubscriptionEvent(
      mockResponses: ["subscription_handshake_success", "subscription_signal_success", "cancelled"]
    ) { [weak self] event in
      guard case let .signalReceived(signal) = event else { return false }
      XCTAssertEqual(signal.channel, self?.testChannel)
      XCTAssertEqual(signal.publisher, "TestUser")
      XCTAssertEqual(signal.payload.stringOptional, "Test Signal")
      return true
    }
  }
}

// MARK: - User Object Response

extension SubscribeRouterTests {
  func test_Subscribe_WithUUIDMetadataSetEvent_ReceivesMetadataChangeset() {
    let baseUser = PubNubUserMetadataBase(metadataId: "TestUserID", name: "Not Real Name")
    let patchedUser = PubNubUserMetadataBase(
      metadataId: "TestUserID",
      name: "Test Name", type: "Test Type", status: "Test Status",
      updated: DateFormatter.iso8601.date(from: "2019-10-06T01:55:50.645685Z"),
      eTag: "UserUpdateEtag"
    )

    expectSubscriptionEvent(
      mockResponses: ["subscription_handshake_success", "subscription_uuidSet_success", "cancelled"],
      onEvent: { event in
        guard case let .uuidMetadataSet(changeset) = event else { return false }
        XCTAssertEqual(try? changeset.apply(to: baseUser).transcode(), patchedUser)
        return true
      },
      configureListener: { listener, expect, session in
        listener.didReceiveObjectMetadataEvent = { event in
          guard case let .setUUID(changeset) = event else {
            return XCTFail("Incorrect Event Received")
          }
          XCTAssertEqual(changeset.metadataId, "TestUserID")
          session.unsubscribeAll()
          expect.fulfill()
        }
      }
    )
  }

  func test_Subscribe_WithUUIDMetadataRemovedEvent_ReceivesMetadataId() {
    expectSubscriptionEvent(
      mockResponses: ["subscription_handshake_success", "subscription_uuidRemove_success", "cancelled"],
      onEvent: { event in
        guard case let .uuidMetadataRemoved(metadataId) = event else { return false }
        XCTAssertEqual(metadataId, "TestUserID")
        return true
      },
      configureListener: { listener, expect, session in
        listener.didReceiveObjectMetadataEvent = { event in
          guard case let .removedUUID(metadataId) = event else {
            return XCTFail("Incorrect Event Received")
          }
          XCTAssertEqual(metadataId, "TestUserID")
          session.unsubscribeAll()
          expect.fulfill()
        }
      }
    )
  }

  func test_Subscribe_WithChannelMetadataSetEvent_ReceivesMetadataChangeset() {
    let baseChannel = PubNubChannelMetadataBase(metadataId: "TestSpaceID", name: "Not Real Name", type: "someType")
    let patchedChannel = PubNubChannelMetadataBase(
      metadataId: "TestSpaceID", name: "Test Name",
      type: "Test Type", status: "Test Status",
      updated: DateFormatter.iso8601.date(from: "2019-10-06T01:55:50.645685Z"),
      eTag: "SpaceUpdateEtag"
    )

    expectSubscriptionEvent(
      mockResponses: ["subscription_handshake_success", "subscription_channelSet_success", "cancelled"],
      onEvent: { event in
        guard case let .channelMetadataSet(changeset) = event else { return false }
        XCTAssertEqual(try? changeset.apply(to: baseChannel).transcode(), patchedChannel)
        return true
      },
      configureListener: { listener, expect, session in
        listener.didReceiveObjectMetadataEvent = { event in
          guard case let .setChannel(changeset) = event else {
            return XCTFail("Incorrect Event Received")
          }
          XCTAssertEqual(changeset.metadataId, "TestSpaceID")
          session.unsubscribeAll()
          expect.fulfill()
        }
      }
    )
  }

  func test_Subscribe_WithChannelMetadataRemovedEvent_ReceivesMetadataId() {
    expectSubscriptionEvent(
      mockResponses: ["subscription_handshake_success", "subscription_channelRemove_success", "cancelled"],
      onEvent: { event in
        guard case let .channelMetadataRemoved(metadataId) = event else { return false }
        XCTAssertEqual(metadataId, "TestSpaceID")
        return true
      },
      configureListener: { listener, expect, session in
        listener.didReceiveObjectMetadataEvent = { event in
          guard case let .removedChannel(metadataId: metadataId) = event else {
            return XCTFail("Incorrect Event Received")
          }
          XCTAssertEqual(metadataId, "TestSpaceID")
          session.unsubscribeAll()
          expect.fulfill()
        }
      }
    )
  }

  func test_Subscribe_WithMembershipSetEvent_ReceivesMembership() {
    let testMembership = PubNubMembershipMetadataBase(
      userMetadataId: "TestUserID", channelMetadataId: "TestSpaceID",
      status: "Test Status",
      user: PubNubUserMetadataBase(metadataId: "TestUserID"),
      channel: PubNubChannelMetadataBase(metadataId: "TestSpaceID"),
      custom: ["something": true],
      updated: DateFormatter.iso8601.date(from: "2019-10-05T23:35:38.457823306Z"),
      eTag: "TestETag"
    )

    expectSubscriptionEvent(
      mockResponses: ["subscription_handshake_success", "subscription_membershipSet_success", "cancelled"],
      onEvent: { event in
        guard case let .membershipMetadataSet(membership) = event else { return false }
        XCTAssertEqual(try? membership.transcode(), testMembership)
        return true
      },
      configureListener: { listener, expect, session in
        listener.didReceiveObjectMetadataEvent = { event in
          guard case let .setMembership(membership) = event else {
            return XCTFail("Incorrect Event Received \(event)")
          }
          XCTAssertEqual(try? membership.transcode(), testMembership)
          session.unsubscribeAll()
          expect.fulfill()
        }
      }
    )
  }

  func test_Subscribe_WithMembershipRemovedEvent_ReceivesMembership() {
    let testMembership = PubNubMembershipMetadataBase(
      userMetadataId: "TestUserID", channelMetadataId: "TestSpaceID",
      user: PubNubUserMetadataBase(metadataId: "TestUserID"),
      channel: PubNubChannelMetadataBase(metadataId: "TestSpaceID"),
      updated: DateFormatter.iso8601.date(from: "2019-10-05T23:35:38.457823306Z"), eTag: "TestETag"
    )

    expectSubscriptionEvent(
      mockResponses: ["subscription_handshake_success", "subscription_membershipRemove_success", "cancelled"],
      onEvent: { event in
        guard case let .membershipMetadataRemoved(membership) = event else { return false }
        XCTAssertEqual(try? membership.transcode(), testMembership)
        return true
      },
      configureListener: { listener, expect, session in
        listener.didReceiveObjectMetadataEvent = { event in
          guard case let .removedMembership(membership) = event else {
            return XCTFail("Incorrect Event Received \(event)")
          }
          XCTAssertEqual(try? membership.transcode(), testMembership)
          session.unsubscribeAll()
          expect.fulfill()
        }
      }
    )
  }
}

// MARK: - Message Action

extension SubscribeRouterTests {
  func test_Subscribe_WithMessageActionAddedEvent_ReceivesAction() {
    expectSubscriptionEvent(
      mockResponses: ["subscription_handshake_success", "subscription_addMessageAction_success", "cancelled"],
      onEvent: { [weak self] event in
        guard case let .messageActionAdded(action) = event else { return false }
        XCTAssertEqual(try? action.transcode(), self?.testAction)
        return true
      },
      configureListener: { [weak self] listener, expect, session in
        listener.didReceiveMessageAction = { event in
          guard case let .added(action) = event else {
            return XCTFail("Incorrect Event Received")
          }
          XCTAssertEqual(try? action.transcode(), self?.testAction)
          session.unsubscribeAll()
          expect.fulfill()
        }
      }
    )
  }

  func test_Subscribe_WithMessageActionRemovedEvent_ReceivesAction() {
    expectSubscriptionEvent(
      mockResponses: ["subscription_handshake_success", "subscription_removeMessageAction_success", "cancelled"],
      onEvent: { [weak self] event in
        guard case let .messageActionRemoved(action) = event else { return false }
        XCTAssertEqual(try? action.transcode(), self?.testAction)
        return true
      },
      configureListener: { [weak self] listener, expect, session in
        listener.didReceiveMessageAction = { event in
          guard case let .removed(action) = event else {
            return XCTFail("Incorrect Event Received")
          }
          XCTAssertEqual(try? action.transcode(), self?.testAction)
          session.unsubscribeAll()
          expect.fulfill()
        }
      }
    )
  }
}

// MARK: - Mixed Response

extension SubscribeRouterTests {
  func test_Subscribe_WithMixedEvents_ReceivesAllEventTypes() {
    let mockResponses = ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
    let mockResult = mockSubscriptionSession(with: mockResponses, and: config)
    let messageExpect = XCTestExpectation(description: "Message Event")
    let presenceExpect = XCTestExpectation(description: "Presence Event")
    let signalExpect = XCTestExpectation(description: "Signal Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let pubnub = PubNub(configuration: config)
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
    mockResult.subscriptionSession.subscribe(to: [pubnub.channel(testChannel).subscription()])
    XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])

    defer { mockResult.listener.cancel() }
    wait(for: [signalExpect, statusExpect], timeout: 1.0)
  }
}

// MARK: - Error Handling

extension SubscribeRouterTests {
  func test_Subscribe_WithInvalidJSON_ReturnsDecodingError() throws {
    // swiftlint:disable:next line_length
    let corruptBase64Response = "eyJ0Ijp7InQiOiIxNTkxMjE4MzQ0MTUyNjM1MCIsInIiOjF9LCJtIjpbeyJhIjoiMyIsImYiOjUxMiwicCI6eyJ0IjoiMTU5MTIxODM0NDE1NTQyMDAiLCJyIjoxfSwiayI6ImRlbW8tMzYiLCJjIjoic3dpZnRJbnZhbGlkSlNPTi7/IiwiZCI6ImhlbGxvIiwiYiI6InN3aWZ0SW52YWxpZEpTT04uKiJ9XX0="

    let corruptedData = try XCTUnwrap(Data(base64Encoded: corruptBase64Response))

    let mockResponses = ["subscription_handshake_success", "subscription_invalid_json", "cancelled"]
    let mockResult = mockSubscriptionSession(with: mockResponses, raw: [corruptedData], and: config)
    let errorExpect = XCTestExpectation(description: "Error Event")
    let statusExpect = XCTestExpectation(description: "Status Event")
    let pubnub = PubNub(configuration: config)

    mockResult.listener.didReceiveSubscription = { [mockResult] event in
      switch event {
      case .subscriptionChanged:
        break
      case let .connectionStatusChanged(connection):
        if case .connectionError = connection {
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
    mockResult.subscriptionSession.subscribe(to: [pubnub.channel(testChannel).subscription()])
    XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])

    defer { mockResult.listener.cancel() }
    wait(for: [errorExpect, statusExpect], timeout: 1.0, enforceOrder: true)
  }
}

// MARK: - Unsubscribe

extension SubscribeRouterTests {
  func test_Unsubscribe_WithSingleChannel_RemovesChannelFromSubscription() {
    let pubnub = PubNub(configuration: config)
    let mockResponses = ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
    let mockResult = mockSubscriptionSession(with: mockResponses, and: config)

    let statusExpect = XCTestExpectation(description: "Status Event")
    statusExpect.expectedFulfillmentCount = 2
    statusExpect.assertForOverFulfill = true

    mockResult.listener.didReceiveSubscription = { [weak self, mockResult] event in
      switch event {
      case let .subscriptionChanged(change):
        switch change {
        case let .subscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self?.testChannel)
        case .responseHeader:
          break
        case let .unsubscribed(channels, _):
          XCTAssertEqual(channels.first?.id, self?.testChannel)
        }
      case let .connectionStatusChanged(status):
        switch status {
        case .connected:
          mockResult.subscriptionSession.unsubscribe(from: [self?.testChannel ?? ""])
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

    mockResult.subscriptionSession.subscribe(to: [pubnub.channel(testChannel).subscription()])
    XCTAssertEqual(mockResult.subscriptionSession.subscribedChannels, [testChannel])

    defer { mockResult.listener.cancel() }
    wait(for: [statusExpect], timeout: 1.0)
  }

  func test_UnsubscribeAll_WithMultipleChannels_RemovesAllChannels() {
    let mockResponses = ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
    let mockResult = mockSubscriptionSession(with: mockResponses, and: config)
    let statusExpect = XCTestExpectation(description: "Status Event")
    let otherChannel = "OtherChannel"
    let pubnub = PubNub(configuration: config)
    let subscriptionSession = mockResult.subscriptionSession

    mockResult.listener.didReceiveSubscription = { [weak self, weak subscriptionSession] event in
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
          subscriptionSession?.unsubscribeAll()
          XCTAssertEqual(subscriptionSession?.subscribedChannels, [])
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

    mockResult.subscriptionSession.subscribe(to: [
      pubnub.channel(testChannel).subscription(),
      pubnub.channel(otherChannel).subscription()
    ])

    XCTAssertTrue(mockResult.subscriptionSession.subscribedChannels.contains(testChannel))
    XCTAssertTrue(mockResult.subscriptionSession.subscribedChannels.contains(otherChannel))

    defer { mockResult.listener.cancel() }
    wait(for: [statusExpect], timeout: 1.0)
  }
}

// MARK: - Subscription with CryptoModule enabled

extension SubscribeRouterTests {
  func test_Subscribe_WithCryptoAndNonEncryptedMessage_ReturnsDecryptionFailure() throws {
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
      value: try XCTUnwrap(MockURLSession.mockSession(for: mockResponses).session),
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

  func test_Subscribe_WithCryptoAndEncryptedMessage_ReturnsDecryptedMessage() throws {
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
      value: try XCTUnwrap(MockURLSession.mockSession(for: mockResponses).session),
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

  func test_Subscribe_WithMismatchedCryptoKey_ReturnsDecryptionFailure() throws {
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
      value: try XCTUnwrap(MockURLSession.mockSession(for: mockResponses).session),
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
}
