//
//  Test+PubNubSpace.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
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

import PubNub
@testable import PubNubSpace

import XCTest

class PubNubSpaceModelTests: XCTestCase {
  let testSpace = PubNubSpace(
    id: "TestSpaceId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    spaceDescription: "TestDescription",
    custom: SpaceCustom(value: "Tester"),
    updated: Date.distantPast,
    eTag: "TestETag"
  )

  let spaceJSON = """
  {
    "id": "TestSpaceId",
    "name": "TestName",
    "type": "TestType",
    "status": "TestStatus",
    "description": "TestDescription",
    "custom": {"value": "Tester"},
    "updated": "0001-01-01T00:00:00.000Z",
    "eTag": "TestETag"
  }
  """

  func testPubNubSpace_Codable() throws {
    let data = try Constant.jsonEncoder.encode(testSpace)
    let spaceFromJSON = try Constant.jsonDecoder.decode(PubNubSpace.self, from: data)

    XCTAssertEqual(testSpace, spaceFromJSON)
  }

  func testPubNubSpace_FromJSON() throws {
    guard let data = spaceJSON.data(using: .utf8) else {
      XCTFail("Could not encode data")
      return
    }

    let spaceFromJSON = try Constant.jsonDecoder.decode(PubNubSpace.self, from: data)

    XCTAssertEqual(testSpace, spaceFromJSON)
  }

  func testPubNubSpace_Init() {
    let testSpace = PubNubSpace(
      id: "TestSpaceId",
      name: "TestName",
      type: "TestType",
      status: "TestStatus",
      spaceDescription: "TestDescription",
      custom: SpaceCustom(value: "Tester"),
      updated: Date.distantPast,
      eTag: "TestETag"
    )

    XCTAssertEqual("TestSpaceId", testSpace.id)
    XCTAssertEqual("TestName", testSpace.name)
    XCTAssertEqual("TestType", testSpace.type)
    XCTAssertEqual("TestStatus", testSpace.status)
    XCTAssertEqual("TestDescription", testSpace.spaceDescription)
    XCTAssertTrue(SpaceCustom(value: "Tester").codableValue == testSpace.custom?.codableValue)
    XCTAssertEqual(Date.distantPast, testSpace.updated)
    XCTAssertEqual("TestETag", testSpace.eTag)
  }

  func testPubNubSpace_Hasher() {
    var hasher = Hasher()
    hasher.combine(testSpace.id)
    hasher.combine(testSpace.name)
    hasher.combine(testSpace.type)
    hasher.combine(testSpace.status)
    hasher.combine(testSpace.spaceDescription)
    hasher.combine(testSpace.custom?.codableValue)
    hasher.combine(testSpace.updated)
    hasher.combine(testSpace.eTag)

    XCTAssertEqual(testSpace.hashValue, hasher.finalize())
  }

  func testPubNubSpace_Convert_UUIDMetadata() {
    let channelMetadata = PubNubChannelMetadataBase(
      metadataId: testSpace.id,
      name: testSpace.name,
      type: testSpace.type,
      status: testSpace.status,
      channelDescription: testSpace.spaceDescription,
      custom: testSpace.custom?.flatJSON,
      updated: testSpace.updated,
      eTag: testSpace.eTag
    )

    XCTAssertEqual(testSpace, channelMetadata.convert())
  }

  func testPubNubSpace_Convert_UUIDMetadata_nilCustom() {
    let channelMetadata = PubNubChannelMetadataBase(
      metadataId: testSpace.id,
      name: testSpace.name,
      type: testSpace.type,
      status: testSpace.status,
      channelDescription: testSpace.spaceDescription,
      custom: nil,
      updated: testSpace.updated,
      eTag: testSpace.eTag
    )
    var testSpace = testSpace
    testSpace.custom = nil

    XCTAssertEqual(testSpace, channelMetadata.convert())
  }
}
