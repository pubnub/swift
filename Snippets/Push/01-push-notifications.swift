//
//  01-push-notifications.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

// snippet.import
import PubNubSDK
import Foundation

// snippet.end

// snippet.pubnub
// Initializes a PubNub object with the configuration
let pubnub = PubNub(
  configuration: PubNubConfiguration(
    publishKey: "demo",
    subscribeKey: "demo",
    userId: "myUniqueUserId"
  )
)

// snippet.end

// snippet.add-apns-devices-on-channels
// Adding a device to a channel for APNs
pubnub.addAPNSDevicesOnChannels(
  ["channelSwift"],
  device: Data([0x01, 0x02, 0x03, 0x04]), // Replace with actual device token
  on: "com.app.bundle",
  environment: .production
) { result in
  switch result {
  case let .success(channels):
    print("The list of channels added for push: \(channels)")
  case let .failure(error):
    print("Failed Push List Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.list-apns-push-channel-registrations
pubnub.listAPNSPushChannelRegistrations(
  for: Data([0x01, 0x02, 0x03, 0x04]), // Replace with actual device token
  on: "com.app.bundle",
  environment: .production
) { result in
  switch result {
  case let .success(channels):
    print("The list of channels enabled for push: \(channels)")
  case let .failure(error):
    print("Failed Push List Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-apns-devices-on-channels
pubnub.removeAPNSDevicesOnChannels(
  ["channelSwift"],
  device: Data([0x01, 0x02, 0x03, 0x04]), // Replace with actual device token
  on: "com.app.bundle",
  environment: .production
) { result in
  switch result {
  case let .success(channels):
    print("The list of channels disabled for push: \(channels)")
  case let .failure(error):
    print("Failed Push List Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-all-apns-push-device
pubnub.removeAllAPNSPushDevice(
  for: Data([0x01, 0x02, 0x03, 0x04]), // Replace with actual device token
  on: "com.app.bundle",
  environment: .production
) { result in
  switch result {
  case .success:
    print("All channels have been removed for the device token.")
  case let .failure(error):
    print("Failed Push List Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.add-push-channels-registrations
pubnub.addPushChannelRegistrations(
  ["channelSwift"],
  for: Data([0x01, 0x02, 0x03, 0x04]) // Replace with actual device token
) { result in
  switch result {
  case let .success(channels):
    print("The list of channels added for push: \(channels)")
  case let .failure(error):
    print("Failed Push Modification Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.list-push-channels-registrations
pubnub.listPushChannelRegistrations(
  for: Data([0x01, 0x02, 0x03, 0x04]) // Replace with actual device token
) { result in
  switch result {
  case let .success(channels):
    print("The list of channels enabled for push: \(channels)")
  case let .failure(error):
    print("Failed Push List Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-push-channel-registrations
pubnub.removePushChannelRegistrations(
  ["channelSwift"],
  for: Data([0x01, 0x02, 0x03, 0x04]) // Replace with actual device token
) { result in
  switch result {
  case let .success(channels):
    print("The list of channels disabled for push: \(channels)")
  case let .failure(error):
    print("Failed Push Modification Response: \(error.localizedDescription)")
  }
}
// snippet.end

// snippet.remove-all-push-channel-registrations
pubnub.removeAllPushChannelRegistrations(
  for: Data([0x01, 0x02, 0x03, 0x04]) // Replace with actual device token
) { result in
  switch result {
  case .success:
    print("All channels have been removed for the device token.")
  case let .failure(error):
    print("Failed Push Deletion Response: \(error.localizedDescription)")
  }
}
// snippet.end
