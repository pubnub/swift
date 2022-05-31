//
//  PubNubContractTest.swift
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

// Origin which should be used to reach mock server for contract testing.
let mockServerAddress = "localhost:8090"
let defaultSubscribeKey = "demo-36"
let defaultPublishKey = "demo-36"

@objc public class PubNubContractTestCase: XCTestCase {
  public var messageReceivedHandler: ((PubNubMessage, [PubNubMessage]) -> Void)?
  public var statusReceivedHandler: ((SubscriptionListener.StatusEvent, [SubscriptionListener.StatusEvent]) -> Void)?
  fileprivate static var _receivedStatuses: [SubscriptionListener.StatusEvent] = []
  fileprivate static var _receivedMessages: [PubNubMessage] = []
  fileprivate static var _apiCallResults: [Any] = []
  fileprivate var currentConfiguration = PubNubConfiguration(publishKey: defaultPublishKey,
                                                             subscribeKey: defaultSubscribeKey,
                                                             uuid: UUID().uuidString,
                                                             useSecureConnections: false,
                                                             origin: mockServerAddress,
                                                             supressLeaveEvents: true)
  fileprivate static var currentClient: PubNub?

  public var configuration: PubNubConfiguration { currentConfiguration }

  public var receivedStatuses: [SubscriptionListener.StatusEvent] {
    get { PubNubContractTestCase._receivedStatuses }
    set { PubNubContractTestCase._receivedStatuses = newValue }
  }

  public var receivedMessages: [PubNubMessage] {
    get { PubNubContractTestCase._receivedMessages }
    set { PubNubContractTestCase._receivedMessages = newValue }
  }

  public var apiCallResults: [Any] {
    get { PubNubContractTestCase._apiCallResults }
    set { PubNubContractTestCase._apiCallResults = newValue }
  }

  public var client: PubNub {
    if PubNubContractTestCase.currentClient == nil {
      PubNubContractTestCase.currentClient = PubNub(configuration: configuration)
    }

    return PubNubContractTestCase.currentClient!
  }

  public func startCucumberHookEventsListening() {
    NotificationCenter.default.addObserver(forName: .cucumberBeforeHook, object: nil, queue: nil) { [weak self] _ in
      self?.handleBeforeHook()
    }
    NotificationCenter.default.addObserver(forName: .cucumberAfterHook, object: nil, queue: nil) { [weak self] _ in
      self?.handleAfterHook()
    }
  }

  public func handleBeforeHook() {
    // Override if something custom required by test case.
  }

  public func handleAfterHook() {
    currentConfiguration = PubNubConfiguration(publishKey: defaultPublishKey,
                                               subscribeKey: defaultSubscribeKey,
                                               uuid: UUID().uuidString,
                                               useSecureConnections: false,
                                               origin: mockServerAddress,
                                               supressLeaveEvents: true)

    PubNubContractTestCase.currentClient?.unsubscribeAll()
    PubNubContractTestCase.currentClient = nil

    receivedStatuses.removeAll()
    receivedMessages.removeAll()
    apiCallResults.removeAll()
  }

  @objc public func setup() {
    before { scenario in
      guard let scenario = scenario else { return }
      if self.shouldSetupMockServerFor(scenario: scenario) {
        XCTAssertNotNil(self.setupMockServerFor(scenario: scenario), "Unable to get server init response")
      }
      NotificationCenter.default.post(name: .cucumberBeforeHook, object: nil)
    }

    after { scenario in
      guard let scenario = scenario else { return }
      if self.shouldSetupMockServerFor(scenario: scenario) {
        XCTAssertNotNil(self.checkMockServerExpectationsFor(scenario: scenario), "Unable to get server init response")
      }
      NotificationCenter.default.post(name: .cucumberAfterHook, object: nil)
    }

    Given("the demo keyset") { _, _ in
      // Nothing to do. Demo keys set by default if not explicitly set.
    }

    Given("the invalid keyset") { _, _ in
      // Nothing to do. Demo keys set by default if not explicitly set.
    }

    Then("I receive successful response") { _, _ in
      let lastResult = self.lastResult()
      XCTAssertNotNil(lastResult, "There is no API calls results.")

      guard let result = lastResult else {
        XCTAssert(false, "Object is not Result type value")
        return
      }

      XCTAssertFalse(result is Error, "Last API call shouldn't fail.")
    }

    Then("I receive error response") { _, _ in
      let lastResult = self.lastResult()
      XCTAssertNotNil(lastResult, "There is no API calls results.")

      guard let result = lastResult else {
        XCTAssert(false, "Object is not Result type value")
        return
      }

      XCTAssertTrue(result is Error, "Last API call should report error")
    }

    PubNubAccessContractTestSteps().setup()
    PubNubFilesContractTestSteps().setup()
    PubNubHistoryContractTestSteps().setup()
    PubNubMessageActionsContractTestSteps().setup()
    PubNubPushContractTestSteps().setup()
    PubNubPublishContractTestSteps().setup()
    PubNubSubscribeContractTestSteps().setup()
    PubNubTimeContractTestSteps().setup()
  }

  // MARK: - Subscription

  public func subscribeSynchronously(
    _ client: PubNub,
    to channels: [String] = [],
    and groups: [String] = [],
    with presence: Bool = false,
    timetoken: Timetoken? = 0
  ) {
    let subscribeStatusExpect = expectation(description: "Subscribe statuses")
    subscribeStatusExpect.assertForOverFulfill = false
    let listener = SubscriptionListener()

    listener.didReceiveStatus = { [weak self] result in
      guard let strongSelf = self else { return }
      strongSelf.receivedStatuses.append(result)

      if let handler = strongSelf.statusReceivedHandler {
        handler(result, strongSelf.receivedStatuses)
      }

      switch result {
      case let .success(status):
        if status == .connected {
          subscribeStatusExpect.fulfill()
        }
      default:
        XCTAssert(false, "Unexpected connection status")
      }
    }

    listener.didReceiveMessage = { [weak self] message in
      guard let strongSelf = self else { return }
      strongSelf.receivedMessages.append(message)

      if let handler = strongSelf.messageReceivedHandler {
        handler(message, strongSelf.receivedMessages)
      }
    }

    client.add(listener)
    client.subscribe(to: channels, and: groups, at: timetoken, withPresence: presence)

    wait(for: [subscribeStatusExpect], timeout: 10.0)
  }

  public func waitForMessages(_: PubNub, count: Int) -> [PubNubMessage]? {
    if receivedMessages.count < count {
      let subscribeMessageExpect = expectation(description: "Subscribe messages")
      subscribeMessageExpect.assertForOverFulfill = false
      messageReceivedHandler = { _, messages in
        if messages.count >= count {
          subscribeMessageExpect.fulfill()
        }
      }

      wait(for: [subscribeMessageExpect], timeout: 30.0)
    }

    if receivedMessages.count > count {
      return Array(receivedMessages[..<count])
    } else {
      return receivedMessages.count > 0 ? receivedMessages : nil
    }
  }

  // MARK: - Results handling

  public func handleResult(result: Any) {
    apiCallResults.append(result)
  }

  public func lastResult() -> Any? {
    apiCallResults.last
  }

  // MARK: - Helpers

  public func checkTestingFeature(feature: String, userInfo: [AnyHashable: Any]) -> Bool {
    guard let testCase = userInfo["XCTestCase"] as? XCTestCase else {
      XCTAssert(false, "Unable to check tested feature.")
      return false
    }

    return testCase.name.contains("CCI\(feature)")
  }

  fileprivate func setupMockServerFor(scenario: CCIScenarioDefinition) -> Data? {
    guard let contract = contractFor(scenario: scenario) else { return nil }
    guard let url = URL(string: "http://\(mockServerAddress)/init?__contract__script__=\(contract)") else { return nil }

    return synchronousMockServerRequestWith(url: url)
  }

  fileprivate func checkMockServerExpectationsFor(scenario _: CCIScenarioDefinition) -> Data? {
    guard let url = URL(string: "http://\(mockServerAddress)/expect") else { return nil }

    return synchronousMockServerRequestWith(url: url)
  }

  fileprivate func synchronousMockServerRequestWith(url: URL) -> Data? {
    let serverSetupExpect = expectation(description: "Files list Response")
    var responseData: Data?

    URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
      responseData = data
      if let error = error {
        XCTAssertNil(error, "Mock server call error: \(error)")
      }

      serverSetupExpect.fulfill()
    }).resume()

    wait(for: [serverSetupExpect], timeout: 5.0)

    return responseData
  }

  fileprivate func shouldSetupMockServerFor(scenario: CCIScenarioDefinition?) -> Bool {
    contractFor(scenario: scenario) != nil
  }

  fileprivate func contractFor(scenario: CCIScenarioDefinition?) -> String? {
    guard let scenario = scenario else { return nil }
    var contract: String?

    for tag in scenario.tags {
      if tag.hasPrefix("contract=") {
        contract = tag.components(separatedBy: "=").last
        break
      }
    }

    return contract
  }

  public func waitFor(delay: TimeInterval) {
    let waitExpectation = expectation(description: "Execution wait for \(delay)")

    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      waitExpectation.fulfill()
    }

    wait(for: [waitExpectation], timeout: delay * 2)
  }
}

extension Notification.Name {
  static let cucumberBeforeHook = Notification.Name("cucumberBeforeHook")
  static let cucumberAfterHook = Notification.Name("cucumberAfterHook")
}
