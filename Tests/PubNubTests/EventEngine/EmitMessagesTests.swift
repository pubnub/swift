//
//  EmitMessagesTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2023 PubNub Inc.
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

import Foundation
import XCTest

@testable import PubNub

fileprivate class MockListener: BaseSubscriptionListener {
  var onEmitMessagesCalled: ([SubscribeMessagePayload]) -> Void = { _ in }
  var onEmitSubscribeEventCalled: ((PubNubSubscribeEvent) -> Void) = { _ in }
  
  override func emit(batch: [SubscribeMessagePayload]) {
    onEmitMessagesCalled(batch)
  }
  override func emit(subscribe: PubNubSubscribeEvent) {
    onEmitSubscribeEventCalled(subscribe)
  }
}

class EmitMessagesTests: XCTestCase {
  private var listeners: [MockListener] = []
  
  override func setUp() {
    listeners = (0...2).map { _ in MockListener() }
    super.setUp()
  }
  
  override func tearDown() {
    listeners = []
    super.tearDown()
  }
  
  func testListener_WithMessage() {
    let expectation = XCTestExpectation(description: "Emit Messages")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = listeners.count
    
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
      listeners: listeners,
      messageCache: MessageCache()
    )
    
    listeners.forEach {
      $0.onEmitMessagesCalled = { receivedMessages in
        XCTAssertTrue(receivedMessages.elementsEqual(messages))
        expectation.fulfill()
      }
    }
    
    effect.performTask(completionBlock: { _ in
      PubNub.log.debug("Did finish performing EmitMessages effect")
    })
    
    wait(for: [expectation], timeout: 0.15)
  }
  
  func testListener_MessageCountExceededMaximum() {
    let expectation = XCTestExpectation(description: "Emit Messages")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = listeners.count
    
    let effect = EmitMessagesEffect(
      messages: (1...100).map {
        generateMessage(
          with: .message,
          payload: AnyJSON("Hello, it's message number \($0)")
        )
      },
      cursor: SubscribeCursor(timetoken: 12345, region: 11),
      listeners: listeners,
      messageCache: MessageCache()
    )
    
    listeners.forEach() {
      $0.onEmitSubscribeEventCalled = { event in
        if case let .errorReceived(error) = event {
          XCTAssertTrue(error.reason == .messageCountExceededMaximum)
          expectation.fulfill()
        }
      }
    }
    
    effect.performTask(completionBlock: { _ in
      PubNub.log.debug("Did finish performing EmitMessages effect")
    })
    
    wait(for: [expectation], timeout: 0.1)
  }
  
  func testEffect_SkipsDuplicatedMessages() {
    let expectation = XCTestExpectation(description: "Emit Messages")
    expectation.assertForOverFulfill = true
    expectation.expectedFulfillmentCount = listeners.count
    
    let effect = EmitMessagesEffect(
      messages: (1...50).map { _ in
        generateMessage(
          with: .message,
          payload: AnyJSON("Hello, it's a message")
        )
      },
      cursor: SubscribeCursor(timetoken: 12345, region: 11),
      listeners: listeners,
      messageCache: MessageCache()
    )
    
    listeners.forEach {
      $0.onEmitMessagesCalled = { messages in
        XCTAssertTrue(messages.count == 1)
        XCTAssertTrue(messages[0].payload == "Hello, it's a message")
        expectation.fulfill()
      }
    }
    
    effect.performTask(completionBlock: { _ in
      PubNub.log.debug("Did finish performing EmitMessages effect")
    })
    
    wait(for: [expectation], timeout: 0.1)
  }
  
  func testEffect_MessageCacheDropsTheOldestMessages() {
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
      listeners: listeners,
      messageCache: cache
    )
    
    effect.performTask(completionBlock: { _ in
      PubNub.log.debug("Did finish performing EmitMessages effect")
    })
    
    let allCachedMessages = cache.messagesArray.compactMap { $0 }
    let expectedDroppedMssgs = Array(initialMessages[0...9])
        
    for droppedMssg in expectedDroppedMssgs {
      XCTAssertFalse(allCachedMessages.contains(droppedMssg))
    }
    for newMessage in allCachedMessages {
      XCTAssertTrue(allCachedMessages.contains(newMessage))
    }
  }
}

fileprivate extension EmitMessagesTests {
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
      meta: nil
    )
  }
}
