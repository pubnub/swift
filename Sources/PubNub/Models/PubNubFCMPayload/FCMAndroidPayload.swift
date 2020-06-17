//
//  FCMAndroidPayload.swift
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

/// Android specific options for messages sent through
/// [FCM connection server](https://firebase.google.com/docs/cloud-messaging/server).
public struct FCMAndroidPayload: Codable, Hashable {
  /// An identifier of a group of messages that can be collapsed,
  /// so that only the last message gets sent when delivery can be resumed.
  ///
  ///  A maximum of 4 different collapse keys is allowed at any given time.∫
  public let collapseKey: String?
  /// Message priority. Can take "normal" and "high" values.
  ///
  /// For more information, see [Setting the priority of a message](https://goo.gl/GjONJv).
  public let priority: FCMAndroidMessagePriority?
  /// How long (in seconds) the message should be kept in FCM storage if the device is offline.
  ///
  /// The maximum time to live supported is 4 weeks, and the default value is 4 weeks if not set.
  ///
  /// Set it to 0 if want to send the message immediately.
  public let ttl: String?
  /// Package name of the application where the registration token must match in order to receive the message.
  public let restrictedPackageName: String?
  /// Notification to send to android devices.
  public let notification: FCMAndroidNotification?
  /// Options for features provided by the FCM SDK for Android.
  public let options: FCMOptionsPayload?

  enum CodingKeys: String, CodingKey {
    case collapseKey = "collapse_key"
    case priority
    case ttl
    case restrictedPackageName = "restricted_package_name"
    case notification
    case options = "fcm_options"
  }

  public init(
    collapseKey: String? = nil,
    priority: FCMAndroidMessagePriority? = nil,
    ttl: Double? = nil,
    restrictedPackageName: String? = nil,
    notification: FCMAndroidNotification? = nil,
    options: FCMOptionsPayload? = nil
  ) {
    self.collapseKey = collapseKey
    self.priority = priority
    if let duration = ttl {
      self.ttl = "\(duration)s"
    } else {
      self.ttl = nil
    }
    self.restrictedPackageName = restrictedPackageName
    self.notification = notification
    self.options = options
  }
}

/// Priority of a Firebase Cloud Messaging (FCM) message to send to Android devices.
///
/// Note this priority is an FCM concept that controls when the message is delivered.
/// See
/// [FCM guides](https://firebase.google.com/docs/cloud-messaging/concept-options?authuser=0#setting-the-priority-of-a-message).
///
/// Additionally, you can determine notification display priority on targeted Android devices using
/// [AndroidNotification.NotificationPriority](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages#androidnotification)
public enum FCMAndroidMessagePriority: String, Codable, Hashable {
  /// Default priority for data messages.
  ///
  /// Normal priority messages won't open network connections on a sleeping device,
  /// and their delivery may be delayed to conserve the battery.
  /// For less time-sensitive messages, such as notifications of new email or other data to sync,
  /// choose normal delivery priority.
  case normal = "NORMAL"
  /// Default priority for notification messages.
  ///
  /// FCM attempts to deliver high priority messages immediately,
  /// allowing the FCM service to wake a sleeping device when possible and open a network connection to your app server.
  ///
  /// Apps with instant messaging, chat, or voice call alerts, for example,
  /// generally need to open a network connection and make sure FCM delivers the message to the device without delay.
  ///
  /// Set high priority if the message is time-critical and requires the user's immediate interaction,
  /// but beware that setting your messages to high priority contributes
  /// more to battery drain compared with normal priority messages.
  case high = "HIGH"
}

/// Firebase Cloud Messaging (FCM) notification to send to android devices.
public struct FCMAndroidNotification: Codable, Hashable {
  /// The notification's title.
  ///
  /// If present, it will override `FCMNotificationPayload.title`.
  public let title: String?
  /// The notification's body text.
  ///
  /// If present, it will override `FCMNotificationPayload.body`.
  public let body: String?
  /// The notification's icon.
  ///
  /// Sets the notification icon to myicon for drawable resource myicon.
  /// If you don't send this key in the request, FCM displays the launcher icon specified in your app manifest.
  public let icon: String?
  /// The notification's icon color
  ///
  /// Expressed in #rrggbb format.
  public let color: String?
  /// The sound to play when the device receives the notification.
  ///
  /// Supports "default" or the filename of a sound resource bundled in the app.
  ///
  /// - Requires: Sound files must reside in /res/raw/.
  public let sound: String?
  /// Identifier used to replace existing notifications in the notification drawer.
  ///
  /// If not specified, each request creates a new notification.
  ///
  /// If specified and a notification with the same tag is already being shown,
  /// the new notification replaces the existing one in the notification drawer.
  public let tag: String?
  /// The action associated with a user click on the notification.
  ///
  /// If specified, an activity with a matching intent filter is launched when a user clicks on the notification.
  public let clickAction: String?
  /// The key to the body string in the app's string resources
  /// to use to localize the body text to the user's current localization.
  ///
  /// See [String Resources](https://goo.gl/NdFZGI) for more information.
  public let bodyLocKey: String?
  /// Variable string values to be used in place of the format specifiers in `bodyLocKey`
  /// to use to localize the body text to the user's current localization.
  ///
  /// See [Formatting and Styling](https://goo.gl/MalYE3) for more information.
  public let bodyLocArgs: [String]?
  /// The key to the title string in the app's string resources to use to localize
  ///  the title text to the user's current localization.
  ///
  /// See [String Resources](https://goo.gl/NdFZGI) for more information.
  public let titleLocKey: String?
  /// Variable string values to be used in place of the format specifiers in `titleLocKey`
  ///  to use to localize the title text to the user's current localization.
  ///
  /// See [Formatting and Styling](https://goo.gl/MalYE3) for more information.
  public let titleLocArgs: [String]?
  /// The
  /// [notification's channel id](https://developer.android.com/guide/topics/ui/notifiers/notifications#ManageChannels)
  ///
  /// If you don't send this channel ID in the request, or if the channel ID
  /// provided has not yet been created by the app,
  /// FCM uses the channel ID specified in the app manifest.
  /// - Requires: The app must create a channel with this channel ID
  ///  before any notification with this channel ID is received.
  public let channelID: String?
  /// Sets the "ticker" text, which is sent to accessibility services.
  ///
  /// Prior to API level 21 (Lollipop), sets the text that is displayed
  /// in the status bar when the notification first arrives.
  public let ticker: String?
  /// When set to false or unset, the notification is automatically dismissed when the user clicks it in the panel.
  ///
  /// When set to true, the notification persists even when the user clicks it.
  public let sticky: Bool?
  /// Set the time that the event in the notification occurred.
  ///
  /// Notifications in the panel are sorted by this time.
  public let eventTime: Date?
  /// Set whether or not this notification is relevant only to the current device.
  ///
  /// Some notifications can be bridged to other devices for remote display, such as a Wear OS watch.
  ///
  /// This hint can be set to recommend this notification not be bridged. See
  /// [Wear OS guides](https://developer.android.com/training/wearables/notifications/bridger#existing-method-of-preventing-bridging)
  public let localOnly: Bool?
  /// Set the relative priority for this notification.
  ///
  /// Priority is an indication of how much of the user's attention should be consumed by this notification.
  ///
  /// Low-priority notifications may be hidden from the user in certain situations,
  /// while the user might be interrupted for a higher-priority notification.
  /// The effect of setting the same priorities may differ slightly on different platforms.
  ///
  /// - Note:This priority differs from `FCMAndroidMessagePriority`.
  /// This priority is processed by the client after the message has been delivered,
  /// whereas `FCMAndroidMessagePriority` is an FCM concept that controls when the message is delivered.
  public let notificationPriority: FCMAndroidNotificationPriority?
  /// If set to true, use the Android framework's default sound for the notification.
  ///
  /// Default values are specified in
  /// [config.xml](https://android.googlesource.com/platform/frameworks/base/+/master/core/res/res/values/config.xml).
  public let defaultSound: Bool?
  /// If set to true, use the Android framework's default vibrate pattern for the notification.
  ///
  /// Default values are specified in
  /// [config.xml](https://android.googlesource.com/platform/frameworks/base/+/master/core/res/res/values/config.xml).
  ///
  /// If `defaultVibrateTimings` is set to true and `vibrateTimings` is also set,
  /// the default value is used instead of the user-specified `vibrateTimings`.
  public let defaultVibrateTimings: Bool?
  /// If set to true, use the Android framework's default LED light settings for the notification.
  ///
  /// Default values are specified in
  /// [config.xml](https://android.googlesource.com/platform/frameworks/base/+/master/core/res/res/values/config.xml).
  ///
  /// If `defaultLightSettings` is set to true and `lightSettings`
  /// is also set, the user-specified `lightSettings` is used instead of the default value.
  public let defaultLightSettings: Bool?
  /// Set the vibration pattern to use.
  ///
  /// The first value indicates the Duration to wait before turning the vibrator on.
  /// The next value indicates the Duration to keep the vibrator on.
  /// Subsequent values alternate between Duration to turn the vibrator off and to turn the vibrator on.
  ///
  /// If `vibrateTimings` is set and `defaultVibrateTimings` is set to true,
  /// the default value is used instead of the user-specified `vibrateTimings`.
  public let vibrateTimings: [String]?
  /// Set the visibility of the notification.
  public let visibility: FCMAndroidVisibility?
  /// Sets the number of items this notification represents.
  ///
  /// May be displayed as a badge count for launchers that support badging.
  /// See [Notification Badge](https://developer.android.com/training/notify-user/badges).
  ///
  /// For example, this might be useful if you're using just one notification to represent multiple new messages
  /// but you want the count here to represent the number of total new messages.
  ///
  /// If zero or unspecified, systems that support badging use the default,
  /// which is to increment a number displayed on the long-press menu each time a new notification arrives.
  public let notificationCount: Int?
  /// Settings to control the notification's LED blinking rate and color if LED is available on the device.
  ///
  /// The total blinking time is controlled by the OS.
  public let lightSettings: FCMAndroidLightSettings?
  /// Contains the URL of an image that is going to be displayed in a notification.
  ///
  /// If present, it will override `FCMNotificationPayload.image`.
  public let image: String?

  enum CodingKeys: String, CodingKey {
    case title
    case body
    case icon
    case color
    case sound
    case tag
    case clickAction = "click_action"
    case bodyLocKey = "body_loc_key"
    case bodyLocArgs = "body_loc_args"
    case titleLocKey = "title_loc_key"
    case titleLocArgs = "title_loc_args"
    case channelID = "channel_id"
    case ticker
    case sticky
    case eventTime = "event_time"
    case localOnly = "local_only"
    case notificationPriority = "notification_priority"
    case defaultSound = "default_sound"
    case defaultVibrateTimings = "default_vibrate_timings"
    case defaultLightSettings = "default_light_settings"
    case vibrateTimings = "vibrate_timings"
    case visibility
    case notificationCount = "notification_count"
    case lightSettings = "light_settings"
    case image
  }

  public init(
    title: String? = nil,
    body: String? = nil,
    icon: String? = nil,
    color: String? = nil,
    sound: String? = nil,
    tag: String? = nil,
    clickAction: String? = nil,
    bodyLocKey: String? = nil,
    bodyLocArgs: [String]? = nil,
    titleLocKey: String? = nil,
    titleLocArgs: [String]? = nil,
    channelID: String? = nil,
    ticker: String? = nil,
    sticky: Bool? = nil,
    eventTime: Date? = nil,
    localOnly: Bool? = nil,
    notificationPriority: FCMAndroidNotificationPriority? = nil,
    defaultSound: Bool? = nil,
    defaultVibrateTimings: Bool? = nil,
    defaultLightSettings: Bool? = nil,
    vibrateTimings: [Double]? = nil,
    visibility: FCMAndroidVisibility? = nil,
    notificationCount: Int? = nil,
    lightSettings: FCMAndroidLightSettings? = nil,
    image: String? = nil
  ) {
    self.title = title
    self.body = body
    self.icon = icon
    self.color = color
    self.sound = sound
    self.tag = tag
    self.clickAction = clickAction
    self.bodyLocKey = bodyLocKey
    self.bodyLocArgs = bodyLocArgs
    self.titleLocKey = titleLocKey
    self.titleLocArgs = titleLocArgs
    self.channelID = channelID
    self.ticker = ticker
    self.sticky = sticky
    self.eventTime = eventTime
    self.localOnly = localOnly
    self.notificationPriority = notificationPriority
    self.defaultSound = defaultSound
    self.defaultVibrateTimings = defaultVibrateTimings
    self.defaultLightSettings = defaultLightSettings
    self.vibrateTimings = vibrateTimings?.map { "\($0)s" }
    self.visibility = visibility
    self.notificationCount = notificationCount
    self.lightSettings = lightSettings
    self.image = image
  }
}

/// Sphere of visibility of this notification,
/// which affects how and when the SystemUI reveals the notification's presence and contents in untrusted situations
/// (namely, on the secure lockscreen).
public enum FCMAndroidVisibility: String, Codable, Hashable {
  /// If unspecified, default to `private`
  case unspecified = "VISIBILITY_UNSPECIFIED"
  /// Show this notification on all lockscreens, but conceal sensitive or private information on secure lockscreens.
  case `private` = "PRIVATE"
  /// Show this notification in its entirety on all lockscreens.
  case `public` = "PUBLIC"
  /// Do not reveal any part of this notification on a secure lockscreen.
  case secret = "SECRET"
}

/// Priority levels of a Firebase Cloud Messaging (FCM) notification.
public enum FCMAndroidNotificationPriority: String, Codable, Hashable {
  /// Priority is unspecified
  case unspecified = "PRIORITY_UNSPECIFIED"
  /// Lowest notification priority.
  ///
  /// Notifications with this might not be shown to the user except under
  /// special circumstances, such as detailed notification logs.
  case min = "PRIORITY_MIN"
  /// Lower notification priority.
  ///
  /// The UI may choose to show the notifications smaller,
  /// or at a different position in the list, compared with notifications with `default`.
  case low = "PRIORITY_LOW"
  /// Default notification priority.
  ///
  /// If the application does not prioritize its own notifications, use this value for all notifications.
  case `default` = "PRIORITY_DEFAULT"
  /// Higher notification priority. Use this for more important notifications or alerts.
  ///
  /// The UI may choose to show these notifications larger,
  /// or at a different position in the notification lists, compared with notifications with `default`.
  case high = "PRIORITY_HIGH"
  /// Highest notification priority.
  ///
  /// Use this for the application's most important items that require the user's prompt attention or input.
  case max = "PRIORITY_MAX"
}

/// Settings to control Firebase Cloud Messaging (FCM) notification LED.
public struct FCMAndroidLightSettings: Codable, Hashable {
  /// Set color of the LED
  public let color: FCMColor
  /// Along with `offDuration`, define the blink rate of LED flashes.
  public let onDuration: String
  /// Along with `onDuration`, define the blink rate of LED flashes.
  public let offDuration: String

  enum CodingKeys: String, CodingKey {
    case color
    case onDuration = "light_on_duration"
    case offDuration = "light_off_duration"
  }

  public init(color: FCMColor, onDuration: Double, offDuration: Int) {
    self.color = color
    self.onDuration = "\(onDuration)s"
    self.offDuration = "\(offDuration)s"
  }
}

/// Represents a color in the RGBA color space.
public struct FCMColor: Codable, Hashable {
  /// The amount of red in the color as a value in the interval [0, 1].
  public let red: Double
  /// The amount of green in the color as a value in the interval [0, 1].
  public let green: Double
  /// The amount of blue in the color as a value in the interval [0, 1].
  public let blue: Double
  /// The fraction of this color that should be applied to the pixel.
  ///
  /// A value of 1.0 corresponds to a solid color, whereas a value of 0.0 corresponds to a completely transparent color.
  public let alpha: Double

  // swiftlint:enable line_length
  // swiftlint:disable:next file_length
}
