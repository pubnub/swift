//
//  SubscribeRouterTests+MessageAction.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

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

// MARK: Helpers

private extension PubNubEvent {

  var addedMessageAction: PubNubMessageAction? {
    guard case let .messageActionChanged(.added(a)) = self else { return nil }
    return a
  }

  var removedMessageAction: PubNubMessageAction? {
    guard case let .messageActionChanged(.removed(a)) = self else { return nil }
    return a
  }
}
