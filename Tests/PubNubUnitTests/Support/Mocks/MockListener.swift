//
//  MockListener.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

@testable import PubNubSDK

class MockListener: BaseSubscriptionListener {
  var onEmitMessagesCalled: ([SubscribeMessagePayload]) -> Void = { _ in }
  var onEmitSubscribeEventCalled: ((PubNubSubscribeEvent) -> Void) = { _ in }

  override func emit(batch: [SubscribeMessagePayload]) {
    onEmitMessagesCalled(batch)
  }

  override func emit(subscribe: PubNubSubscribeEvent) {
    onEmitSubscribeEventCalled(subscribe)
  }
}
