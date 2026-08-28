//
//  SubscriptionTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

class SubscriptionTests: XCTestCase {
  func testSubscription_OnMessage() {
    let expectation = XCTestExpectation(description: "Message")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    subscription.onMessage = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockMessagePayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_OnSignal() {
    let expectation = XCTestExpectation(description: "Signal")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    subscription.onSignal = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockSignalPayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_OnPresence() {
    let expectation = XCTestExpectation(description: "Presence")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    subscription.onPresence = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockPresenceChangePayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_OnAppContext() {
    let expectation = XCTestExpectation(description: "App Context")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    subscription.onAppContext = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockAppContextPayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_OnDataSync() {
    let expectation = XCTestExpectation(description: "DataSync")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    subscription.onDataSync = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockDataSyncPayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_OnFileEvent() {
    let expectation = XCTestExpectation(description: "File")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    subscription.onFileEvent = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockFilePayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_OnMessageAction() {
    let expectation = XCTestExpectation(description: "Message Action")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    subscription.onMessageAction = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockMessageActionPayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_OnEvents() {
    let expectation = XCTestExpectation(description: "All Events")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 1

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    subscription.onEvents = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockMessagePayload(channel: channel.name), mockSignalPayload(channel: channel.name),
      mockPresenceChangePayload(channel: channel.name), mockAppContextPayload(channel: channel.name),
      mockFilePayload(channel: channel.name), mockMessageActionPayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_PayloadsFromDifferentChannel() {
    let messagesExpectation = XCTestExpectation(description: "Message")
    messagesExpectation.isInverted = true
    messagesExpectation.assertForOverFulfill = true

    let signalExpectation = XCTestExpectation(description: "Signal")
    signalExpectation.isInverted = true
    signalExpectation.assertForOverFulfill = true

    let messageAction = XCTestExpectation(description: "Message Action")
    messageAction.isInverted = true
    messageAction.assertForOverFulfill = true

    let presenceChangeExpectation = XCTestExpectation(description: "Presence")
    presenceChangeExpectation.isInverted = true
    presenceChangeExpectation.assertForOverFulfill = true
    presenceChangeExpectation.expectedFulfillmentCount = 1

    let appContextExpectation = XCTestExpectation(description: "App Context")
    appContextExpectation.isInverted = true
    appContextExpectation.assertForOverFulfill = true

    let fileExpectation = XCTestExpectation(description: "File")
    fileExpectation.isInverted = true
    fileExpectation.assertForOverFulfill = true

    let allEventsExpectation = XCTestExpectation(description: "All Events")
    allEventsExpectation.isInverted = true
    allEventsExpectation.assertForOverFulfill = true

    let singleEventExpectation = XCTestExpectation(description: "Single Event")
    singleEventExpectation.isInverted = true
    singleEventExpectation.expectedFulfillmentCount = 6

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("channel")
    let subscription = channel.subscription()

    subscription.onEvents = { _ in
      allEventsExpectation.fulfill()
      singleEventExpectation.fulfill()
    }
    subscription.onMessage = { _ in
      messagesExpectation.fulfill()
      singleEventExpectation.fulfill()
    }
    subscription.onSignal = { _ in
      signalExpectation.fulfill()
      singleEventExpectation.fulfill()
    }
    subscription.onMessageAction = { _ in
      messageAction.fulfill()
      singleEventExpectation.fulfill()
    }
    subscription.onPresence = { _ in
      presenceChangeExpectation.fulfill()
    }
    subscription.onAppContext = { _ in
      appContextExpectation.fulfill()
      singleEventExpectation.fulfill()
    }
    subscription.onFileEvent = { _ in
      fileExpectation.fulfill()
      singleEventExpectation.fulfill()
    }
    subscription.onPayloadsReceived(payloads: [
      mockMessagePayload(channel: "diff"), mockSignalPayload(channel: "diff"),
      mockPresenceChangePayload(channel: "diff"), mockAppContextPayload(channel: "diff"),
      mockFilePayload(channel: "diff"), mockMessageActionPayload(channel: "diff")
    ])

    let allExpectations = [
      messagesExpectation, signalExpectation, presenceChangeExpectation,
      messageAction, fileExpectation, appContextExpectation,
      allEventsExpectation, singleEventExpectation
    ]

    wait(for: allExpectations, timeout: 0.5)
  }

  func testSubscription_WildcardSubscription() {
    let expectation = XCTestExpectation(description: "Message")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 1

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("channel.item.*")
    let subscription = channel.subscription()

    subscription.onMessage = { _ in
      expectation.fulfill()
    }
    subscription.onPayloadsReceived(
      payloads: [mockMessagePayload(channel: "channel.item.x")]
    )
    wait(for: [expectation], timeout: 0.5)
  }

  func testSubscription_WithFilterOption() {
    let expectation = XCTestExpectation(description: "Message")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = 1

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("channel")
    let subscription = channel.subscription(options: FilterOption(predicate: { event in
      guard case let .messageReceived(message) = event else {
        return false
      }
      if message.payload.stringOptional == "Hey!" {
        expectation.fulfill(); return true
      } else {
        return false
      }
    }))

    subscription.onPayloadsReceived(payloads: [
      mockMessagePayload(channel: channel.name, message: "This is a message"),
      mockMessagePayload(channel: channel.name, message: "Hey!")
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_ReceivePresenceEvents() {
    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("c")
    let subscription = channel.subscription(options: ReceivePresenceEvents())

    XCTAssertEqual(
      subscription.subscriptionTopology,
      SubscriptionTopology(channels: ["c", "c-pnpres"])
    )
  }

  func testSubscription_ReceivePresenceEventsForChannelGroup() {
    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channelGroup("g")
    let subscription = channel.subscription(options: ReceivePresenceEvents())

    XCTAssertEqual(
      subscription.subscriptionTopology,
      SubscriptionTopology(channelGroups: ["g", "g-pnpres"])
    )
  }

  func testDataSyncSubscribables_UseIdentifierAsChannelWithoutProjection() {
    let pubnub = TestPubNubFactory.make(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId"
    )
    let subscriptions = [
      pubnub.dataSyncUser("user-id").subscription(),
      pubnub.dataSyncChannel("channel-id").subscription(),
      pubnub.dataSyncMembership("membership-id").subscription(),
      pubnub.dataSyncEntity("entity-id").subscription(),
      pubnub.dataSyncRelationship("relationship-id").subscription()
    ]

    XCTAssertEqual(
      subscriptions.map(\.subscriptionTopology),
      [
        SubscriptionTopology(channels: ["user-id"]),
        SubscriptionTopology(channels: ["channel-id"]),
        SubscriptionTopology(channels: ["membership-id"]),
        SubscriptionTopology(channels: ["entity-id"]),
        SubscriptionTopology(channels: ["relationship-id"])
      ]
    )
  }

  func testDataSyncSubscribables_UseProjectionAndIdentifierAsChannelWithProjection() {
    let pubnub = TestPubNubFactory.make(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId"
    )
    let subscriptions = [
      pubnub.dataSyncUser("user-id").subscription(projection: "details"),
      pubnub.dataSyncChannel("channel-id").subscription(projection: "details"),
      pubnub.dataSyncMembership("membership-id").subscription(projection: "details"),
      pubnub.dataSyncEntity("entity-id").subscription(projection: "details"),
      pubnub.dataSyncRelationship("relationship-id").subscription(projection: "details")
    ]

    XCTAssertEqual(
      subscriptions.map(\.subscriptionTopology),
      [
        SubscriptionTopology(channels: ["__details__user-id"]),
        SubscriptionTopology(channels: ["__details__channel-id"]),
        SubscriptionTopology(channels: ["__details__membership-id"]),
        SubscriptionTopology(channels: ["__details__entity-id"]),
        SubscriptionTopology(channels: ["__details__relationship-id"])
      ]
    )
  }

  func testDataSyncSubscribables_UseIdentifierAsChannelWithDefaultProjection() {
    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let subscriptions = [
      pubnub.dataSyncUser("user-id").subscription(projection: "default"),
      pubnub.dataSyncChannel("channel-id").subscription(projection: "default"),
      pubnub.dataSyncMembership("membership-id").subscription(projection: "default"),
      pubnub.dataSyncEntity("entity-id").subscription(projection: "default"),
      pubnub.dataSyncRelationship("relationship-id").subscription(projection: "default")
    ]

    XCTAssertEqual(
      subscriptions.map(\.subscriptionTopology),
      [
        SubscriptionTopology(channels: ["user-id"]),
        SubscriptionTopology(channels: ["channel-id"]),
        SubscriptionTopology(channels: ["membership-id"]),
        SubscriptionTopology(channels: ["entity-id"]),
        SubscriptionTopology(channels: ["relationship-id"])
      ]
    )
  }

  func testKMPDataSyncSubscribables_MirrorSwiftReferencesAndProjectionSubscriptions() {
    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let kmpPubNub = KMPPubNub(pubnub: pubnub)
    let references: [KMPDataSyncReference] = [
      kmpPubNub.dataSyncUser(with: "user-id"),
      kmpPubNub.dataSyncChannel(with: "channel-id"),
      kmpPubNub.dataSyncMembership(with: "membership-id"),
      kmpPubNub.dataSyncEntity(with: "entity-id"),
      kmpPubNub.dataSyncRelationship(with: "relationship-id")
    ]

    XCTAssertEqual(
      references.map(\.id),
      ["user-id", "channel-id", "membership-id", "entity-id", "relationship-id"]
    )
    XCTAssertEqual(
      references.map { KMPSubscription(entity: $0).subscription.subscriptionTopology },
      [
        SubscriptionTopology(channels: ["user-id"]),
        SubscriptionTopology(channels: ["channel-id"]),
        SubscriptionTopology(channels: ["membership-id"]),
        SubscriptionTopology(channels: ["entity-id"]),
        SubscriptionTopology(channels: ["relationship-id"])
      ]
    )
    XCTAssertEqual(
      references.map { $0.subscription(withProjection: "details").subscription.subscriptionTopology },
      [
        SubscriptionTopology(channels: ["__details__user-id"]),
        SubscriptionTopology(channels: ["__details__channel-id"]),
        SubscriptionTopology(channels: ["__details__membership-id"]),
        SubscriptionTopology(channels: ["__details__entity-id"]),
        SubscriptionTopology(channels: ["__details__relationship-id"])
      ]
    )
  }

  func testSubscription_WithListeners_OnMessage() {
    let expectation = XCTestExpectation(description: "Message")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    let listener = EventListener(onMessage: { _ in
      expectation.fulfill()
    })

    subscription.addEventListener(listener)
    subscription.onPayloadsReceived(payloads: [
      mockMessagePayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_WithListeners_OnSignal() {
    let expectation = XCTestExpectation(description: "Signal")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    let listener = EventListener(onSignal: { _ in
      expectation.fulfill()
    })

    subscription.addEventListener(listener)
    subscription.onPayloadsReceived(payloads: [
      mockSignalPayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_WithListeners_OnPresence() {
    let expectation = XCTestExpectation(description: "Presence")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    let listener = EventListener(onPresence: { _ in
      expectation.fulfill()
    })

    subscription.addEventListener(listener)
    subscription.onPayloadsReceived(payloads: [
      mockPresenceChangePayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_WithListeners_OnMessageAction() {
    let expectation = XCTestExpectation(description: "Message Action")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    let listener = EventListener(onMessageAction: { _ in
      expectation.fulfill()
    })

    subscription.addEventListener(listener)
    subscription.onPayloadsReceived(payloads: [
      mockMessageActionPayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_WithListeners_OnFileEvent() {
    let expectation = XCTestExpectation(description: "File")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    let listener = EventListener(onFileEvent: { _ in
      expectation.fulfill()
    })

    subscription.addEventListener(listener)
    subscription.onPayloadsReceived(payloads: [
      mockFilePayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_WithListeners_OnAppContext() {
    let expectation = XCTestExpectation(description: "App Context")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    let listener = EventListener(onAppContext: { _ in
      expectation.fulfill()
    })

    subscription.addEventListener(listener)
    subscription.onPayloadsReceived(payloads: [
      mockAppContextPayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }

  func testSubscription_WithListeners_OnDataSync() {
    let expectation = XCTestExpectation(description: "DataSync")
    expectation.assertForOverFulfill = true

    let pubnub = TestPubNubFactory.make(publishKey: "pubKey", subscribeKey: "subKey", userId: "userId")
    let channel = pubnub.channel("test-channel")
    let subscription = channel.subscription()

    let listener = EventListener(onDataSync: { _ in
      expectation.fulfill()
    })

    subscription.addEventListener(listener)
    subscription.onPayloadsReceived(payloads: [
      mockDataSyncPayload(channel: channel.name)
    ])

    wait(for: [expectation], timeout: 1.0)
  }
}
