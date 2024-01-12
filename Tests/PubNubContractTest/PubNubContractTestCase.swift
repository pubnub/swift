//
//  PubNubContractTestCase.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Cucumberish
import Foundation
import PubNub

// Origin which should be used to reach mock server for contract testing.
let mockServerAddress = "localhost:8090"
let defaultSubscribeKey = "demo-36"
let defaultPublishKey = "demo-36"

@objc public class PubNubContractTestCase: XCTestCase {
  
  fileprivate var listener: SubscriptionListener!
  
  public var messageReceivedHandler: ((PubNubMessage, [PubNubMessage]) -> Void)?
  public var statusReceivedHandler: ((SubscriptionListener.StatusEvent, [SubscriptionListener.StatusEvent]) -> Void)?
  public var presenceChangeReceivedHandler: ((PubNubPresenceChange, [PubNubPresenceChange]) -> Void)?

  fileprivate static var _receivedErrorStatuses: [SubscriptionListener.StatusEvent] = []
  fileprivate static var _receivedStatuses: [SubscriptionListener.StatusEvent] = []
  fileprivate static var _receivedMessages: [PubNubMessage] = []
  fileprivate static var _receivedPresenceChanges: [PubNubPresenceChange] = []

  fileprivate static var _currentScenario: CCIScenarioDefinition?
  fileprivate static var _apiCallResults: [Any] = []
  
  fileprivate static var _currentConfiguration = PubNubContractTestCase._defaultConfiguration
  fileprivate static var _defaultConfiguration: PubNubConfiguration {
    PubNubConfiguration(
      publishKey: defaultPublishKey,
      subscribeKey: defaultSubscribeKey,
      userId: UUID().uuidString,
      useSecureConnections: false,
      origin: mockServerAddress,
      supressLeaveEvents: true
    )
  }
    
  fileprivate static var currentClient: PubNub?

  public var configuration: PubNubConfiguration { PubNubContractTestCase._currentConfiguration }

  public var expectSubscribeFailure: Bool { false }

  public var expectSubscribeRetry: Bool { false }

  public var currentScenario: CCIScenarioDefinition? { PubNubContractTestCase._currentScenario }

  public var scenarioSteps: [CCIStep]? { PubNubContractTestCase._currentScenario?.steps }

  public var currentStep: CCIStep { CCIStepsManager.instance().currentStep }

  public var receivedErrorStatuses: [SubscriptionListener.StatusEvent] {
    get { PubNubContractTestCase._receivedErrorStatuses }
    set { PubNubContractTestCase._receivedErrorStatuses = newValue }
  }

  public var receivedStatuses: [SubscriptionListener.StatusEvent] {
    get { PubNubContractTestCase._receivedStatuses }
    set { PubNubContractTestCase._receivedStatuses = newValue }
  }

  public var receivedMessages: [PubNubMessage] {
    get { PubNubContractTestCase._receivedMessages }
    set { PubNubContractTestCase._receivedMessages = newValue }
  }
  
  public var receivedPresenceChanges: [PubNubPresenceChange] {
    get { PubNubContractTestCase._receivedPresenceChanges }
    set { PubNubContractTestCase._receivedPresenceChanges = newValue }
  }

  public var apiCallResults: [Any] {
    get { PubNubContractTestCase._apiCallResults }
    set { PubNubContractTestCase._apiCallResults = newValue }
  }

  public var client: PubNub {
    if PubNubContractTestCase.currentClient == nil {
      PubNubContractTestCase.currentClient = createPubNubClient()
    }
    return PubNubContractTestCase.currentClient!
  }
  
  func replacePubNubConfiguration(with configuration: PubNubConfiguration) {
    if PubNubContractTestCase.currentClient != nil {
      preconditionFailure("Cannot replace configuration when PubNub instance was already created")
    }
    PubNubContractTestCase._currentConfiguration = configuration
  }
  
  func createPubNubClient() -> PubNub {
    PubNub(configuration: configuration)
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
    PubNubContractTestCase._currentConfiguration = PubNubContractTestCase._defaultConfiguration
    PubNubContractTestCase.currentClient?.unsubscribeAll()
    PubNubContractTestCase.currentClient = nil

    receivedErrorStatuses.removeAll()
    receivedStatuses.removeAll()
    receivedMessages.removeAll()
    receivedPresenceChanges.removeAll()
    apiCallResults.removeAll()
  }

  @objc public func setup() {
    before { scenario in
      guard let scenario = scenario else { return }
      PubNubContractTestCase._currentScenario = scenario
      if self.shouldSetupMockServerFor(scenario: scenario) {
        XCTAssertNotNil(self.setupMockServerFor(scenario: scenario), "Unable to get server init response")
      }
      NotificationCenter.default.post(name: .cucumberBeforeHook, object: nil)
    }

    after { scenario in
      guard let scenario = scenario else { return }
      PubNubContractTestCase._currentScenario = nil
      if self.shouldSetupMockServerFor(scenario: scenario) {
        XCTAssertNotNil(self.checkMockServerExpectationsFor(scenario: scenario), "Unable to get server init response")
      }
      NotificationCenter.default.post(name: .cucumberAfterHook, object: nil)
    }

    Given("the demo keyset") { _, _ in /* Nothing to do. Demo keys set by default if not explicitly set. */ }
    Given("the invalid keyset") { _, _ in /* Nothing to do. Demo keys set by default if not explicitly set. */ }
    Given("no auth key") { _, _ in /* Nothing to do. Auth key not used in default configuration. */ }
    Given("auth key") { _, _ in /* Nothing to do here. Auth key will should be added by test case. */ }
    Given("token") { _, _ in /* Nothing to do here. Auth token will should be added by test case. */ }
    Given("secret key") { _, _ in /* Nothing to do here. Swift SDK doesn't have ability to use 'secret key'. */ }

    Then("I receive successful response") { _, _ in
      let lastResult = self.lastResult()
      XCTAssertNotNil(lastResult, "There is no API calls results.")

      guard let result = lastResult else {
        XCTAssert(false, "Object is not Result type value")
        return
      }

      XCTAssertFalse(result is Error, "Last API call shouldn't fail.")
    }

    /// Not unified properly in feature files, so need to add duplicate to previous `Then(...)`
    Then("I receive a successful response") { _, _ in
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

    Then("I receive access denied status") { _, _ in
      let lastResult = self.receivedErrorStatuses.last
      XCTAssertNotNil(lastResult, "There is subscribe statuses.")

      guard let result = lastResult else {
        XCTAssert(false, "Object is not status type value")
        return
      }

      switch result {
      case .success:
        XCTAssert(false, "Expected access denied status")
      case let .failure(error):
        XCTAssertTrue(error.reason == .forbidden)
      }
    }

    Match(["*"], "I receive access denied status") { _, _ in
      let lastResult = self.receivedErrorStatuses.last
      XCTAssertNotNil(lastResult, "There is subscribe statuses.")

      guard let result = lastResult else {
        XCTAssert(false, "Object is not status type value")
        return
      }

      switch result {
      case .success:
        XCTAssert(false, "Expected access denied status")
      case let .failure(error):
        XCTAssertTrue(error.reason == .forbidden)
      }
    }

    PubNubAccessContractTestSteps().setup()
    PubNubFilesContractTestSteps().setup()
    PubNubHistoryContractTestSteps().setup()
    PubNubMessageActionsContractTestSteps().setup()
    PubNubPushContractTestSteps().setup()
    PubNubPublishContractTestSteps().setup()
    PubNubSubscribeContractTestSteps().setup()
    PubNubSubscribeEngineContractTestsSteps().setup()
    PubNubPresenceEngineContractTestsSteps().setup()
    PubNubTimeContractTestSteps().setup()
    PubNubCryptoModuleContractTestSteps().setup()
    
    /// Objects acceptance testins.
    PubNubObjectsContractTests().setup()
    PubNubObjectsChannelMetadataContractTestSteps().setup()
    PubNubObjectsUUIDMetadataContractTestSteps().setup()
    PubNubObjectsMembershipsContractTestSteps().setup()
    PubNubObjectsMembersContractTestSteps().setup()
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
    self.listener = SubscriptionListener()

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
      case let .failure(error):
        var statusCode = 200

        error.affected.forEach {
          switch $0 {
          case let .response(response):
            statusCode = response.statusCode
          default:
            break
          }
        }

        if strongSelf.receivedErrorStatuses.count > 0 && !strongSelf.expectSubscribeRetry {
          XCTAssert(false, "Unexpected subscribe retry")
        }

        strongSelf.receivedErrorStatuses.append(result)

        /// Mock server special case handling.
        let shouldIgnoreMockServerTeardown = strongSelf.isLastStep() && statusCode == 500

        if strongSelf.expectSubscribeFailure || shouldIgnoreMockServerTeardown {
          subscribeStatusExpect.fulfill()
        } else {
          XCTAssert(false, "Unexpected connection status")
        }
      }
    }

    listener.didReceiveMessage = { [weak self] message in
      guard let strongSelf = self else { return }
      strongSelf.receivedMessages.append(message)

      if let handler = strongSelf.messageReceivedHandler {
        handler(message, strongSelf.receivedMessages)
      }
    }
    
    listener.didReceivePresence = { [weak self] presenceChange in
      guard let strongSelf = self else { return }
      strongSelf.receivedPresenceChanges.append(presenceChange)
      
      if let handler = strongSelf.presenceChangeReceivedHandler {
        handler(presenceChange, strongSelf.receivedPresenceChanges)
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
  
  // MARK: - Presence
  
  @discardableResult
  public func waitForPresenceChanges(_: PubNub, count: Int) -> [PubNubPresenceChange]? {
    if receivedPresenceChanges.count < count {
      let receivedPresenceChangeExpectation = expectation(description: "Presence Events")
      receivedPresenceChangeExpectation.assertForOverFulfill = false
      presenceChangeReceivedHandler = { _, presenceChanges in
        if presenceChanges.count >= count {
          receivedPresenceChangeExpectation.fulfill()
        }
      }

      wait(for: [receivedPresenceChangeExpectation], timeout: 10.0)
    }

    defer {
      receivedPresenceChanges.removeAll()
    }
    
    if receivedPresenceChanges.count > count {
      return Array(receivedPresenceChanges[..<count])
    } else {
      return receivedPresenceChanges.count > 0 ? receivedPresenceChanges : nil
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

    return testCase.name.contains(feature)
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

  public func isNextStep(with name: String) -> Bool {
    guard let steps = scenarioSteps else { return false }
    guard let currentStepIdx = steps.firstIndex(of: currentStep), currentStepIdx + 1 < steps.count else { return false }
    let nextStep = steps[currentStepIdx + 1]

    return nextStep.fullName() == name || nextStep.text == name
  }

  public func hasStep(with name: String) -> Bool {
    guard let steps = scenarioSteps else { return false }

    return steps.map { $0.text }.contains(name) || steps.map { $0.fullName() }.contains(name)
  }

  fileprivate func isLastStep() -> Bool {
    let currentStep = CCIStepsManager.instance().currentStep
    let lastStep = PubNubContractTestCase._currentScenario?.steps.last

    return currentStep?.fullName() == lastStep?.fullName()
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

/// Membership helper for membership management steps.
public enum PubNubTestMembershipForAction {
  case add(PubNubMembershipMetadata)
  case remove(PubNubMembershipMetadata)
}
