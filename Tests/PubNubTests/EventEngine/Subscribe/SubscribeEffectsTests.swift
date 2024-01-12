//
//  SubscribeEffectTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import XCTest

@testable import PubNub

class SubscribeEffectsTests: XCTestCase {
  private var mockUrlSession: MockURLSession!
  private var httpSession: HTTPSession!
  private var delegate: HTTPSessionDelegate!
  private var factory: SubscribeEffectFactory!
  
  private let config = PubNubConfiguration(
    publishKey: "pubKey",
    subscribeKey: "subKey",
    userId: "userId",
    automaticRetry: AutomaticRetry(
      retryLimit: 3,
      policy: .linear(delay: 2.0)
    )
  )
  
  private func configWithLinearPolicy(_ delay: Double = 2.0) -> PubNubConfiguration {
    PubNubConfiguration(
      publishKey: "pubKey",
      subscribeKey: "subKey",
      userId: "userId",
      automaticRetry: AutomaticRetry(retryLimit: 3, policy: .linear(delay: delay), excluded: [])
    )
  }
  
  override func setUp() {
    delegate = HTTPSessionDelegate()
    mockUrlSession = MockURLSession(delegate: delegate)
    httpSession = HTTPSession(session: mockUrlSession, delegate: delegate, sessionQueue: .main)
    factory = SubscribeEffectFactory(session: httpSession, presenceStateContainer: .shared)
    super.setUp()
  }
  
  override func tearDown() {
    mockUrlSession = nil
    delegate = nil
    httpSession = nil
    super.tearDown()
  }
}

// MARK: - HandshakingEffect

extension SubscribeEffectsTests {
  func test_HandshakingEffectWithSuccessResponse() {
    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: []
    ))
    runEffect(
      configuration: config,
      invocation: .handshakeRequest(
        channels: ["channel1", "channel1-pnpres", "channel2"],
        groups: ["g1", "g2", "g2-pnpres"]
      ),
      expectedOutput: [
        .handshakeSuccess(
          cursor: SubscribeCursor(
            timetoken: 12345,
            region: 1
          )
        )
      ]
    )
  }
  
  func test_HandshakingEffectWithFailedResponse() {
    mockResponse(
      errorIfAny: URLError(.cannotFindHost),
      httpResponse: HTTPURLResponse(statusCode: 404)!
    )
    runEffect(
      configuration: config,
      invocation: .handshakeRequest(
        channels: ["channel1", "channel1-pnpres", "channel2"],
        groups: ["g1", "g2", "g2-pnpres"]
      ), expectedOutput: [
        .handshakeFailure(
          error: PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost))
        )
      ]
    )
  }
}

// MARK: ReceivingEffect

extension SubscribeEffectsTests {
  func test_ReceivingEffectWithSuccessResponse() {
    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: [firstMessage, secondMessage]
    ))
    runEffect(
      configuration: config,
      invocation: .receiveMessages(
        channels: ["channel1", "channel1-pnpres", "channel2"],
        groups: ["g1", "g2", "g2-pnpres"],
        cursor: SubscribeCursor(timetoken: 111, region: 1)
      ), expectedOutput: [
        .receiveSuccess(
          cursor: SubscribeCursor(timetoken: 12345, region: 1),
          messages: [firstMessage, secondMessage]
        )
      ]
    )
  }
  
  func test_ReceivingEffectWithFailedResponse() {
    mockResponse(
      errorIfAny: URLError(.cannotFindHost),
      httpResponse: HTTPURLResponse(statusCode: 404)!
    )
    runEffect(
      configuration: config,
      invocation: .receiveMessages(
        channels: ["channel1", "channel1-pnpres", "channel2"],
        groups: ["g1", "g2", "g2-pnpres"],
        cursor: SubscribeCursor(timetoken: 111, region: 1)
    ), expectedOutput: [
      .receiveFailure(
        error: PubNubError(.nameResolutionFailure, underlying: URLError(.cannotFindHost))
      )
    ])
  }
}

// MARK: - HandshakeReconnecting

extension SubscribeEffectsTests {
  func test_HandshakeReconnectingSuccess() {
    let delayRange = 2.0...3.0
    let urlError = URLError(.badServerResponse)
    let httpUrlResponse = HTTPURLResponse(statusCode: 500)!
    let pubNubError = PubNubError(urlError.pubnubReason!, underlying: urlError, affected: [.response(httpUrlResponse)])

    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: []
    ))
    runEffect(
      configuration: configWithLinearPolicy(delayRange.lowerBound),
      invocation: .handshakeReconnect(
        channels: ["channel1", "channel1-pnpres", "channel2"],
        groups: ["g1", "g2", "g2-pnpres"],
        retryAttempt: 1,
        reason: pubNubError
      ),
      timeout: 2 * delayRange.upperBound,
      expectedOutput: [
        .handshakeReconnectSuccess(cursor: SubscribeCursor(
          timetoken: 12345,
          region: 1
        ))
      ]
    )
  }
  
  func test_HandshakeReconnectingFailed() {
    let delayRange = 2.0...3.0
    let urlError = URLError(.badServerResponse)
    let httpUrlResponse = HTTPURLResponse(statusCode: 500)!
    let pubNubError = PubNubError(urlError.pubnubReason!, underlying: urlError, affected: [.response(httpUrlResponse)])
    
    mockResponse(
      errorIfAny: URLError(.cannotFindHost),
      httpResponse: HTTPURLResponse(statusCode: 404)!
    )
    runEffect(
      configuration: configWithLinearPolicy(delayRange.lowerBound),
      invocation: .handshakeReconnect(
        channels: ["channel1", "channel1-pnpres", "channel2"],
        groups: ["g1", "g2", "g2-pnpres"],
        retryAttempt: 1,
        reason: pubNubError
      ),
      timeout: 2 * delayRange.upperBound,
      expectedOutput: [
        .handshakeReconnectFailure(
          error: PubNubError(
            .nameResolutionFailure,
            underlying: URLError(.cannotFindHost)
          )
        )
      ]
    )
  }
  
  func test_HandshakeReconnectGiveUp() {
    let delayRange = 2.0...3.0
    let urlError = URLError(.badServerResponse)
    
    runEffect(
      configuration: configWithLinearPolicy(delayRange.lowerBound),
      invocation: .handshakeReconnect(
        channels: ["channel1", "channel1-pnpres", "channel2"],
        groups: ["g1", "g2", "g2-pnpres"],
        retryAttempt: 3,
        reason: PubNubError(urlError.pubnubReason!, underlying: urlError)
      ),
      expectedOutput: [
        .handshakeReconnectGiveUp(
          error: PubNubError(.badServerResponse)
        )
      ]
    )
  }
  
  func test_HandshakeReconnectIsDelayed() {
    let urlError = URLError(.badServerResponse)
    let httpUrlResponse = HTTPURLResponse(statusCode: 500)!
    let pubNubError = PubNubError(urlError.pubnubReason!, underlying: urlError, affected: [.response(httpUrlResponse)])
    
    let delayRange = 2.0...3.0
    let startDate = Date()

    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: []
    ))
    runEffect(
      configuration: configWithLinearPolicy(delayRange.lowerBound),
      invocation: .handshakeReconnect(
        channels: ["channel1", "channel1-pnpres", "channel2"],
        groups: ["g1", "g2", "g2-pnpres"],
        retryAttempt: 1,
        reason: pubNubError
      ),
      timeout: 2.5 * delayRange.upperBound,
      expectedOutput: [
        .handshakeReconnectSuccess(
          cursor: SubscribeCursor(timetoken: 12345, region: 1)
        )
      ],
      additionalValidations: {
        XCTAssertTrue(
          Int(Date().timeIntervalSince(startDate)) <= Int(delayRange.upperBound)
        )
      }
    )
  }
}

// MARK: - ReceiveReconnecting

extension SubscribeEffectsTests {
  func test_ReceiveReconnectingSuccess() {
    let urlError = URLError(.badServerResponse)
    let httpUrlResponse = HTTPURLResponse(statusCode: 500)!
    let pubNubError = PubNubError(urlError.pubnubReason!, underlying: urlError, affected: [.response(httpUrlResponse)])
    let delayRange = 2.0...3.0

    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: [firstMessage, secondMessage]
    ))
    runEffect(
      configuration: configWithLinearPolicy(delayRange.lowerBound),
      invocation: .receiveReconnect(
        channels: ["channel1", "channel1-pnpres", "channel2"],
        groups: ["g1", "g2", "g2-pnpres"],
        cursor: SubscribeCursor(timetoken: 1111, region: 1),
        retryAttempt: 1,
        reason: pubNubError
      ),
      timeout: 2 * delayRange.upperBound,
      expectedOutput: [
        .receiveReconnectSuccess(
          cursor: SubscribeCursor(timetoken: 12345, region: 1),
          messages: [firstMessage, secondMessage]
        )
      ]
    )
  }
  
  func test_ReceiveReconnectingFailure() {
    let delayRange = 2.0...3.0
    let urlError = URLError(.badServerResponse)
    let httpUrlResponse = HTTPURLResponse(statusCode: 500)!
    let pubNubError = PubNubError(urlError.pubnubReason!, underlying: urlError, affected: [.response(httpUrlResponse)])

    mockResponse(
      errorIfAny: URLError(.cannotFindHost),
      httpResponse: HTTPURLResponse(statusCode: 404)!
    )
    runEffect(
      configuration: configWithLinearPolicy(delayRange.lowerBound),
      invocation: .receiveReconnect(
        channels: ["channel1", "channel1-pnpres", "channel2"],
        groups: ["g1", "g2", "g2-pnpres"],
        cursor: SubscribeCursor(timetoken: 1111, region: 1),
        retryAttempt: 1,
        reason: pubNubError
      ),
      timeout: 2 * delayRange.upperBound,
      expectedOutput: [
        .receiveReconnectFailure(
          error: PubNubError(.nameResolutionFailure)
        )
      ]
    )
  }
  
  func test_ReceiveReconnectGiveUp() {
    let urlError = URLError(.badServerResponse)
    let delayRange = 2.0...3.0

    mockResponse(
      errorIfAny: URLError(.cannotFindHost),
      httpResponse: HTTPURLResponse(statusCode: 404)!
    )
    runEffect(
      configuration: configWithLinearPolicy(delayRange.lowerBound),
      invocation: .receiveReconnect(
        channels: ["channel1", "channel1-pnpres", "channel2"],
        groups: ["g1", "g2", "g2-pnpres"],
        cursor: SubscribeCursor(timetoken: 1111, region: 1),
        retryAttempt: 3,
        reason: PubNubError(urlError.pubnubReason!, underlying: urlError)
      ),
      expectedOutput: [
        .receiveReconnectGiveUp(
          error: PubNubError(.badServerResponse)
        )
      ]
    )
  }
  
  func test_ReceiveReconnectingIsDelayed() {
    let urlError = URLError(.badServerResponse)
    let httpUrlResponse = HTTPURLResponse(statusCode: 500)!
    let pubNubError = PubNubError(urlError.pubnubReason!, underlying: urlError, affected: [.response(httpUrlResponse)])
    
    let delayRange = 2.0...3.0
    let startDate = Date()

    mockResponse(subscribeResponse: SubscribeResponse(
      cursor: SubscribeCursor(timetoken: 12345, region: 1),
      messages: [firstMessage, secondMessage]
    ))
    runEffect(
      configuration: configWithLinearPolicy(delayRange.lowerBound),
      invocation: .receiveReconnect(
        channels: ["channel1", "channel1-pnpres", "channel2"],
        groups: ["g1", "g2", "g2-pnpres"],
        cursor: SubscribeCursor(timetoken: 1111, region: 1),
        retryAttempt: 1,
        reason: pubNubError
      ),
      timeout: 2 * delayRange.upperBound,
      expectedOutput: [
        .receiveReconnectSuccess(
          cursor: SubscribeCursor(timetoken: 12345, region: 1),
          messages: [firstMessage, secondMessage]
        )
      ],
      additionalValidations: {
        XCTAssertTrue(
          Int(Date().timeIntervalSince(startDate)) <= Int(delayRange.upperBound)
        )
      }
    )
  }
}

// MARK: - Helpers

fileprivate extension SubscribeEffectsTests {
  func mockResponse(
    subscribeResponse: SubscribeResponse? = nil,
    errorIfAny: Error? = nil,
    httpResponse: HTTPURLResponse = HTTPURLResponse(statusCode: 200)!
  ) {
    mockUrlSession.responseForDataTask = { task, id in
      task.mockError = errorIfAny
      task.mockData = try? Constant.jsonEncoder.encode(subscribeResponse)
      task.mockResponse = httpResponse
      return task
    }
  }
  
  private func runEffect(
    configuration: PubNubConfiguration,
    invocation: Subscribe.Invocation,
    timeout: TimeInterval = 0.5,
    expectedOutput results: [Subscribe.Event] = [],
    additionalValidations validations: @escaping () -> Void = {}
  ) {
    let expectation = XCTestExpectation(description: "Effect Completion")
    expectation.expectedFulfillmentCount = 1
    expectation.assertForOverFulfill = true
    
    let effect = factory.effect(
      for: invocation,
      with: EventEngineDependencies(value: Subscribe.Dependencies(configuration: configuration))
    )
    effect.performTask {
      XCTAssertEqual(results, $0)
      validations()
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: timeout)
  }
}

fileprivate let firstMessage = SubscribeMessagePayload(
  shard: "",
  subscription: nil,
  channel: "test-channel",
  messageType: .message,
  payload: ["message": "hello!"],
  flags: 123,
  publisher: "publisher",
  subscribeKey: "FakeKey",
  originTimetoken: nil,
  publishTimetoken: SubscribeCursor(timetoken: 12312412412, region: 12),
  meta: nil,
  error: nil
)

fileprivate let secondMessage = SubscribeMessagePayload(
  shard: "",
  subscription: nil,
  channel: "test-channel",
  messageType: .messageAction,
  payload: ["reaction": "👍"],
  flags: 456,
  publisher: "second-publisher",
  subscribeKey: "FakeKey",
  originTimetoken: nil,
  publishTimetoken: SubscribeCursor(timetoken: 12312412555, region: 12),
  meta: nil,
  error: nil
)
