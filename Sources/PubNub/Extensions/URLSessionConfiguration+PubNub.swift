//
//  URLSessionConfiguration+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public extension URLSessionConfiguration {
  /// Default configuration for PubNub URLSessions
  ///
  /// Sets `Accept-Encoding`, `Content-Type`, and `User-Agent` headers
  static var pubnub: URLSessionConfiguration {
    let configuration = URLSessionConfiguration.default

    configuration.headers = [
      Constant.acceptEncodingHeaderKey: Constant.defaultAcceptEncodingHeader,
      Constant.userAgentHeaderKey: Constant.defaultUserAgentHeader
    ]

    return configuration
  }

  /// Default URLSession used when PubNub makes upload/download tasks
  static var pubnubBackground: URLSessionConfiguration {
    let config = URLSessionConfiguration.background(withIdentifier: "pubnub.background")
    #if !targetEnvironment(simulator)
      config.isDiscretionary = true
    #endif

    // NOTE: Still in beta on macOS https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1617174-sessionsendslaunchevents
    #if !os(macOS)
      config.sessionSendsLaunchEvents = true
    #endif
    return config
  }

  /// Default configuration for PubNub subscription URLSessions
  ///
  /// Sets `Accept-Encoding`, `Content-Type`, and `User-Agent` headers.
  ///
  /// Also sets the `timeoutIntervalForRequest` to:
  ///
  /// *280s + timeoutIntervalForRequest default*
  static var subscription: URLSessionConfiguration {
    let configuration = URLSessionConfiguration.pubnub
    configuration.timeoutIntervalForRequest += Constant.minimumSubscribeRequestTimeout
    configuration.httpMaximumConnectionsPerHost = 1;

    return configuration
  }

  /// Convience for assigning `HTTPHeader` values to `httpAdditionalHeaders`
  var headers: [String: String] {
    get {
      return httpAdditionalHeaders as? [String: String] ?? [:]
    }
    set {
      httpAdditionalHeaders = newValue
    }
  }
}
