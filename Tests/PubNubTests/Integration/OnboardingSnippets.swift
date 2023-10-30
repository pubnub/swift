//
//  OnboardingSnippets.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
        _ = result.map { print("Successfully sent at \($0)!") }
        publishExpect.fulfill()
      }
    }

    // Add Listener
    let listener = SubscriptionListener()
    listener.didReceiveMessage = { event in
      print("Received \(event.payload) from \(event.publisher ?? "_Unknown_")")
      messageExpect.fulfill()
    }
    listener.didReceivePresence = { event in
      print("Channel `\(event.channel)` has occupancy of \(event.occupancy)")
      for action in event.actions {
        print("Event `\(action)` at \(event.timetoken)")
      }
    }
    listener.didReceiveStatus = { event in
      switch event {
      case let .success(status):
        print("Status changed to \(status)")
        if status == .connected { performPublish() }
      case let .failure(error):
        print("Error received on endpoint \(error.localizedDescription)")
        XCTFail("Publish returned an error")
      }
    }
    client.add(listener)

    // Subscribe to the demo_tutorial channel
    client.subscribe(to: ["pubnub_onboarding_channel"], withPresence: true)

    // Cleanup
    defer { listener.cancel() }
    wait(for: [messageExpect, publishExpect], timeout: 10.0)
  }

  // Publish 10 messages, History of 10 messages, Delete 10 messages
  func testFetchChannelHistory() {
    let historyExpect = expectation(description: "Message Response")
    let publishExpect = expectation(description: "Publish Response")

    // Instantiate PubNub
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)

    // Fetch last 10 messages
    let performMessageFetch = {
      client.fetchMessageHistory(for: ["pubnub_onboarding_channel"]) { result in
        switch result {
        case let .success((actions, nextPage)):
          XCTAssertNotNil(actions["pubnub_onboarding_channel"])
          if let channelMessages = actions["pubnub_onboarding_channel"] {
            print("Start timetoken: \(nextPage?.start ?? 0)")
            print("End timetoken: \(nextPage?.end ?? 0)")
            for message in channelMessages {
              print("Message content: \(message.payload)")
            }
          }
        case let .failure(error):
          print("Message History error received: \(error.localizedDescription)")
          XCTFail("Message History returned an error")
        }
        historyExpect.fulfill()
      }
    }

    let listener = SubscriptionListener()
    listener.didReceiveSubscription = { event in
      switch event {
      case let .messageReceived(message):
        if message.publisher == configuration.uuid {
          performMessageFetch()
        }
      case let .connectionStatusChanged(connection):
        if connection == .connected {
          client.publish(channel: "pubnub_onboarding_channel",
                         message: ["sender": configuration.uuid,
                                   "content": "Hello From SDK_NAME SDK"]) { _ in
            publishExpect.fulfill()
          }
        }
      default:
        break
      }
    }

    client.add(listener)
    client.subscribe(to: ["pubnub_onboarding_channel"])

    defer { listener.cancel() }

    wait(for: [publishExpect, historyExpect], timeout: 10.0)
  }
}
