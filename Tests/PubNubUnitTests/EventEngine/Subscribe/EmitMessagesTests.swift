//
//  EmitMessagesTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import XCTest

@testable import PubNubSDK

class EmitMessagesTests: XCTestCase {
  func test_EmitMessages_DeliversAllMessageTypesToListeners() throws {
    let subscriptions = makeListeners()

    let expectation = XCTestExpectation(description: "Emit Messages")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = subscriptions.count

    let messages = [
      testMessage,
      testSignal,
      testObject,
      testMessageAction,
      testFile,
      testPresenceChange
    ]

    let effect = EmitMessagesEffect(
      messages: messages,
      cursor: SubscribeCursor(timetoken: 12345, region: 11),
      subscriptions: WeakSet(subscriptions),
      messageCache: MessageCache()
    )

    subscriptions.forEach {
      $0.onEmitMessagesCalled = { receivedMessages in
        XCTAssertTrue(receivedMessages.map { $0.messageType } == messages.map { $0.messageType })
        expectation.fulfill()
      }
    }

    effect.performTask(completionBlock: { _ in })

    wait(for: [expectation], timeout: 0.35)
  }

  func test_EmitMessages_WhenCountExceedsMaximum_EmitsErrorToListeners() throws {
    let subscriptions = makeListeners()

    let expectation = XCTestExpectation(description: "Emit Messages")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = subscriptions.count

    let generatedMessages = (1...100).map {
      generateMessage(
        with: .message,
        payload: AnyJSON("Hello, it's message number \($0)")
      )
    }

    let effect = EmitMessagesEffect(
      messages: generatedMessages,
      cursor: SubscribeCursor(timetoken: 12345, region: 11),
      subscriptions: WeakSet(subscriptions),
      messageCache: MessageCache()
    )

    subscriptions.forEach {
      $0.onEmitSubscribeEventCalled = { event in
        if case let .errorReceived(error) = event {
          XCTAssertTrue(error.reason == .messageCountExceededMaximum)
        } else {
          XCTFail("Expected .errorReceived but received \(event)")
        }
        expectation.fulfill()
      }
    }

    effect.performTask(completionBlock: { _ in })

    wait(for: [expectation], timeout: 0.1)
  }

  func test_EmitMessages_WithDuplicateMessages_SkipsDuplicates() throws {
    let subscriptions = makeListeners()

    let expectation = XCTestExpectation(description: "Emit Messages")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = subscriptions.count

    let generatedMessages = (1...50).map { _ in
      generateMessage(
        with: .message,
        payload: AnyJSON("Hello, it's a message")
      )
    }
    let effect = EmitMessagesEffect(
      messages: generatedMessages,
      cursor: SubscribeCursor(timetoken: 12345, region: 11),
      subscriptions: WeakSet(subscriptions),
      messageCache: MessageCache()
    )

    subscriptions.forEach {
      $0.onEmitMessagesCalled = { messages in
        XCTAssertEqual(messages.count, 1, "Expected to produce exactly one message")
        XCTAssertEqual(messages.first?.payload, "Hello, it's a message")
        expectation.fulfill()
      }
    }

    effect.performTask(completionBlock: { _ in })

    wait(for: [expectation], timeout: 0.1)
  }

  func test_EmitMessages_WhenCacheFull_DropsOldestMessages() throws {
    let subscriptions = makeListeners()

    let initialMessages = (1...99).map { idx in
      generateMessage(
        with: .message,
        payload: AnyJSON("Hello, it's a message \(idx)")
      )
    }
    let newMessages = (1...10).map { idx in
      generateMessage(
        with: .message,
        payload: AnyJSON("Hello again, it's a message \(idx)")
      )
    }
    let cache = MessageCache(
      messagesArray: initialMessages
    )
    let effect = EmitMessagesEffect(
      messages: newMessages,
      cursor: SubscribeCursor(timetoken: 12345, region: 11),
      subscriptions: WeakSet(subscriptions),
      messageCache: cache
    )

    let completionExpect = expectation(description: "Effect completed")

    effect.performTask(completionBlock: { _ in
      completionExpect.fulfill()
    })

    wait(for: [completionExpect], timeout: 1.0)

    let allCachedMessages = cache.messagesArray.compactMap { $0 }
    let expectedDroppedMssgs = Array(initialMessages[0...9])

    for droppedMssg in expectedDroppedMssgs {
      XCTAssertFalse(allCachedMessages.contains(droppedMssg))
    }
    for newMessage in newMessages {
      XCTAssertTrue(allCachedMessages.contains(newMessage))
    }
  }
}

private extension EmitMessagesTests {
  func makeListeners(count: Int = 3) -> [MockListener] {
    (0..<count).map { _ in MockListener() }
  }

  var testMessage: SubscribeMessagePayload {
    generateMessage(
      with: .message,
      payload: "Hello, this is a message"
    )
  }

  var testSignal: SubscribeMessagePayload {
    generateMessage(
      with: .signal,
      payload: "Hello, this is a signal"
    )
  }

  var testObject: SubscribeMessagePayload {
    generateMessage(
      with: .object,
      payload: AnyJSON(
        SubscribeObjectMetadataPayload(
          source: "123",
          version: "456",
          event: .delete,
          type: .uuid,
          subscribeEvent: .uuidMetadataRemoved(metadataId: "12345")
        )
      )
    )
  }

  var testMessageAction: SubscribeMessagePayload {
    generateMessage(
      with: .messageAction,
      payload: AnyJSON(
        [
          "event": "added",
          "source": "actions",
          "version": "1.0",
          "data": [
            "messageTimetoken": "16844114408637596",
            "type": "receipt",
            "actionTimetoken": "16844114409339370",
            "value": "read"
          ]
        ] as [String: Any]
      )
    )
  }

  var testFile: SubscribeMessagePayload {
    generateMessage(
      with: .file,
      payload: AnyJSON(FilePublishPayload(
        channel: "",
        fileId: "",
        filename: "",
        size: 54556,
        contentType: "image/jpeg",
        createdDate: nil,
        additionalDetails: nil
      ))
    )
  }

  var testPresenceChange: SubscribeMessagePayload {
    generateMessage(
      with: .presence,
      payload: AnyJSON(
        SubscribePresencePayload(
          actionEvent: .join,
          occupancy: 15,
          uuid: nil,
          timestamp: 123123,
          refreshHereNow: false,
          state: nil,
          join: ["dsadf", "fdsa"],
          leave: [],
          timeout: []
        )
      )
    )
  }

  func generateMessage(
    with type: SubscribeMessagePayload.Action,
    payload: AnyJSON
  ) -> SubscribeMessagePayload {
    SubscribeMessagePayload(
      shard: "shard",
      subscription: nil,
      channel: "test-channel",
      messageType: type,
      payload: payload,
      flags: 123,
      publisher: "publisher",
      subscribeKey: "FakeKey",
      originTimetoken: nil,
      publishTimetoken: SubscribeCursor(timetoken: 12312412412, region: 12),
      meta: nil,
      error: nil
    )
  }
}
