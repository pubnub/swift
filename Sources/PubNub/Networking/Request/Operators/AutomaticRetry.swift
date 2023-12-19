//
//  AutomaticRetry.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// Reconnection policy which will be used if/when a request fails
public struct AutomaticRetry: RequestOperator, Hashable {
  /// Exponential backoff twice for any 500 response code or `URLError` contained in `defaultRetryableURLErrorCodes`
  public static var `default` = AutomaticRetry()
  /// No retry will be performed
  public static var none = AutomaticRetry(retryLimit: 1)
  /// Retry on lost network connection
  public static var connectionLost = AutomaticRetry(
    policy: .defaultLinear,
    retryableURLErrorCodes: [.networkConnectionLost]
  )
  /// Exponential backoff twice when no internet connection is detected
  public static var noInternet = AutomaticRetry(
    policy: .defaultExponential,
    retryableURLErrorCodes: [.notConnectedToInternet]
  )
  // The minimum value allowed between retries
  static let minDelay: UInt = 2
  
  /// Provides the action taken when a retry is to be performed
  public enum ReconnectionPolicy: Hashable {
    /// Exponential backoff with base/scale factor of 2, and a 150s max delay
    public static let defaultExponential: ReconnectionPolicy = .exponential(minDelay: minDelay, maxDelay: 150)
    /// Linear reconnect every 2 seconds
    public static let defaultLinear: ReconnectionPolicy = .linear(delay: Double(minDelay))

    /// Reconnect with an exponential backoff
    case exponential(minDelay: UInt, maxDelay: UInt)
    /// Attempt to reconnect every X seconds
    case linear(delay: Double)

    func delay(for retryAttempt: Int) -> TimeInterval {
      /// Generates a random interval that's added to the final value
      /// Mitigates receiving 429 status code that's the result of too many requests in a given amount of time
      let randomDelay = Double.random(in: 0...1)
      
      switch self {
      case let .exponential(minDelay, maxDelay):
        return exponentialBackoffDelay(minDelay: minDelay, maxDelay: maxDelay, current: retryAttempt) + randomDelay
      case let .linear(delay):
        return delay + randomDelay
      }
    }

    func exponentialBackoffDelay(minDelay: UInt, maxDelay: UInt, current retryCount: Int) -> Double {
      return min(Double(maxDelay), Double(minDelay) * pow(2, Double(retryCount)))
    }
  }

  /// Collection of default `URLError.Code` objects that will trigger a retry
  public static let defaultRetryableURLErrorCodes: Set<URLError.Code> = [
    .badServerResponse,
    .callIsActive,
    .cannotConnectToHost,
    .cannotFindHost,
    .cannotLoadFromNetwork,
    .dataNotAllowed,
    .dnsLookupFailed,
    .internationalRoamingOff,
    .networkConnectionLost,
    .notConnectedToInternet,
    .secureConnectionFailed,
    .serverCertificateHasBadDate,
    .serverCertificateNotYetValid,
    .timedOut
  ]

  /// The max amount of retries before returning an error
  public let retryLimit: UInt
  /// The policy for when a retry will occurr
  public let policy: ReconnectionPolicy
  /// Collection of returned HTTP Status Codes  that will trigger a retry
  public let retryableHTTPStatusCodes: Set<Int>
  /// Collection of returned `URLError.Code` objects that will trigger a retry
  public let retryableURLErrorCodes: Set<URLError.Code>
  /// The list of endpoints excluded from retrying
  public let excluded: [AutomaticRetry.Endpoint]

  public init(
    retryLimit: UInt = 6,
    policy: ReconnectionPolicy = .defaultExponential,
    retryableHTTPStatusCodes: Set<Int> = [500, 429],
    retryableURLErrorCodes: Set<URLError.Code> = AutomaticRetry.defaultRetryableURLErrorCodes,
    excluded endpoints: [AutomaticRetry.Endpoint] = [
      .addChannelsToGroup,
      .removeChannelsFromGroup,
      .listChannelsForGroup,
      .listChannelGroups,
      .removeChannelGroup,
      .publish,
      .fire,
      .signal,
      .time,
      .whereNow,
      .hereNow,
      .setPresence,
      .getPresence,
      .fetchMessageActions,
      .addMessageAction,
      .removeMessageAction,
      .fetchMessageHistory,
      .deleteMessageHistory,
      .messageCounts,
      .fetchMemberships,
      .addMemberships,
      .removeMemberships,
      .fetchUsers,
      .createUser,
      .removeUser,
      .fetchSpaces,
      .createSpace,
      .removeSpace,
      .listPushChannels,
      .managePushChannels,
      .listAPNSPushChannels,
      .manageAPNSDevices,
      .listFiles,
      .generateFileUploadURL,
      .publishFile,
      .removeFile
    ]
  ) {
    switch policy {
    case let .exponential(minDelay, maxDelay):
      var finalMinDelay: UInt = minDelay
      var finalMaxDelay: UInt = maxDelay
      var finalRetryLimit: UInt = retryLimit
      
      if finalRetryLimit > 10 {
        PubNub.log.warn("The `retryLimit` for exponential policy must be less than or equal 10")
        finalRetryLimit = 10
      }
      if finalMinDelay < Self.minDelay {
        PubNub.log.warn("The `minDelay` must be a minimum of \(Self.minDelay)")
        finalMinDelay = Self.minDelay
      }
      if finalMinDelay > finalMaxDelay {
        PubNub.log.warn("The `minDelay` \"\(minDelay)\" must be greater or equal `maxDelay` \"\(maxDelay)\"")
        finalMaxDelay = minDelay
      }
      self.retryLimit = finalRetryLimit
      self.policy = .exponential(minDelay: finalMinDelay, maxDelay: finalMaxDelay)
      
    case let .linear(delay):
      var finalRetryLimit = retryLimit
      var finalDelay = delay
      
      if finalRetryLimit > 10 {
        PubNub.log.warn("The `retryLimit` for linear policy must be less than or equal 10")
        finalRetryLimit = 10
      }
      if finalDelay < 0 || UInt(finalDelay) < Self.minDelay {
        PubNub.log.warn("The `linear.delay` must be greater than or equal \(Self.minDelay).")
        finalDelay = Double(Self.minDelay)
      }
      self.retryLimit = finalRetryLimit
      self.policy = .linear(delay: finalDelay)
    }
    
    self.retryableHTTPStatusCodes = retryableHTTPStatusCodes
    self.retryableURLErrorCodes = retryableURLErrorCodes
    self.excluded = endpoints
  }

  public func retry(
    _ request: RequestReplaceable,
    for _: SessionReplaceable,
    dueTo error: Error,
    completion: @escaping (Result<TimeInterval, Error>) -> Void
  ) {
    guard request.retryCount < retryLimit, shouldRetry(response: request.urlResponse, error: error) else {
      completion(.failure(error))
      return
    }
    
    let urlResponse = request.urlResponse
    let retryAfterValue = urlResponse?.allHeaderFields[Constant.retryAfterHeaderKey]
    
    if let retryAfterValue = retryAfterValue as? TimeInterval {
      return completion(.success(retryAfterValue))
    } else {
      return completion(.success(policy.delay(for: request.retryCount)))
    }
  }

  func shouldRetry(response: HTTPURLResponse?, error: Error) -> Bool {
    if let statusCode = response?.statusCode {
      return retryableHTTPStatusCodes.contains(statusCode)
    } else if let errorCode = error.urlError?.code, retryableURLErrorCodes.contains(errorCode) {
      return true
    } else if let errorCode = error.pubNubError?.underlying?.urlError?.code, retryableURLErrorCodes.contains(errorCode) {
      return true
    }
    return false
  }
  
  public subscript(endpoint: AutomaticRetry.Endpoint) -> RequestOperator? {
    excluded.contains(endpoint) ? nil : self
  }
  
  /// List of endpoints possible to retry
  public enum Endpoint {
    /// Adding a channel to the channel group
    case addChannelsToGroup
    /// Removing a channel from the channel group
    case removeChannelsFromGroup
    /// Listing all the channels of the channel group
    case listChannelsForGroup
    /// Listing all the channel groups
    case listChannelGroups
    /// Removing the channel group
    case removeChannelGroup
    /// Publishing a message to the channel
    case publish
    /// Publishing a message to PubNub Functions Event Handlers
    case fire
    /// Publish a message to PubNub Functions Event Handlers
    case signal
    /// Getting current `Timetoken` from System
    case time
    /// Subscribing to channels and/or channel groups
    case subscribe
    /// Informing Presence that a user is still active
    case heartbeat
    /// Obtaining information about the current list of channels a UUID is subscribed to
    case whereNow
    /// Obtaining information about the current state of a channel
    case hereNow
    /// Setting state dictionary pairs specific to a subscriber UUID
    case setPresence
    /// Getting state dictionary pairs from a specific subscriber uuid
    case getPresence
    /// Fetching a list of Message Actions for a channel
    case fetchMessageActions
    /// Add an Action to a Message
    case addMessageAction
    /// Removes a Message Action from a published Message
    case removeMessageAction
    /// Fetching historical messages of a channel
    case fetchMessageHistory
    /// Removing the messages from the history of a specific channel
    case deleteMessageHistory
    /// Returning the number of messages published for one or more channels
    case messageCounts
    /// Fetching all `PubNubMembership` linked to a specific `PubNubUser.id`
    case fetchMemberships
    /// Adding a `PubNubMembership` relationship between a `PubNubSpace` and one or more `PubNubUser`
    case addMemberships
    /// Removing the `PubNubMembership` relationship
    case removeMemberships
    /// Fetching one or all `PubNubUser` that exist on a keyset
    case fetchUsers
    /// Creating a new `PubNubUser`
    case createUser
    /// Removing a previously created `PubNubUser` (if it existed)
    case removeUser
    /// Fetching one or all `PubNubSpace` that exist on a keyset
    case fetchSpaces
    /// Creating a new `PubNubSpace`
    case createSpace
    /// Updating an existing`PubNubSpace`
    case removeSpace
    /// Getting channels on which push notification has been enabled using specified push token
    case listPushChannels
    /// Getting channels on which APNS push notification has been enabled using specified device token and topic
    case listAPNSPushChannels
    /// Adding/removing push notification functionality on provided set of channels
    case managePushChannels
    /// Adding/removing APNS push notification functionality on provided set of channels for a given topic
    case manageAPNSDevices
    /// Retrieve list of files uploaded to a channel
    case listFiles
    /// Generating a File Upload URL
    case generateFileUploadURL
    /// Publishing the `PubNubFile` representing the uploaded File
    case publishFile
    /// Removing file from specified `Channel`
    case removeFile
  }
}
