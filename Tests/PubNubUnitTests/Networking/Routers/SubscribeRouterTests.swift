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
@testable import PubNubSDK

final class SubscribeRouterTests: XCTestCase {
  let testChannel = "TestChannel"

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

  // MARK: - Endpoint Tests

  func test_SubscribeRouter_WithValidConfig_SetsExpectedEndpoint() {
    let router = SubscribeRouter(.subscribe(
      channels: [testChannel], groups: [], channelStates: [:],
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

    XCTAssertNotNil(router.validationError)
    XCTAssertEqual(
      router.validationError?.pubNubError,
      PubNubError(.missingRequiredParameter, router: router)
    )
  }
}

// MARK: - Subscribe Query Params

extension SubscribeRouterTests {
  func test_SubscribeRouter_WithEventEngineEnabled_IncludesStateAndEEParams() throws {
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
    let queryItems = try router.queryItems.get()

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

  func test_SubscribeRouter_WithEventEngineDisabled_ExcludesStateAndEEParams() throws {
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
    let queryItems = try router.queryItems.get()

    XCTAssertTrue(queryItems.count == 6)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value == "30" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value == "group-1,group-2" })
    XCTAssertTrue(queryItems.contains { $0.name == "tt" && $0.value == "123456" })
    XCTAssertTrue(queryItems.contains { $0.name == "tr" && $0.value == "42" })
  }

  func test_SubscribeRouter_WithMaintainPresenceStateDisabled_ExcludesStateParam() throws {
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
    let queryItems = try router.queryItems.get()

    XCTAssertTrue(queryItems.count == 7)
    XCTAssertTrue(queryItems.contains { $0.name == "pnsdk" })
    XCTAssertTrue(queryItems.contains { $0.name == "uuid" && $0.value == "someId" })
    XCTAssertTrue(queryItems.contains { $0.name == "heartbeat" && $0.value == "30" })
    XCTAssertTrue(queryItems.contains { $0.name == "channel-group" && $0.value == "group-1,group-2" })
    XCTAssertTrue(queryItems.contains { $0.name == "tt" && $0.value == "123456" })
    XCTAssertTrue(queryItems.contains { $0.name == "tr" && $0.value == "42" })
    XCTAssertTrue(queryItems.contains { $0.name == "ee" && $0.value == nil })
  }

  func test_SubscribeRouter_WithEmptyPresenceStates_ExcludesStateParam() throws {
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
    let queryItems = try router.queryItems.get()

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

// MARK: - Message Response

extension SubscribeRouterTests {
  func test_Subscribe_WithMessageEvent_ReceivesExpectedMessage() throws {
    let event = try decodeEvent(from: "subscription_message_success")
    let message = try XCTUnwrap(event.message)

    XCTAssertEqual(message.channel, testChannel)
    XCTAssertEqual(message.payload.stringOptional, "Test Message")
  }
}

// MARK: - Presence Response

extension SubscribeRouterTests {
  func test_Subscribe_WithPresenceEvent_ReceivesJoinAndLeaveActions() throws {
    let event = try decodeEvent(from: "subscription_presence_success")
    let presence = try XCTUnwrap(event.presence)

    XCTAssertEqual(presence.channel, testChannel)
    XCTAssertEqual(presence.actions, [
      .join(uuids: ["db9c5e39-7c95-40f5-8d71-125765b6f561", "vqwqvae39-7c95-40f5-8d71-25234165142"]),
      .leave(uuids: ["234vq2343-7c95-40f5-8d71-125765b6f561", "42vvsge39-7c95-40f5-8d71-25234165142"])
    ])
  }
}

// MARK: - Signal Response

extension SubscribeRouterTests {
  func test_Subscribe_WithSignalEvent_ReceivesExpectedSignal() throws {
    let event = try decodeEvent(from: "subscription_signal_success")
    let signal = try XCTUnwrap(event.signal)

    XCTAssertEqual(signal.channel, testChannel)
    XCTAssertEqual(signal.publisher, "TestUser")
    XCTAssertEqual(signal.payload.stringOptional, "Test Signal")
  }
}

// MARK: - User Object Response

extension SubscribeRouterTests {
  func test_Subscribe_WithUUIDMetadataSetEvent_ReceivesMetadataChangeset() throws {
    let baseUser = PubNubUserMetadataBase(
      metadataId: "TestUserID",
      name: "Not Real Name"
    )
    let patchedUser = PubNubUserMetadataBase(
      metadataId: "TestUserID",
      name: "Test Name", type: "Test Type", status: "Test Status",
      updated: DateFormatter.iso8601.date(from: "2019-10-06T01:55:50.645685Z"),
      eTag: "UserUpdateEtag"
    )

    let event = try decodeEvent(from: "subscription_uuidSet_success")
    let changeset = try XCTUnwrap(event.userMetadataChangeset)

    XCTAssertEqual(try changeset.apply(to: baseUser).transcode(), patchedUser)
  }

  func test_Subscribe_WithUUIDMetadataRemovedEvent_ReceivesMetadataId() throws {
    let event = try decodeEvent(from: "subscription_uuidRemove_success")
    let metadataId = try XCTUnwrap(event.removedUserMetadataId)

    XCTAssertEqual(metadataId, "TestUserID")
  }

  func test_Subscribe_WithChannelMetadataSetEvent_ReceivesMetadataChangeset() throws {
    let baseChannel = PubNubChannelMetadataBase(
      metadataId: "TestSpaceID",
      name: "Not Real Name",
      type: "someType"
    )
    let patchedChannel = PubNubChannelMetadataBase(
      metadataId: "TestSpaceID", name: "Test Name",
      type: "Test Type", status: "Test Status",
      updated: DateFormatter.iso8601.date(from: "2019-10-06T01:55:50.645685Z"),
      eTag: "SpaceUpdateEtag"
    )

    let event = try decodeEvent(from: "subscription_channelSet_success")
    let changeset = try XCTUnwrap(event.channelMetadataChangeset)

    XCTAssertEqual(try changeset.apply(to: baseChannel).transcode(), patchedChannel)
  }

  func test_Subscribe_WithChannelMetadataRemovedEvent_ReceivesMetadataId() throws {
    let event = try decodeEvent(from: "subscription_channelRemove_success")
    let metadataId = try XCTUnwrap(event.removedChannelMetadataId)

    XCTAssertEqual(metadataId, "TestSpaceID")
  }

  func test_Subscribe_WithMembershipSetEvent_ReceivesMembership() throws {
    let expectedMembership = PubNubMembershipMetadataBase(
      userMetadataId: "TestUserID", channelMetadataId: "TestSpaceID",
      status: "Test Status",
      user: PubNubUserMetadataBase(metadataId: "TestUserID"),
      channel: PubNubChannelMetadataBase(metadataId: "TestSpaceID"),
      custom: ["something": true],
      updated: DateFormatter.iso8601.date(from: "2019-10-05T23:35:38.457823306Z"),
      eTag: "TestETag"
    )

    let event = try decodeEvent(from: "subscription_membershipSet_success")
    let membership = try XCTUnwrap(event.membershipSet)

    XCTAssertEqual(try membership.transcode(), expectedMembership)
  }

  func test_Subscribe_WithMembershipRemovedEvent_ReceivesMembership() throws {
    let expectedMembership = PubNubMembershipMetadataBase(
      userMetadataId: "TestUserID", channelMetadataId: "TestSpaceID",
      user: PubNubUserMetadataBase(metadataId: "TestUserID"),
      channel: PubNubChannelMetadataBase(metadataId: "TestSpaceID"),
      updated: DateFormatter.iso8601.date(from: "2019-10-05T23:35:38.457823306Z"), eTag: "TestETag"
    )

    let event = try decodeEvent(from: "subscription_membershipRemove_success")
    let membership = try XCTUnwrap(event.membershipRemoved)

    XCTAssertEqual(try membership.transcode(), expectedMembership)
  }
}

// MARK: - Message Action

extension SubscribeRouterTests {
  func test_Subscribe_WithMessageActionAddedEvent_ReceivesAction() throws {
    let event = try decodeEvent(from: "subscription_addMessageAction_success")
    let action = try XCTUnwrap(event.addedMessageAction)

    XCTAssertEqual(try action.transcode(), testAction)
  }

  func test_Subscribe_WithMessageActionRemovedEvent_ReceivesAction() throws {
    let event = try decodeEvent(from: "subscription_removeMessageAction_success")
    let action = try XCTUnwrap(event.removedMessageAction)

    XCTAssertEqual(try action.transcode(), testAction)
  }
}

// MARK: - Error Handling

extension SubscribeRouterTests {
  func test_Subscribe_WithInvalidJSON_ReturnsDecodingError() throws {
    let corruptBase64Response = [
      "eyJ0Ijp7InQiOiIxNTkxMjE4MzQ0MTUyNjM1MCIsInIiOjF9LCJtIjpbeyJhIjoiMyIsImYiOjUx",
      "MiwicCI6eyJ0IjoiMTU5MTIxODM0NDE1NTQyMDAiLCJyIjoxfSwiayI6ImRlbW8tMzYiLCJjIjoi",
      "c3dpZnRJbnZhbGlkSlNPTi7/IiwiZCI6ImhlbGxvIiwiYiI6InN3aWZ0SW52YWxpZEpTT04uKiJ9",
      "XX0="
    ].joined()

    let corruptedData = try XCTUnwrap(Data(base64Encoded: corruptBase64Response))
    let mockResponses = ["subscription_handshake_success", "subscription_invalid_json", "cancelled"]
    let mock = try mockSubscription(responses: mockResponses, rawData: [corruptedData], configuration: config)
    let pubnub = PubNub(configuration: config)
    let errorExpect = expectation(description: "Subscribe error")
    let disconnectExpect = expectation(description: "Connection error")

    mock.listener.didReceiveSubscription = { [mock] event in
      if case let .subscribeError(error) = event {
        XCTAssertEqual(error.reason, .jsonDataDecodingFailure)
        mock.session.unsubscribeAll()
        errorExpect.fulfill()
      } else if case .connectionStatusChanged(.connectionError) = event {
        disconnectExpect.fulfill()
      }
    }

    mock.session.subscribe(to: [pubnub.channel(testChannel).subscription()])
    defer { mock.listener.cancel() }
    wait(for: [errorExpect, disconnectExpect], timeout: 1.0, enforceOrder: true)
  }
}

// MARK: - Unsubscribe

extension SubscribeRouterTests {
  func test_Unsubscribe_WithSingleChannel_RemovesChannelFromSubscription() throws {
    let pubnub = PubNub(configuration: config)
    let mockResponses = ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
    let mock = try mockSubscription(responses: mockResponses, configuration: config)
    let connectedExpect = expectation(description: "Connected")
    let disconnectedExpect = expectation(description: "Disconnected")

    mock.listener.didReceiveStatus = { status in
      do {
        let status = try status.get()
        switch status {
        case .connected:
          connectedExpect.fulfill()
        case .disconnected:
          disconnectedExpect.fulfill()
        default:
          break
        }
      } catch {
        XCTFail("Unexpected status error: \(error)")
      }
    }

    mock.session.subscribe(to: [pubnub.channel(testChannel).subscription()])
    wait(for: [connectedExpect], timeout: 1.0)

    XCTAssertEqual(mock.session.subscribedChannels, [testChannel])
    mock.session.unsubscribe(from: [testChannel])
    XCTAssertEqual(mock.session.subscribedChannels, [])

    wait(for: [disconnectedExpect], timeout: 1.0)
    mock.listener.cancel()
  }

  func test_UnsubscribeAll_WithMultipleChannels_RemovesAllChannels() throws {
    let otherChannel = "OtherChannel"
    let pubnub = PubNub(configuration: config)
    let mockResponses = ["subscription_handshake_success", "subscription_mixed_success", "cancelled"]
    let mock = try mockSubscription(responses: mockResponses, configuration: config)
    let connectedExpect = expectation(description: "Connected")
    let disconnectedExpect = expectation(description: "Disconnected")

    mock.listener.didReceiveStatus = { status in
      do {
        let status = try status.get()
        switch status {
        case .connected:
          connectedExpect.fulfill()
        case .disconnected:
          disconnectedExpect.fulfill()
        default:
          break
        }
      } catch {
        XCTFail("Unexpected status error: \(error)")
      }
    }

    mock.session.subscribe(to: [
      pubnub.channel(testChannel).subscription(),
      pubnub.channel(otherChannel).subscription()
    ])

    wait(for: [connectedExpect], timeout: 1.0)

    XCTAssertTrue(mock.session.subscribedChannels.contains(testChannel))
    XCTAssertTrue(mock.session.subscribedChannels.contains(otherChannel))
    mock.session.unsubscribeAll()
    XCTAssertEqual(mock.session.subscribedChannels, [])

    wait(for: [disconnectedExpect], timeout: 1.0)
    mock.listener.cancel()
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

// MARK: Helpers

private extension PubNubEvent {
  var message: PubNubMessage? {
    guard case let .messageReceived(m) = self else { return nil }
    return m
  }

  var signal: PubNubMessage? {
    guard case let .signalReceived(s) = self else { return nil }
    return s
  }

  var presence: PubNubPresenceChange? {
    guard case let .presenceChanged(p) = self else { return nil }
    return p
  }

  var userMetadataChangeset: PubNubUserMetadataChangeset? {
    guard case let .appContextChanged(.userMetadataSet(c)) = self else { return nil }
    return c
  }

  var removedUserMetadataId: String? {
    guard case let .appContextChanged(.userMetadataRemoved(metadataId)) = self else { return nil }
    return metadataId
  }

  var channelMetadataChangeset: PubNubChannelMetadataChangeset? {
    guard case let .appContextChanged(.channelMetadataSet(c)) = self else { return nil }
    return c
  }

  var removedChannelMetadataId: String? {
    guard case let .appContextChanged(.channelMetadataRemoved(metadataId)) = self else { return nil }
    return metadataId
  }

  var membershipSet: PubNubMembershipMetadata? {
    guard case let .appContextChanged(.membershipMetadataSet(m)) = self else { return nil }
    return m
  }

  var membershipRemoved: PubNubMembershipMetadata? {
    guard case let .appContextChanged(.membershipMetadataRemoved(m)) = self else { return nil }
    return m
  }

  var addedMessageAction: PubNubMessageAction? {
    guard case let .messageActionChanged(.added(a)) = self else { return nil }
    return a
  }

  var removedMessageAction: PubNubMessageAction? {
    guard case let .messageActionChanged(.removed(a)) = self else { return nil }
    return a
  }
}

private extension SubscribeRouterTests {
  struct MockSubscription {
    let session: SubscriptionSession
    let listener: SubscriptionListener
  }

  func mockSubscription(
    responses: [String],
    rawData: [Data] = [],
    configuration: PubNubConfiguration
  ) throws -> MockSubscription {
    let container = DependencyContainer(configuration: configuration)
    let listener = SubscriptionListener()
    let urlSession = try XCTUnwrap(MockURLSession.mockSession(for: responses, raw: rawData).session)

    container.register(
      value: urlSession,
      forKey: HTTPSubscribeSessionDependencyKey.self
    )

    let session = container.subscriptionSession
    session.add(listener)

    return MockSubscription(
      session: session,
      listener: listener
    )
  }

  func decodeEvent(from resource: String) throws -> PubNubEvent {
    let data = try ImportTestResource.importResource(resource)
    let response = try JSONDecoder().decode(EndpointResource.self, from: data)
    let body = try response.body.jsonDataResult.get()
    let subscribeResponse = try JSONDecoder().decode(SubscribeResponse.self, from: body)
    let payload = try XCTUnwrap(subscribeResponse.messages.first)

    return payload.asPubNubEvent()
  }
}
