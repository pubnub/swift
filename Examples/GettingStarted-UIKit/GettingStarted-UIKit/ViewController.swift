//
//  ViewController.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit
import PubNubSDK

// A view controller that demonstrates basic PubNub chat functionality
class ViewController: UIViewController {
  // PubNub instance configured with publish/subscribe keys and unique user ID
  private let pubnub: PubNub = PubNub(configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "device-\(UUID().uuidString.prefix(8))"
  ))
  
  // A dedicated subscription object for the example chat channel
  private lazy var subscription: Subscription? = pubnub
    .channel("hello_world")
    .subscription(queue: .main, options: ReceivePresenceEvents())
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupConnectionHandling()
    setupMessageHandling()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // Subscribe to the channel
    subscription?.subscribe()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // Unsubscribe when view disappears
    subscription?.unsubscribe()
  }
  
  private func setupConnectionHandling() {
    pubnub.onConnectionStateChange = { [weak self] newStatus in
      print("Connection status changed: \(newStatus)")
      
      // Connection status changes are posted on the main thread.
      // No manual synchronization needed
      self?.updateConnectionStatus(newStatus)
      
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
      print("Message received: \(message.payload.stringOptional ?? "")")
      self?.displayMessage(message)
    }
  }
  
  private func displayMessage(_ message: PubNubMessage) {
    // Update your UI to display the message
    // For example, add it to a UITableView or UILabel
  }
  
  private func updateConnectionStatus(_ status: ConnectionStatus) {
    // Update UI to reflect connection status
    // For example, change a status indicator color
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
