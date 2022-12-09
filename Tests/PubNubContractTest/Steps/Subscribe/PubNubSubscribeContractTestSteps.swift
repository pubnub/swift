//
//  PubNubSubscribeContractTestSteps.swift
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

public class PubNubSubscribeContractTestSteps: PubNubContractTestCase {
  fileprivate var cipherKey: Crypto?

  override public var configuration: PubNubConfiguration {
    var config = super.configuration
    config.cipherKey = cipherKey

    if let scenario = self.currentScenario, scenario.name.contains("auto-retry") {
      config.automaticRetry = AutomaticRetry(retryLimit: 10, policy: .linear(delay: 0.1))
    }

    if hasStep(with: "Given auth key") {
      config.authKey = "auth"
    }

    if hasStep(with: "Given token") {
      config.authToken = "token"
    }

    return config
  }

  override public func handleBeforeHook() {
    cipherKey = nil
    super.handleBeforeHook()
  }

  override public var expectSubscribeFailure: Bool {
    return self.hasStep(with: "I receive access denied status")
  }

  override public func setup() {
    startCucumberHookEventsListening()

    Given("the crypto keyset") { _, _ in
      self.cipherKey = Crypto(key: "enigma")
    }

    Given("the invalid-crypto keyset") { _, _ in
      self.cipherKey = Crypto(key: "secret")
    }

    When("I subscribe") { _, _ in
      self.subscribeSynchronously(self.client, to: ["test"])
      // Give some time to rotate received timetokens.
      self.waitFor(delay: 0.25)
    }

    Then("I receive the message in my subscribe response") { _, userInfo in
      let messages = self.waitForMessages(self.client, count: 1)
      XCTAssertNotNil(messages)

      if self.checkTestingFeature(feature: "MessageEncryption", userInfo: userInfo!) {
        if let message = messages?.last {
          XCTAssertEqual(message.payload.rawValue as! String, "hello world")
        } else {
          XCTAssert(false, "Expected at least on message")
        }
      } else if self.checkTestingFeature(feature: "SubscribeLoop", userInfo: userInfo!) {
        // Give some time to rotate received timetokens.
        self.waitFor(delay: 0.25)
      }
    }

    Then("an error is thrown") { _, _ in
      let messages = self.waitForMessages(self.client, count: 1)
      XCTAssertNotNil(messages)

      if let message = messages?.last {
        let data = Data(base64Encoded: message.payload.rawValue as! String)
        XCTAssertNotNil(data, "Client shouldn't be able to decrypt message with wrong key.")
      } else {
        XCTAssert(false, "Expected at least on message")
      }

      self.waitFor(delay: 0.25)
    }

    Match(["*"], "I don't auto-retry subscribe") { _, _ in
      guard self.receivedErrorStatuses.last != nil else {
        XCTAssert(false, "Last status should be error.")
        return
      }

      /// Give some more time for SDK to check that it won't retry after 0.1 seconds.
      self.waitFor(delay: 0.3)
    }
  }
}
