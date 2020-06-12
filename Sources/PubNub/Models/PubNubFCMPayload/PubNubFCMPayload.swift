//
//  PubNubFCMPayload.swift
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
/// Message to send by Firebase Cloud Messaging Service
///
/// For more infomration see
/// [FCM Messaging Overview](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
public struct PubNubFCMPayload: Codable {
  /// Arbitrary key/value payload.
  ///
  /// The payload of the FCM notification
  /// - Warning: The key should not be a reserved word (`"from"`, `"message_type"`,
  /// or any word starting with `"google"` or `"gcm"`).
  public let payload: JSONCodable?
  /// Basic notification template to use across all platforms.
  public let notification: FCMNotificationPayload?
  /// Android specific options for messages sent through [FCM connection server](https://goo.gl/4GLdUl).
  public let android: FCMAndroidPayload?
  /// [Webpush protocol](https://tools.ietf.org/html/rfc8030) options
  public let webpush: FCMWebpushConfig?
  /// [Apple Push Notification Service](https://goo.gl/MXRTPa) specific options
  public let apns: FCMApnsConfig?
  /// Template for FCM SDK feature options to use across all platforms.
  public let options: FCMOptionsPayload?
  /// Target to send a message to
  public let target: FCMTarget?

  enum CodingKeys: String, CodingKey {
    case payload = "data"
    case notification
    case android
    case webpush
    case apns
    case options = "fcm_options"
  }

  public init(
    payload: JSONCodable?,
    target: FCMTarget?,
    notification: FCMNotificationPayload? = nil,
    android: FCMAndroidPayload? = nil,
    webpush: FCMWebpushConfig? = nil,
    apns: FCMApnsConfig? = nil,
    options: FCMOptionsPayload? = nil
  ) {
    self.payload = payload
    self.target = target
    self.notification = notification
    self.android = android
    self.webpush = webpush
    self.apns = apns
    self.options = options
  }

  public init(from decoder: Decoder) throws {
    target = try? FCMTarget(from: decoder)

    let container = try decoder.container(keyedBy: CodingKeys.self)
    payload = try container.decodeIfPresent(AnyJSON.self, forKey: .payload)
    notification = try container.decode(FCMNotificationPayload.self, forKey: .notification)
    android = try container.decodeIfPresent(FCMAndroidPayload.self, forKey: .android)
    webpush = try container.decodeIfPresent(FCMWebpushConfig.self, forKey: .webpush)
    apns = try container.decodeIfPresent(FCMApnsConfig.self, forKey: .apns)
    options = try container.decodeIfPresent(FCMOptionsPayload.self, forKey: .options)
  }

  public func encode(to encoder: Encoder) throws {
    // Preserve the key names of target
    try target?.encode(to: encoder)

    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(payload?.codableValue, forKey: .payload)
    try container.encode(notification, forKey: .notification)
    try container.encodeIfPresent(android, forKey: .android)
    try container.encodeIfPresent(webpush, forKey: .webpush)
    try container.encodeIfPresent(apns, forKey: .apns)
    try container.encodeIfPresent(options, forKey: .options)
  }
}

/// Target to send a Firebase Cloud Messaging (FCM) message to
public enum FCMTarget: Codable, Hashable {
  /// Registration token to send a message to
  case token(String)
  /// Topic name to send a message to
  ///
  /// e.g. "weather". Note: "/topics/" prefix should not be provided.
  case topic(String)
  /// Condition to send a message to
  ///
  /// e.g. "'foo' in topics && 'bar' in topics".
  case condition(String)

  enum CodingKeys: String, CodingKey {
    case token
    case topic
    case condition
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let value = try? container.decode(String.self, forKey: .token) {
      self = .token(value)
    } else if let value = try? container.decode(String.self, forKey: .topic) {
      self = .topic(value)
    } else {
      self = .condition(try container.decode(String.self, forKey: .condition))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .token(value):
      try container.encode(value, forKey: .token)
    case let .topic(value):
      try container.encode(value, forKey: .topic)
    case let .condition(value):
      try container.encode(value, forKey: .condition)
    }
  }
}

/// Basic notification template to use across all platforms.
public struct FCMNotificationPayload: Codable, Hashable {
  /// The notification's title.
  public let title: String?
  /// The notification's body text.
  public let body: String?
  /// Contains the URL of an image that is going to be downloaded on the device and displayed in a notification.
  ///
  /// JPEG, PNG, BMP have full support across platforms.
  ///
  /// Animated GIF and video only work on iOS.
  ///
  /// WebP and HEIF have varying levels of support across platforms and platform versions.
  ///
  /// Android has 1MB image size limit.
  ///
  /// Quota usage and implications/costs for hosting image on [Firebase Storage](https://firebase.google.com/pricing)
  public let image: String?

  public init(
    title: String? = nil,
    body: String? = nil,
    image: String? = nil
  ) {
    self.title = title
    self.body = body
    self.image = image
  }
}

/// Platform independent options for features provided by the FCM SDKs.
public struct FCMOptionsPayload: Codable, Hashable {
  /// Label associated with the message's analytics data.
  public let analyticsLabel: String?

  enum CodingKeys: String, CodingKey {
    case analyticsLabel = "analytics_label"
  }

  public init(analyticsLabel: String? = nil) {
    self.analyticsLabel = analyticsLabel
  }
}

// MARK: - FCM APNS

/// Firebase Cloud Messaging (FCM) [Apple Push Notification Service](https://goo.gl/MXRTPa) specific options.
public struct FCMApnsConfig: Codable, Hashable {
  /// HTTP request headers defined in Apple Push Notification Service.
  ///
  /// Refer to [APNs request headers](https://goo.gl/C6Yhia) for supported headers
  public let headers: [String: String]?
  /// The `APS` payload to be included in all notifications through APNS
  public let payload: APSPayload?
  /// Options for features provided by the FCM SDK for iOS.
  public let options: FCMApnsFcmOptions?

  enum CodingKeys: String, CodingKey {
    case headers
    case payload
    case options = "fcm_options"
  }

  public init(
    headers: [String: String]? = nil,
    payload: APSPayload? = nil,
    options: FCMApnsFcmOptions? = nil
  ) {
    self.headers = headers
    self.payload = payload
    self.options = options
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    headers = try container.decode([String: String].self, forKey: .headers)
    guard let payload = try container.decode([String: APSPayload].self, forKey: .payload)["aps"] else {
      let context = DecodingError.Context(codingPath: [CodingKeys.payload],
                                          debugDescription: "`aps` key missing inside `payload`")
      throw DecodingError.keyNotFound(CodingKeys.payload, context)
    }
    self.payload = payload
    options = try container.decode(FCMApnsFcmOptions.self, forKey: .options)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(headers, forKey: .headers)
    try container.encode(["aps": payload], forKey: .payload)
    try container.encode(options, forKey: .options)
  }
}

/// Options for features provided by the FCM SDK for iOS.
public struct FCMApnsFcmOptions: Codable, Hashable {
  /// Label associated with the message's analytics data.
  public let analyticsLabel: String?
  /// Contains the URL of an image that is going to be displayed in a notification.
  ///
  /// If present, it will override `FCMNotificationPayload.image`.
  public let image: String?

  enum CodingKeys: String, CodingKey {
    case analyticsLabel = "analytics_label"
    case image
  }

  public init(
    analyticsLabel: String? = nil,
    image: String? = nil
  ) {
    self.analyticsLabel = analyticsLabel
    self.image = image
  }
}
