//
//  PubNubConfiguration.swift
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

/// A configuration object that defines behavior and policies for a PubNub session.
public struct PubNubConfiguration: Hashable {
  /// A default session configuration object.
  public static var `default` = PubNubConfiguration()

  /// Creates a configuration from the Info.plist contents of the specified Bundle
  ///
  /// You can set these values in the Info.plist of the application by using:
  /// - `PubNubPublishKey` for your PubNub Publish Key
  /// - `PubNubSubscribeKey` for your PubNub Subscribe Key
  ///
  /// - Parameters:
  ///   - from: `Bundle` that will provide the Info Dictionary containing the PubNub Pub/Sub keys.
  ///   - using: The dictionary key used to search the Info Dictionary of the `Bundle` for the Publish Key Value
  ///   - and: The dictionary key used to search the Info Dictionary of the `Bundle` for the Subscribe Key Value
  public init(from bundle: Bundle = .main,
              using pubPlistKey: String = "PubNubPublishKey", and subPlistKey: String = "PubNubSubscribeKey") {
    self.init(
      publishKey: bundle.infoDictionary?[pubPlistKey] as? String,
      subscribeKey: bundle.infoDictionary?[subPlistKey] as? String
    )
  }

  /// Creates a configuration using the specified PubNub Publish and Subscribe Keys
  ///
  /// - Attention: It is recommended that you use this initializer only if you have a
  /// custom way to pass your PubNub Publish and Subscribe keys without storing them
  /// inside your source code/code repository.
  ///
  /// - Parameters:
  ///   - publishKey: The PubNub Publish Key to be used when publishing data to a channel
  ///   - subscribeKey: The PubNub Subscribe Key to be used when getting data from a channel
  public init(publishKey: String?, subscribeKey: String?) {
    self.publishKey = publishKey
    self.subscribeKey = subscribeKey
  }

  /// Specifies the PubNub Publish Key to be used when publishing messages to a channel
  public var publishKey: String?
  /// Specifies the PubNub Subscribe Key to be used when subscribing to a channel
  public var subscribeKey: String?
  /// If set, all communication will be encrypted with this key
  public var cipherKey: Crypto?
  /// If Access Manager (PAM) is enabled, client will use `authKey` on all requests
  public var authKey: String?
  /// UUID to be used as a device identifier
  public var uuid: String = UUID().pubnubString
  /// If true, requests will be made over `https`, otherwise they will use 'http'
  ///
  /// You will still need to disable ATS for the system to allow insecure network traffic.
  ///
  /// See Apple's
  /// [documentation](https://developer.apple.com/documentation/security/preventing_insecure_network_connections)
  /// for further details.
  public var useSecureConnections: Bool = true
  /// Full origin (`subdomain`.`domain`) used for requests
  public var origin: String = "ps.pndsn.com"
  /// Whether a PubNub object instanceId should be included on outgoing requests
  public var useInstanceId: Bool = false
  /// Whether a request identifier should be included on outgoing requests
  public var useRequestId: Bool = false
  /// Reconnection policy which will be used if/when a request fails
  public var automaticRetry: AutomaticRetry?
  /// URLSessionConfiguration used for URLSession network events
  public var urlSessionConfiguration: URLSessionConfiguration = .pubnub
  /// How long (in seconds) the server will consider the client alive for presence
  ///
  /// - NOTE: The minimum value this field can be is 20
  @BoundedValue(min: 20, max: UInt.max) public var durationUntilTimeout: UInt = 300

  /// How often (in seconds) the client will announce itself to server
  ///
  /// - NOTE: The minimum value this field can be is 0
  public var heartbeatInterval: UInt = 0
  /// Whether to send out the leave requests
  public var supressLeaveEvents: Bool = false
  /// The number of messages into the payload before emitting `RequestMessageCountExceeded`
  public var requestMessageCountThreshold: UInt = 100
  /// PSV2 feature to subscribe with a custom filter expression.
  public var filterExpression: String?
}
