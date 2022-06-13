//
//  Test+PubNubMembershipEvent.swift
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

@testable import PubNubMembership
import PubNub
import PubNubUser
import PubNubSpace

import XCTest

class PubNubMembershipEventTests: XCTestCase {

  let testMembership = PubNubMembership(
    user: PubNubUser(id: "TestUserId"),
    space: PubNubSpace(id: "TestSpaceId"),
    status: "TestStatus",
    custom: MembershipCustom(value: "Tester"),
    updated: Date.distantFuture,
    eTag: "TestETag"
  )
  
  var listener = PubNubMembershipListener()
  
  func testMembershipListener_Emit_UpdateEvent() {
    let expectation = XCTestExpectation(description: "Membership Update Event")
    expectation.expectedFulfillmentCount = 2
    
    let entityEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .updated,
      type: .membership,
      data: [
        "uuid": ["id": testMembership.user.id],
        "channel": ["id": testMembership.space.id],
        "status": testMembership.status,
        "custom": ["value": "Tester"],
        "updated": "4001-01-01T00:00:00.000Z",
        "eTag": testMembership.eTag
      ]
    )

    let malformedEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .updated,
      type: .membership,
      data: AnyJSON("")
    )
    
    listener.didReceiveMembershipEvents = { [unowned self] events in
      for event in events {
        switch event {
        case let .membershipUpdated(membership):
          XCTAssertEqual(membership, testMembership)
        case .membershipRemoved:
          XCTFail("Membership Removed Event should not fire")
        }
      }
      expectation.fulfill()
    }
    
    listener.didReceiveMembershipEvent = { [unowned self] event in
      switch event {
      case let .membershipUpdated(membership):
        XCTAssertEqual(membership, testMembership)
      case .membershipRemoved:
        XCTFail("Membership Removed Event should not fire")
      }
      expectation.fulfill()
    }
    
    listener.emit(entity: [malformedEvent, entityEvent])
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testMembershipListener_Emit_RemoveEvent() {
    let expectation = XCTestExpectation(description: "Membership Update Event")
    expectation.expectedFulfillmentCount = 2
    
    let entityEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .removed,
      type: .membership,
      data: [
        "uuid": ["id": testMembership.user.id],
        "channel": ["id": testMembership.space.id],
        "status": testMembership.status,
        "custom": ["value": "Tester"],
        "updated": "4001-01-01T00:00:00.000Z",
        "eTag": testMembership.eTag
      ]
    )
    
    let malformedEvent = PubNubEntityEvent(
      source: "objects",
      version: "2.0",
      action: .removed,
      type: .membership,
      data: AnyJSON("")
    )
    
    listener.didReceiveMembershipEvents = { [unowned self] events in
      for event in events {
        switch event {
        case let .membershipRemoved(membership):
          XCTAssertEqual(membership, testMembership)
        case .membershipUpdated:
          XCTFail("Membership Updated Event should not fire")
        }
      }
      expectation.fulfill()
    }
    
    listener.didReceiveMembershipEvent = { [unowned self] event in
      switch event {
      case let .membershipRemoved(membership):
        XCTAssertEqual(membership, testMembership)
      case .membershipUpdated:
        XCTFail("Membership Updated Event should not fire")
      }
      expectation.fulfill()
    }
    
    listener.emit(entity: [malformedEvent, entityEvent])
    
    wait(for: [expectation], timeout: 1.0)
  }
}

