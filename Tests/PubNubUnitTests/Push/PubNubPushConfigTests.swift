//
//  PubNubPushConfigTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

class PubNubPushConfigTests: XCTestCase {
  let fixtureTarget = PubNubPushTarget(topic: "com.pubnub", environment: .production)

  func test_PushTypeIsEncodedAsPushTypeKey() throws {
    let config = PubNubPushConfig(targets: [fixtureTarget], pushType: .voip)
    let data = try Constant.jsonEncoder.encode(config)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(json["push_type"] as? String, "voip")
  }

  func test_PushTypeIsNotSentIfNotProvided() throws {
    let config = PubNubPushConfig(targets: [fixtureTarget])
    let data = try Constant.jsonEncoder.encode(config)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertNil(json["push_type"])
  }

  func test_EveryPushTypeEncodesTheValueExpectedByAPNs() throws {
    let expectedRawValues: [PubNub.PushType: String] = [
      .alert: "alert",
      .background: "background",
      .location: "location",
      .voip: "voip",
      .complication: "complication",
      .fileProvider: "fileprovider",
      .mdm: "mdm",
      .liveActivity: "liveactivity",
      .pushToTalk: "pushtotalk"
    ]

    XCTAssertEqual(
      Set(expectedRawValues.keys),
      Set(PubNub.PushType.allCases)
    )

    for (pushType, expectedRawValue) in expectedRawValues {
      let data = try Constant.jsonEncoder.encode(PubNubPushConfig(targets: [fixtureTarget], pushType: pushType))
      let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

      XCTAssertEqual(json["push_type"] as? String, expectedRawValue)
    }
  }
}
