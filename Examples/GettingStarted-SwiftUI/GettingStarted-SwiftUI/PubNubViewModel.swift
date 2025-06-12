//
//  PubNubViewModel.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import SwiftUI
import PubNubSDK

class PubNubViewModel: ObservableObject {
  // Holds the streamed messages
  @Published var messages: [String] = []
  // Reference to the SDK instance
  private let pubnub: PubNub

  // A dedicated subscription object for the example chat channel
  lazy var subscription: Subscription? = pubnub
    .channel("hello_world")
    .subscription(options: ReceivePresenceEvents())

  init() {
    pubnub = PubNub(configuration: PubNubConfiguration(
      publishKey: "demo",
      subscribeKey: "demo",
      userId: "device-\(UUID().uuidString.prefix(8))"
    ))

    setupConnectionHandling()
    setupMessageHandling()
  }

  private func setupConnectionHandling() {
    pubnub.onConnectionStateChange = { [weak self] newStatus in
      print("Connection status changed: \(newStatus)")

      // When connected, publish a welcome message
      if case .connected = newStatus {
        self?.sendWelcomeMessage()
      } else {
        // Handle other connection states according to your needs
      }
    }
  }

  private func setupMessageHandling() {
    subscription?.onMessage = { [weak self] message in
      print("Message received: \(message.payload.stringOptional ?? "N/A")")
      self?.messages.append(message.payload.stringOptional ?? "N/A")
    }
  }

  private func sendWelcomeMessage() {
    pubnub.publish(
      channel: "hello_world",
      message: "Hello from iOS!"
    ) { result in
      switch result {
      case .success(let response):
        print("Message published successfully at \(response.timetokenDate)")
      case .failure(let error):
         print("Failed to publish message: \(error.localizedDescription)")
      }
    }
  }
}
