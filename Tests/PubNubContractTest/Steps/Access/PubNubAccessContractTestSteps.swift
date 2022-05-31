//
//  PNAccessContractTestSteps.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2021 PubNub Inc.
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

import Cucumberish
import Foundation
import PubNub
import XCTest

public class PubNubAccessContractTestSteps: PubNubContractTestCase {
  var authToken: String!
  var token: PAMToken?

  override public func handleAfterHook() {
    token = nil
    super.handleAfterHook()
  }

  override public func setup() {
    startCucumberHookEventsListening()

    Given("I have a keyset with access manager enabled") { _, _ in
      // Do noting, because client doesn't support token grant.
    }

    Given("^I have a known token containing (.*)$") { _, _ in
      self.authToken = "qEF2AkF0GmEI03xDdHRsGDxDcmVzpURjaGFuoWljaGFubmVsLTEY70NncnChb2NoYW5uZWxfZ3JvdXAtMQVDdXNyoENzcGOgRHV1aWShZnV1aWQtMRhoQ3BhdKVEY2hhbqFtXmNoYW5uZWwtXFMqJBjvQ2dycKF0XjpjaGFubmVsX2dyb3VwLVxTKiQFQ3VzcqBDc3BjoER1dWlkoWpedXVpZC1cUyokGGhEbWV0YaBEdXVpZHR0ZXN0LWF1dGhvcml6ZWQtdXVpZENzaWdYIPpU-vCe9rkpYs87YUrFNWkyNq8CVvmKwEjVinnDrJJc"
    }

    When("I parse the token") { _, _ in
      self.token = self.client.parse(token: self.authToken)
    }

    Then("^the parsed token output contains the authorized UUID \"(.*)\"$") { args, _ in
      guard let token = self.token else {
        XCTAssertNotNil(self.token)
        return
      }

      guard let uuid = args?.first else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }

      XCTAssertNotNil(token.authorizedUUID)
      XCTAssertEqual(token.authorizedUUID, uuid)
    }

    Then("^the token has '(.*)' UUID (.*) access permissions$") { args, _ in
      guard let token = self.token else {
        XCTAssertNotNil(self.token)
        return
      }

      guard args?.count == 2, let uuid = args?.first, let type = args?.last else {
        XCTAssert(false, "Step match failed")
        return
      }

      let resource = type == "resource" ? token.resources : token.patterns

      XCTAssertGreaterThanOrEqual(resource.uuids.count, 1)
      XCTAssertNotNil(resource.uuids[uuid])
    }

    Match(["*"], "token (.*) permission GET") { args, _ in
      guard let token = self.token else {
        XCTAssertNotNil(self.token)
        return
      }

      guard let type = args?.first else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }

      let resource = type == "resource" ? token.resources : token.patterns

      guard let permission = Array(resource.uuids.values).last else {
        XCTAssert(false, "Expected at least one UUID \(type).")
        return
      }

      XCTAssertTrue(permission.contains(PAMPermission.get))
    }
  }
}
