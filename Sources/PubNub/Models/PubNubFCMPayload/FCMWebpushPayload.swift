//
//  FCMWebpushPayload.swift
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

/// Firebase Cloud Messaging (FCM) [Webpush protocol](https://tools.ietf.org/html/rfc8030) options.
public struct FCMWebpushConfig: Codable, Hashable {
  /// HTTP headers defined in webpush protocol.
  ///
  /// Refer to [Webpush protocol](https://tools.ietf.org/html/rfc8030#section-5) for supported headers
  public let headers: [String: String]?
  /// Web Notification options
  ///
  /// Supports Notification instance properties as defined in
  /// [Web Notification API](https://developer.mozilla.org/en-US/docs/Web/API/Notification).
  public let notification: String?
  /// Options for features provided by the FCM SDK for Web.
  public let options: FCMWebpushFcmOptions?

  enum CodingKeys: String, CodingKey {
    case headers
    case notification
    case options = "fcm_options"
  }

  public init(
    headers: [String: String]? = nil,
    notification: String? = nil,
    options: FCMWebpushFcmOptions? = nil
  ) {
    self.headers = headers
    self.notification = notification
    self.options = options
  }
}

/// Firebase Cloud Messaging (FCM) Notification instance properties as defined in
/// [Web Notification API](https://developer.mozilla.org/en-US/docs/Web/API/Notification).
public struct FCMWebpushNotification: Codable, Hashable {
  /// The actions array of the notification.
  public let actions: [FCMWebpushAction]?
  /// The URL of the image used to represent the notification
  /// used when there is not enough space to display the notification itself.
  public let badge: String?
  /// The body string of the notification.
  public let body: String?
  /// The text direction of the notification.
  public let dir: FCMWebpushDirection?
  /// The language code of the notification
  public let lang: String?
  /// The ID of the notification (if any)
  public let tag: String?
  /// The URL of the image used as an icon of the notification
  public let icon: String?
  /// The URL of an image to be displayed as part of the notification
  public let image: String?
  /// Specifies whether the user should be notified after a new notification replaces an old one
  public let renotify: Bool?
  /// Whehter notification should remain active until the user clicks or dismisses it,
  /// rather than closing automatically.
  public let requireInteraction: Bool?
  /// Specifies whether the notification should be silent
  ///
  /// i.e., no sounds or vibrations should be issued, regardless of the device settings.
  public let silent: Bool?
  /// Specifies the time at which a notification is created or applicable (past, present, or future).
  public let timestamp: Date?
  /// The title of the notification as specified in the first parameter of the constructor.
  public let title: String?
  /// Specifies a vibration pattern for devices with vibration hardware to emit.
  public let vibrate: [UInt]?
}

/// Used to represent action buttons the user can click to interact
/// with Firebase Cloud Messaging (FCM) Webpush notifications.
public struct FCMWebpushAction: Codable, Hashable {
  /// The name of the action, which can be used to identify the clicked action
  public let action: String?
  /// The string describing the action that is displayed to the user.
  public let title: String?
  /// The URL of the image used to represent the notification
  /// when there is not enough space to display the notification itself.
  public let icon: String?
}

/// Indicates the text direction of the Firebase Cloud Messaging (FCM) Webpush notification
public enum FCMWebpushDirection: String, Codable, Hashable {
  /// Adopts the browser's language setting behaviour (the default.)
  case auto
  /// Displays text left to right
  case leftToRight = "ltr"
  /// Displays text right to left
  case rightToLeft = "rtl"
}

/// Options for features provided by the FCM SDK for Web.
public struct FCMWebpushFcmOptions: Codable, Hashable {
  /// The link to open when the user clicks on the notification.
  ///
  /// For all URL values, HTTPS is required.
  public let link: String?
}
