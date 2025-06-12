//
//  01-configuration.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

// snippet.import
import PubNubSDK

// snippet.end

func basicConfigExample() {
  // snippet.config-basic
  // Create a configuration object with the desired parameters
  let configuration = PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId",
    heartbeatInterval: 100
  )

  // Creates a PubNub instance with the configuration specified above
  let pubnub = PubNub(
    configuration: configuration
  )
  // snippet.end
}

func aesCbcCryptoModuleExample() {
  // snippet.crypto-module
  // Uses 256-bit AES-CBC encryption (recommended) with backward compatibility for legacy encryption
  let pubnub = PubNub(
    configuration: PubNubConfiguration(
      publishKey: "demo",
      subscribeKey: "demo",
      userId: "myUniqueUserId",
      cryptoModule: CryptoModule.aesCbcCryptoModule(with: "pubnubenigma")
    )
  )
  // snippet.end
}

func legacyCryptoModuleExample() {
  // snippet.legacy-crypto-module
  // Uses a legacy encryption mechanism (128-bit cipher key entropy) that is no longer recommended
  let pubnub = PubNub(
    configuration: PubNubConfiguration(
      publishKey: "demo",
      subscribeKey: "demo",
      userId: "myUniqueUserId",
      cryptoModule: CryptoModule.legacyCryptoModule(with: "pubnubenigma")
    )
  )
  // snippet.end
}

func automaticRetryExample() {
  // snippet.automatic-retry
  /// Creates automatic retry behavior for failed requests with a linear backoff policy
  /// The delay parameter (4 seconds) specifies the base linear delay between retry attempts.

  /// As an example, we'll disable automatic retry for publish, signal, and fire requests.
  /// Other possible values to exclude are:
  /// - .messageSend
  /// - .subscribe
  /// - .presence
  /// - .files
  /// - .messageStorage
  /// - .channelGroups
  /// - .devicePushNotifications
  /// - .appContext
  /// - .messageActions
  let automaticRetry = AutomaticRetry(
    policy: .linear(delay: 4),
    excluded: [.messageSend]
  )

  // Creates a PubNub instance with retry mechanism enabled
  let pubnub = PubNub(
    configuration: PubNubConfiguration(
      publishKey: "demo",
      subscribeKey: "demo",
      userId: "myUniqueUserId",
      automaticRetry: automaticRetry
    )
  )
  // snippet.end
}

func publishKeyAsNilExample() {
  // snippet.config-publish-key-nil
  let config = PubNubConfiguration(
    publishKey: nil,
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )

  let pubnub = PubNub(
    configuration: config
  )
  // snippet.end
}

func filterExpressionExample() {
  // snippet.filter-expression
  // snippet.hide
  let configuration = PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
  let pubnub = PubNub(
    configuration: configuration
  )
  // snippet.show
  pubnub.subscribeFilterExpression = "(senderID=='my_new_userId')"
  // snippet.end
}

func readOnlyConfigExample() {
  let configuration = PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
  let pubnub = PubNub(
    configuration: configuration
  )

  // snippet.config-read-only
  // Accessing the current configuration
  var config = pubnub.configuration
  // Modyfing user ID parameter
  config.userId = "my_new_userId"
  // Creating a new PubNub instance with the modified configuration
  let newPubNub = PubNub(configuration: config)
  // snippet.end
}
