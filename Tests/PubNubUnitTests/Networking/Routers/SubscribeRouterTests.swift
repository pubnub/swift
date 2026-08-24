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
    XCTAssertEqual(router.validationError?.pubNubError, PubNubError(.missingRequiredParameter, router: router))
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

extension SubscribeRouterTests {
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
    let httpSession = try XCTUnwrap(MockURLSession.mockSession(for: responses, raw: rawData).session)

    container.register(
      value: httpSession,
      forKey: HTTPSubscribeSessionDependencyKey.self
    )

    let session = container.subscriptionSession
    let listener = SubscriptionListener()

    session.add(listener)

    return MockSubscription(
      session: session,
      listener: listener
    )
  }

  func decodeEvent(from resource: String) throws -> PubNubEvent {
    let data = try ImportTestResource.importResource(resource)
    let response = try JSONDecoder().decode(EndpointResource.self, from: data)
    let body = try XCTUnwrap(response.body).jsonDataResult.get()
    let subscribeResponse = try JSONDecoder().decode(SubscribeResponse.self, from: body)
    let payload = try XCTUnwrap(subscribeResponse.messages.first)

    return payload.asPubNubEvent()
  }
}

// MARK: Helpers

extension PubNubEvent {
  var message: PubNubMessage? {
    guard case let .messageReceived(m) = self else { return nil }
    return m
  }
}
