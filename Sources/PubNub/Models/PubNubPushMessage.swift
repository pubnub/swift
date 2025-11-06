//
//  PubNubPushMessage.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public struct PubNubPushMessage: JSONCodable {
  /// The payload delivered via Apple Push Notification Service (APNS)
  public let apns: PubNubAPNSPayload?
  /// The payload delivered via Firebase Cloud Messaging Service (FCM)
  public let fcm: PubNubFCMPayload?

  /// Additional message payload sent outside of the push notification
  ///
  /// In order to guarantee valid JSON any scalar values will be assigned to the `data` key.
  /// Non-scalar values will retain their coding keys.
  public var additionalMessage: JSONCodable?

  enum CodingKeys: String, CodingKey {
    case apns = "pn_apns"
    case fcm = "pn_fcm"
    case additionalMessage = "data"
  }

  public init(
    apns: PubNubAPNSPayload? = nil,
    fcm: PubNubFCMPayload? = nil,
    additional message: JSONCodable? = nil
  ) {
    self.apns = apns
    self.fcm = fcm
    additionalMessage = message
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    apns = try container.decodeIfPresent(PubNubAPNSPayload.self, forKey: .apns)
    fcm = try container.decodeIfPresent(PubNubFCMPayload.self, forKey: .fcm)
  }

  public func encode(to encoder: Encoder) throws {
    if !(additionalMessage?.codableValue.isScalar ?? true) {
      try additionalMessage?.codableValue.encode(to: encoder)
    }

    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(apns, forKey: .apns)
    try container.encodeIfPresent(fcm, forKey: .fcm)

    if additionalMessage?.codableValue.isScalar ?? true {
      try container.encodeIfPresent(additionalMessage?.codableValue, forKey: .additionalMessage)
    }
  }
}
