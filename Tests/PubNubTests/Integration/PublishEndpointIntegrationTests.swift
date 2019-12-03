//
//  PublishEndpointIntegrationTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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
import XCTest

class PublishEndpointIntegrationTests: XCTestCase {
  let testsBundle = Bundle(for: PublishEndpointIntegrationTests.self)

  func testPublishEndpoint() {
    let publishExpect = expectation(description: "Publish Response")

    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    // Publish a simple message to the demo_tutorial channel
    client.publish(channel: "SwiftITest", message: "TestPublish") { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      publishExpect.fulfill()
    }

    wait(for: [publishExpect], timeout: 10.0)
  }

  func testCompressedPublishEndpoint() {
    let compressedPublishExpect = expectation(description: "Compressed Publish Response")

    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    // Publish a simple message to the demo_tutorial channel
    client.publish(channel: "SwiftITest",
                   message: "TestCompressedPublish",
                   shouldCompress: true) { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      compressedPublishExpect.fulfill()
    }

    wait(for: [compressedPublishExpect], timeout: 10.0)
  }

  func testFireEndpoint() {
    let fireExpect = expectation(description: "Fire Response")

    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    // Publish a simple message to the demo_tutorial channel
    client.fire(channel: "SwiftITest", message: "TestFire") { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      fireExpect.fulfill()
    }

    wait(for: [fireExpect], timeout: 10.0)
  }

  func testSignalEndpoint() {
    let signalExpect = expectation(description: "Signal Response")

    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    // Publish a simple message to the demo_tutorial channel
    client.signal(channel: "SwiftITest", message: "TestSignal") { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      signalExpect.fulfill()
    }

    wait(for: [signalExpect], timeout: 10.0)
  }

  func testPushblishEscapedString() {
    let message = "{\"text\": \"bob\", \"duckName\": \"swiftduck\"}"

    let publishExpect = expectation(description: "Publish Response")

    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    // Publish a simple message to the demo_tutorial channel
    client.publish(channel: "SwiftITest", message: message) { result in
      switch result {
      case .success:
        XCTFail("Publish should fail")
      case let .failure(error):
        XCTAssertEqual(error.pubNubError?.reason,
                       PubNubError.Reason.requestContainedInvalidJSON)
      }
      publishExpect.fulfill()
    }

    wait(for: [publishExpect], timeout: 10.0)
  }

  func testPublishPushPayload() {
    let publishExpect = expectation(description: "Publish Response")

    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let pushMessage = PubNubPushMessage(
      apns: PubNubAPNSPayload(
        aps: APSPayload(alert: .object(.init(title: "Apple Message")), badge: 1, sound: .string("default")),
        pubnub: [.init(targets: [.init(topic: "com.pubnub.swift", environment: .production)], collapseID: "SwiftSDK")],
        payload: "Push Message from PubNub Swift SDK"
      ),
      fcm: PubNubFCMPayload(
        payload: "Push Message from PubNub Swift SDK",
        target: .topic("com.pubnub.swift"),
        notification: FCMNotificationPayload(title: "Android Message"),
        android: FCMAndroidPayload(collapseKey: "SwiftSDK", notification: FCMAndroidNotification(sound: "default"))
      ),
      additional: "Push Message from PubNub Swift SDK"
    )

    // Publish a simple message to the demo_tutorial channel
    client.publish(channel: "SwiftITest", message: pushMessage) { result in
      switch result {
      case .success:
        break
      case let .failure(error):
        XCTFail("Failed due to error: \(error)")
      }
      publishExpect.fulfill()
    }

    wait(for: [publishExpect], timeout: 10.0)
  }
}
