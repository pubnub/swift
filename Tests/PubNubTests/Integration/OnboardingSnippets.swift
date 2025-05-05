//
//  OnboardingSnippets.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK
import XCTest

class OnboardingSnippets: XCTestCase {
  let testsBundle = Bundle(for: OnboardingSnippets.self)
  
  func testPubSub() {
    let messageExpect = expectation(description: "Message Response")
    let publishExpect = expectation(description: "Publish Response")
    
    let configuration = PubNubConfiguration(from: testsBundle)
    let client = PubNub(configuration: configuration)
    let channelName = randomString()
    
    let performPublish = {
      client.publish(
        channel: channelName,
        message: ["sender": configuration.userId, "content": "Hello From Swift SDK"]
      ) { result in
        publishExpect.fulfill()
      }
    }
    
    let listener = SubscriptionListener()
    
    listener.didReceiveMessage = { event in
      messageExpect.fulfill()
    }
    
    listener.didReceiveStatus = { event in
      switch event {
      case let .success(status):
        if status == .connected {
          performPublish()
        }
      case let .failure(error):
        XCTFail("Publish returned an error \(error.localizedDescription)")
      }
    }
    
    client.add(listener)
    client.subscribe(to: [channelName], withPresence: true)
    
    defer {
      listener.cancel()
      client.deleteMessageHistory(from: channelName, completion: nil)
    }
    
    wait(for: [messageExpect, publishExpect], timeout: 10.0)
  }
}
