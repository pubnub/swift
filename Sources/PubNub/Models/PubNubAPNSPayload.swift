//
//  PubNubAPNSPayload.swift
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

import Foundation

/// The PubNub push configuration payload
public struct PubNubPushConfig: Codable, Hashable {
  /// The authorization method used inside the PubNub Portal from your Apple Developer Account
  public let authMethod: String = "token"
  /// The targets of a published PubNub notification
  public let targets: [PubNubPushTarget]
  /// Version of the PubNub push configuration
  public let version: String = "v2"
  /// APS collapse id
  ///
  /// This will populate the APN's `apns-collapse-id` header
  public let collapseID: String?
  /// Expiration time of the remote notification
  ///
  /// This will populate the APN's `apns-expiration` header
  public let expiration: Date?

  enum CodingKeys: String, CodingKey {
    case authMethod = "auth_method"
    case collapseID = "collapse_id"
    case expiration
    case targets
    case version
  }

  public init(
    targets: [PubNubPushTarget],
    collapseID: String? = nil,
    expiration: Date? = nil
  ) {
    self.targets = targets
    self.collapseID = collapseID
    self.expiration = expiration
  }
}

/// The target of a published PubNub notification
public struct PubNubPushTarget: Codable, Hashable {
  /// The topic of the device
  ///
  /// This will populate the APN's `apns-topic` header
  public let topic: String
  /// The APS environment
  public let environment: PubNub.PushEnvironment
  /// Devices that should not receive this notification
  ///
  /// This is likely the senders device token
  public let excludedDevices: [String]?

  enum CodingKeys: String, CodingKey {
    case environment
    case excludedDevices = "excluded_devices"
    case topic
  }

  public init(
    topic: String,
    environment: PubNub.PushEnvironment = .development,
    excludedDevices: [String]? = nil
  ) {
    self.topic = topic
    self.environment = environment
    self.excludedDevices = excludedDevices
  }
}

// MARK: - APS Payload

public struct PubNubAPNSPayload: Codable {
  /// The `APS` payload to be included in all notifications through APNS
  public let aps: APSPayload
  /// The PubNub push configuration payload
  public let pubnub: [PubNubPushConfig]
  /// The message being sent inside the remote notification
  ///
  /// In order to guarantee valid JSON any scalar values will be assigned to the `data` key.  Non-scalar values will retain their coding keys.
  public let payload: JSONCodable?

  enum CodingKeys: String, CodingKey {
    case aps
    case pubnub = "pn_push"
    case payload = "data"
  }

  public init(aps: APSPayload, pubnub: [PubNubPushConfig], payload: JSONCodable?) {
    self.aps = aps
    self.pubnub = pubnub
    self.payload = payload
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    aps = try container.decode(APSPayload.self, forKey: .aps)
    pubnub = try container.decode([PubNubPushConfig].self, forKey: .pubnub)
    payload = try container.decodeIfPresent(AnyJSON.self, forKey: .payload)
  }

  public func encode(to encoder: Encoder) throws {
    if let payload = payload, !payload.codableValue.isScalar {
      try payload.codableValue.encode(to: encoder)
    }

    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(aps, forKey: .aps)
    try container.encode(pubnub, forKey: .pubnub)

    if let payload = payload, payload.codableValue.isScalar {
      try container.encode(payload.codableValue, forKey: .payload)
    }
  }
}

/// The `APS` payload to be included in all notifications through APNS
///
/// More information can be found at
/// [Generating a Remote Notification](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification#2943365)
public struct APSPayload: Codable, Hashable {
  /// The information for displaying an alert.
  ///
  /// An object is recommended. If you specify a string, the alert displays your string as the body text.
  public let alert: APSAlert?
  /// The number to display in a badge on your app’s icon.
  ///
  /// Specify 0 to remove the current badge, if any.
  public let badge: Int?
  /// The sound that will play
  public let sound: APSSound?
  /// An app-specific identifier for grouping related notifications.
  ///
  /// This value corresponds to the `threadIdentifier` property in the `UNNotificationContent` object.
  public let threadID: String?
  /// The notification’s type.
  ///
  /// - Requires: This string must correspond to the identifier of one of the
  /// `UNNotificationCategory` objects you register at launch time.
  /// See [Declaring Your Actionable Notification Types](https://developer.apple.com/documentation/usernotifications/declaring_your_actionable_notification_types).
  public let category: String?
  /// The background notification flag.
  ///
  /// To perform a silent background update,
  /// specify the value 1 and don't include the alert, badge, or sound keys in your payload.
  ///
  /// See [Pushing Background Updates to Your App](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app).
  public let contentAvailable: Int?
  /// The notification service app extension flag.
  ///
  /// If the value is 1, the system passes the notification to your notification service app extension before delivery.
  /// Use your extension to modify the notification’s content.
  ///
  /// See [Modifying Content in Newly Delivered Notifications](https://developer.apple.com/documentation/usernotifications/modifying_content_in_newly_delivered_notifications).
  public let mutableContent: Int?
  /// The identifier of the window brought forward.
  ///
  ///  The value of this key will be populated on the `UNNotificationContent` object created from the push payload.
  ///
  ///  Access the value using the `UNNotificationContent` object's `targetContentIdentifier` property.
  public let targetContentID: String?

  enum CodingKeys: String, CodingKey {
    case alert
    case badge
    case sound
    case threadID = "thread-id"
    case category
    case contentAvailable = "content-available"
    case mutableContent = "mutable-content"
    case targetContentID = "target-content-id"
  }

  public init(
    alert: APSAlert? = nil,
    badge: Int? = nil,
    sound: APSSound? = .string("default"),
    threadID: String? = nil,
    category: String? = nil,
    contentAvailable: Int? = nil,
    mutableContent: Int? = nil,
    targetContentID: String? = nil
  ) {
    self.alert = alert
    self.badge = badge
    self.sound = sound
    self.threadID = threadID
    self.category = category
    self.contentAvailable = contentAvailable
    self.mutableContent = mutableContent
    self.targetContentID = targetContentID
  }
}

/// The information for displaying an alert.
///
/// Using the object is recommended.
///
/// If you specify a string, the alert displays your string as the body text.
public enum APSAlert: Codable, Hashable {
  /// The alert displays your string as the body text.
  case body(String)
  /// Use these strings to specify the title and message to include in the alert banner.
  case object(APSAlertObject)

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let bodyString = try? container.decode(String.self) {
      self = .body(bodyString)
    } else {
      let alertObject = try container.decode(APSAlertObject.self)
      self = .object(alertObject)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case let .body(value):
      try container.encode(value)
    case let .object(value):
      try container.encode(value)
    }
  }
}

/// Use these strings to specify the title and message to include in the alert banner.
public struct APSAlertObject: Codable, Hashable {
  /// The title of the notification.
  ///
  /// Specify a string that is quickly understood by the user.
  /// - Note:  Apple Watch displays this string in the short look notification interface.
  public let title: String?
  /// Additional information that explains the purpose of the notification.
  public let subtitle: String?
  /// The content of the alert message.
  public let body: String?
  /// The name of the launch image file to display.
  ///
  ///  If the user chooses to launch your app, the contents of the specified image or storyboard file
  ///  are displayed instead of your app's normal launch image.
  public let launchImage: String?
  /// The key for a localized title string.
  ///
  /// Specify this key instead of the title key to retrieve the title from your app’s Localizable.strings files.
  /// - Requires: The value must contain the name of a key in your strings file.
  public let titleLocKey: String?
  /// An array of strings containing replacement values for variables in your title string.
  ///
  /// Each %@ character in the string specified by the title-loc-key is replaced by a value from this array.
  ///
  /// The first item in the array replaces the first instance of the %@ character in the string,
  /// the second item replaces the second instance, and so on.
  public let titleLocArgs: [String]?
  /// The key for a localized subtitle string.
  ///
  /// Use this key, instead of the subtitle key, to retrieve the subtitle from your app's Localizable.strings file.
  /// - Requires: The value must contain the name of a key in your strings file.
  public let subtitleLocKey: [String]?
  /// An array of strings containing replacement values for variables in your title string.
  ///
  ///  Each %@ character in the string specified by subtitle-loc-key is replaced by a value from this array.
  ///
  ///  The first item in the array replaces the first instance of the %@ character in the string,
  ///  the second item replaces the second instance, and so on.
  public let subtitleLocArgs: [String]?
  /// The key for a localized message string.
  ///
  /// Use this key, instead of the body key, to retrieve the message text from your app's Localizable.strings file.
  /// - Requires: The value must contain the name of a key in your strings file.
  public let locKey: String?
  /// An array of strings containing replacement values for variables in your message text.
  ///
  /// Each %@ character in the string specified by loc-key is replaced by a value from this array.
  ///
  /// The first item in the array replaces the first instance of the %@ character in the string,
  /// the second item replaces the second instance, and so on.
  public let locArgs: [String]?

  enum CodingKeys: String, CodingKey {
    case title
    case subtitle
    case body
    case launchImage = "launch-image"
    case titleLocKey = "title-loc-key"
    case titleLocArgs = "title-loc-args"
    case subtitleLocKey = "subtitle-loc-key"
    case subtitleLocArgs = "subtitle-loc-args"
    case locKey = "loc-key"
    case locArgs = "loc-args"
  }

  public init(
    title: String? = nil,
    subtitle: String? = nil,
    body: String? = nil,
    launchImage: String? = nil,
    titleLocKey: String? = nil,
    titleLocArgs: [String]? = nil,
    subtitleLocKey: [String]? = nil,
    subtitleLocArgs: [String]? = nil,
    locKey: String? = nil,
    locArgs: [String]? = nil
  ) {
    self.title = title
    self.subtitle = subtitle
    self.body = body
    self.launchImage = launchImage
    self.titleLocKey = titleLocKey
    self.titleLocArgs = titleLocArgs
    self.subtitleLocKey = subtitleLocKey
    self.subtitleLocArgs = subtitleLocArgs
    self.locKey = locKey
    self.locArgs = locArgs
  }
}

/// The sound that will play upon delivery of your APS message
public enum APSSound: Codable, Hashable {
  /// The name of a sound file in your app’s main bundle or in
  /// the Library/Sounds folder of your app’s container directory.
  ///
  /// Specify the string "default" to play the system sound.
  ///
  /// For critical alerts, use the sound dictionary instead.
  /// For information about how to prepare sounds, see `UNNotificationSound`.
  case string(String)
  /// An object that contains sound information for critical alerts.
  case critical(APSCriticalSound)

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let soundString = try? container.decode(String.self) {
      self = .string(soundString)
    } else {
      let soundObject = try container.decode(APSCriticalSound.self)
      self = .critical(soundObject)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case let .string(value):
      try container.encode(value)
    case let .critical(value):
      try container.encode(value)
    }
  }
}

/// An object that contains sound information for critical APS alerts.
public struct APSCriticalSound: Codable, Hashable {
  /// The critical alert flag.
  ///
  /// Set to 1 to enable the critical alert.
  public let critical: Int?
  /// The name of a sound file in your app’s main bundle or
  ///  in the Library/Sounds folder of your app’s container directory.
  ///
  /// Specify the string "default" to play the system sound.
  ///
  /// For information about how to prepare sounds, see `UNNotificationSound`.
  public let name: String
  /// The volume for the critical alert’s sound.
  ///
  /// Set this to a value between 0.0 (silent) and 1.0 (full volume).
  public let volume: Int?

  public init(critical: Int? = nil, name: String = "default", volume: Int? = nil) {
    self.critical = critical
    self.name = name
    self.volume = volume
  }
}
