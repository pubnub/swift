//
//  02-automatic-retry.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import PubNubSDK

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

// Creates a PubNub instance with retry mechanism enabled:
let pubnub = PubNub(
  publishKey: "demo",
  subscribeKey: "demo",
  userId: "myUniqueUserId",
  automaticRetry: automaticRetry
)
// snippet.end
