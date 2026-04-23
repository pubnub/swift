//
//  PubNubSubscribeContractTestSteps.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Cucumberish
import Foundation
import PubNubSDK

public class PubNubSubscribeContractTestSteps: PubNubContractTestCase {
  fileprivate var cryptoModule: CryptoModule?

  override public var configuration: PubNubConfiguration {
    var config = super.configuration
    config.cryptoModule = cryptoModule

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
    cryptoModule = nil
    super.handleBeforeHook()
  }

  override public var expectSubscribeFailure: Bool {
    return self.hasStep(with: "I receive access denied status")
  }

  override public func setup() {
    startCucumberHookEventsListening()

    Given("^the crypto keyset$") { _, _ in
      self.cryptoModule = CryptoModule.legacyCryptoModule(with: "enigma")
    }

    Given("^the invalid-crypto keyset$") { _, _ in
      self.cryptoModule = CryptoModule.legacyCryptoModule(with: "secret")
    }
    
    When("^I subscribe$") { _, _ in
      self.subscribeSynchronously(self.client, to: ["test"])
      // Give some time to rotate received timetokens.
      self.waitFor(delay: 0.25)
    }
    
    When("^I subscribe to '(.*)' channel$") { args, _ in
      guard let matches = args, let channel = matches.first else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }
      
      self.subscribeSynchronously(self.client, to: [channel])
      // Give some time to rotate received timetokens.
      self.waitFor(delay: 0.25)
    }

    Then("^I receive (the|[0-9]+) message(s)? in my subscribe response$") { args, userInfo in
      guard let match = args?.first else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }

      let messages = self.waitForMessages(self.client, count: Int(match) ?? 1)
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
    
    Match(["And"], "^response contains messages with '(.*)' and '(.*)' types$") { args, _ in
      guard let matches = args else {
        XCTAssertNotNil(args?.first, "Step match failed")
        return
      }
      
      let messages = self.waitForMessages(self.client, count: 2)!
      XCTAssertNotNil(messages)
      
      let messagesWithTypes = messages.compactMap { $0.customMessageType }
      XCTAssertTrue(messagesWithTypes.map { $0.description }.allSatisfy { matches.contains($0) })
    }
  }
}
