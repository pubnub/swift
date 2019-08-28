//
//  OnboardingSnippets.swift
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

class OnboardingSnippets: XCTestCase {
  let testsBundle = Bundle(for: OnboardingSnippets.self)

  // Subscribe with presence
  func testPubSub() {
    let messageExpect = expectation(description: "Message Response")
    let publishExpect = expectation(description: "Publish Response")

    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    let performPublish = {
      // Publish a simple message to the demo_tutorial channel
      client.publish(channel: "pubnub_onboarding_channel",
                     message: ["sender": configuration.uuid,
                               "content": "Hello From SDK_NAME SDK"]) { result in
        _ = result.map { print("Successfully sent at \($0.timetoken)!") }
        publishExpect.fulfill()
      }
    }

    // Add Listener
    let listener = SubscriptionListener()
    listener.didReceiveMessage = { event in
      print("Received \(event.message) from \(event.publisher ?? "_Unknown_")")
      messageExpect.fulfill()
    }
    listener.didReceivePresence = { event in
      print("Channel `\(event.channel)` has occupancy of \(event.occupancy)")
      print("User(s) Joined: \(event.join)")
      print("User(s) Left: \(event.leave)")
      print("User(s) Timedout: \(event.timeout)")
    }
    listener.didReceiveStatus = { event in
      switch event {
      case let .success(status):
        print("Status changed to \(status)")
        if status == .connected { performPublish() }
      case let .failure(error):
        print("Error received on endpoint \(error.endpoint): \(error.localizedDescription)")
        XCTFail("Publish returned an error")
      }
    }
    let token = client.add(listener)

    // Subscribe to the demo_tutorial channel
    client.subscribe(to: ["pubnub_onboarding_channel"], withPresence: true)

    // Cleanup
    defer { token.cancel() }
    wait(for: [messageExpect, publishExpect], timeout: 10.0)
  }

  // Publish 10 messages, History of 10 messages, Delete 10 messages
  func testFetchChannelHistory() {
    let historyExpect = expectation(description: "Message Response")

    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    // Fetch last 10 messages
    client.fetchMessageHistory(for: ["pubnub_onboarding_channel"], max: 10) { result in
      switch result {
      case let .success(response):
        XCTAssertNotNil(response["pubnub_onboarding_channel"])
        if let channelMessages = response["pubnub_onboarding_channel"] {
          print("Start timetoken: \(channelMessages.startTimetoken)")
          print("Start timetoken: \(channelMessages.endTimetoken)")
          for message in channelMessages.messages {
            print("Message content: \(message.message)")
          }
        }
      case let .failure(error):
        print("Message History error received: \(error.localizedDescription)")
        XCTFail("Message History returned an error")
      }
      historyExpect.fulfill()
    }

    wait(for: [historyExpect], timeout: 10.0)
  }
}
