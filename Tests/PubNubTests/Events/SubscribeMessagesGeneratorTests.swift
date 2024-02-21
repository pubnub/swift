//
//  SubscribeMessagesGeneratorTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
@testable import PubNub

func mockMessagePayload(
  channel: String = "channel",
  message: String = "Hello, this is a message"
) -> SubscribeMessagePayload {
  generateMessage(
    with: .message,
    channel: channel,
    payload: AnyJSON(message)
  )
}

func mockSignalPayload(
  channel: String = "channel"
) -> SubscribeMessagePayload {
  generateMessage(
    with: .signal,
    channel: channel,
    payload: "Hello, this is a signal"
  )
}

func mockAppContextPayload(
  channel: String = "channel"
) -> SubscribeMessagePayload {
  generateMessage(
    with: .object,
    channel: channel,
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

func mockMessageActionPayload(
  channel: String = "channel"
) -> SubscribeMessagePayload {
  generateMessage(
    with: .messageAction,
    channel: channel,
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

func mockFilePayload(
  channel: String = "channel"
) -> SubscribeMessagePayload {
  generateMessage(
    with: .file,
    channel: channel,
    payload: AnyJSON(FilePublishPayload(
      channel: channel,
      fileId: "",
      filename: "",
      size: 54556,
      contentType: "image/jpeg",
      createdDate: nil,
      additionalDetails: nil
    ))
  )
}

func mockPresenceChangePayload(
  channel: String = "channel"
) -> SubscribeMessagePayload {
  generateMessage(
    with: .presence,
    channel: channel,
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
  subscription: String? = nil,
  channel: String = "test-channel",
  publishTimetoken: SubscribeCursor = SubscribeCursor(timetoken: 122412, region: 1),
  payload: AnyJSON
) -> SubscribeMessagePayload {
  SubscribeMessagePayload(
    shard: "shard",
    subscription: subscription,
    channel: channel,
    messageType: type,
    payload: payload,
    flags: 123,
    publisher: "publisher",
    subscribeKey: "FakeKey",
    originTimetoken: nil,
    publishTimetoken: publishTimetoken,
    meta: nil,
    error: nil
  )
}
