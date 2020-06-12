//
//  PubNubPushMessage.swift
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

public struct PubNubPushMessage: JSONCodable {
  /// The payload delivered via Apple Push Notification Service (APNS)
  public let apns: PubNubAPNSPayload?
  /// The payload delivered via Firebase Cloud Messaging Service (FCM)
  public let fcm: PubNubFCMPayload?
  /// The payload delivered via Microsoft Push Notification Service (MPNS)
  public let mpns: JSONCodable?
  /// Additional message payload sent outside of the push notification
  ///
  /// In order to guarantee valid JSON any scalar values will be assigned to the `data` key.
  /// Non-scalar values will retain their coding keys.
  public var additionalMessage: JSONCodable?

  enum CodingKeys: String, CodingKey {
    case apns = "pn_apns"
    case fcm = "pn_gcm"
    case mpns = "pn_mpns"
    case additionalMessage = "data"
  }

  public init(
    apns: PubNubAPNSPayload? = nil,
    fcm: PubNubFCMPayload? = nil,
    mpns: JSONCodable? = nil,
    additional message: JSONCodable? = nil
  ) {
    self.apns = apns
    self.fcm = fcm
    self.mpns = mpns
    additionalMessage = message
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    apns = try container.decodeIfPresent(PubNubAPNSPayload.self, forKey: .apns)
    fcm = try container.decodeIfPresent(PubNubFCMPayload.self, forKey: .fcm)
    mpns = try container.decodeIfPresent(AnyJSON.self, forKey: .mpns)
  }

  public func encode(to encoder: Encoder) throws {
    if !(additionalMessage?.codableValue.isScalar ?? true) {
      try additionalMessage?.codableValue.encode(to: encoder)
    }

    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(apns, forKey: .apns)
    try container.encodeIfPresent(fcm, forKey: .fcm)
    try container.encodeIfPresent(mpns?.codableValue, forKey: .mpns)

    if additionalMessage?.codableValue.isScalar ?? true {
      try container.encodeIfPresent(additionalMessage?.codableValue, forKey: .additionalMessage)
    }
  }
}
