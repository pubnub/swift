//
//  PubNubObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class PubNubObjC : NSObject {
  private let pubnub: PubNub
  
  // MARK: - Init
  
  @objc
  public init(user: String, subKey: String, pubKey: String) {
    self.pubnub = PubNub(configuration: PubNubConfiguration(publishKey: pubKey, subscribeKey: subKey, userId: user))
    super.init()
  }
  
  // MARK: - Publish
  
  @objc
  public func publish(
    channel: String,
    message: Any,
    meta: Any?,
    shouldStore: NSNumber?,
    ttl: NSNumber?,
    onSuccess: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.publish(
      channel: channel,
      message: AnyJSON(message),
      shouldStore: shouldStore?.boolValue,
      storeTTL: shouldStore?.intValue,
      meta: resolveJSONObject(meta)
    ) {
      switch $0 {
      case .success(let timetoken):
        onSuccess(timetoken)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  private func resolveJSONObject(_ object: Any?) -> AnyJSON? {
    if let object = object {
      return AnyJSON(object)
    } else {
      return nil
    }
  }
  
  // MARK: Signal
  
  @objc
  public func signal(
    channel: String,
    message: Any,
    onSuccess: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.signal(channel: channel, message: AnyJSON(message)) {
      switch $0 {
      case .success(let timetoken):
        onSuccess(timetoken)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  // MARK: Subscribed channels & channel groups
  
  @objc
  public var subscribedChannels: [String] {
    pubnub.subscribedChannels
  }
  
  @objc
  public var subscribedChannelGroups: [String] {
    pubnub.subscribedChannelGroups
  }
  
  // MARK: Push registration
  
  @objc
  public func addChannelsToPushNotifications(
    channels: [String],
    deviceId: Data,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.addPushChannelRegistrations(channels, for: deviceId) {
      switch $0 {
      case .success(let channels):
        onSuccess(channels)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  public func listPushChannels(
    deviceId: Data,
    pushType: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushType = PubNub.PushService(rawValue: pushType) else {
      onFailure(PubNubError(.invalidArguments, additional: ["Invalid pushType parameter"])); return
    }
    pubnub.listPushChannelRegistrations(for: deviceId, of: pushType) {
      switch $0 {
      case .success(let channels):
        onSuccess(channels)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  public func removeChannelsFromPush(
    channels: [String],
    deviceId: Data,
    pushType: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushType = PubNub.PushService(rawValue: pushType) else {
      onFailure(PubNubError(.invalidArguments, additional: ["Invalid pushType parameter"])); return
    }
    pubnub.removePushChannelRegistrations(channels, for: deviceId, of: pushType) {
      switch $0 {
      case .success(let channels):
        onSuccess(channels)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  public func removeAllChannelsFromPush(
    pushType: String,
    deviceId: Data,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushType = PubNub.PushService(rawValue: pushType) else {
      onFailure(PubNubError(.invalidArguments, additional: ["Invalid pushType parameter"])); return
    }
    pubnub.removeAllPushChannelRegistrations(for: deviceId, of: pushType) {
      switch $0 {
      case .success:
        onSuccess()
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  // MARK: History
  
  @objc
  public func fetchMessages(
    from channels: [String],
    includeUUID: Bool,
    includeMeta: Bool,
    includeMessageActions: Bool,
    includeMessageType: Bool,
    page: PubNubBoundedPageObjC?,
    onSuccess: @escaping (([String: [PubNubMessageObjC]]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetchMessageHistory(
      for: channels,
      includeActions: includeMessageActions,
      includeMeta: includeMeta,
      includeUUID: includeUUID,
      includeMessageType: includeMessageType,
      page: PubNubBoundedPageBase(
        start: page?.start?.uint64Value ?? nil,
        end: page?.end?.uint64Value ?? nil,
        limit: page?.limit?.intValue ?? nil
      )
    ) {
      switch $0 {
      case .success(let response):
        onSuccess(response.messagesByChannel.mapValues {
          $0.map {
            PubNubMessageObjC(
              payload: $0.payload.codableValue,
              actions: $0.actions.map {
                PubNubMessageActionObjC(
                  actionType: $0.actionType,
                  actionValue: $0.actionValue,
                  actionTimetoken: $0.actionTimetoken,
                  messageTimetoken: $0.messageTimetoken,
                  publisher: $0.publisher,
                  channel: $0.channel,
                  subscription: $0.subscription,
                  published: $0.published != nil ? NSNumber(value: $0.published!) : nil
                )
              },
              publisher: $0.publisher,
              channel: $0.channel,
              subscription: $0.subscription,
              published: $0.published,
              metadata: $0.metadata?.codableValue,
              messageType: $0.messageType.rawValue,
              error: $0.error
            )
          }
        })
      case .failure(let error):
        onFailure(error)
      }
    }
  }
}

@objc
public class PubNubBoundedPageObjC: NSObject {
  @objc public let start: NSNumber?
  @objc public let end: NSNumber?
  @objc public let limit: NSNumber?

  public init(start: NSNumber?, end: NSNumber?, limit: NSNumber?) {
    self.start = start
    self.end = end
    self.limit = limit
  }
}

@objc
public class PubNubMessageObjC: NSObject {
  init(
    payload: Any,
    actions: [PubNubMessageActionObjC],
    publisher: String?,
    channel: String,
    subscription: String?,
    published: Timetoken,
    metadata: Any?,
    messageType: Int,
    error: Error?
  ) {
    self.payload = payload
    self.actions = actions
    self.publisher = publisher
    self.channel = channel
    self.subscription = subscription
    self.published = published
    self.metadata = metadata
    self.messageType = messageType
    self.error = error
  }
  
  @objc public let payload: Any
  @objc public let actions: [PubNubMessageActionObjC]
  @objc public let publisher: String?
  @objc public let channel: String
  @objc public let subscription: String?
  @objc public let published: Timetoken
  @objc public let metadata: Any?
  @objc public let messageType: Int
  @objc public let error: Error?
}

@objc
public class PubNubMessageActionObjC: NSObject {
  @objc public let actionType: String
  @objc public let actionValue: String
  @objc public let actionTimetoken: Timetoken
  @objc public let messageTimetoken: Timetoken
  @objc public let publisher: String
  @objc public let channel: String
  @objc public let subscription: String?
  @objc public let published: NSNumber?
  
  init(
    actionType: String,
    actionValue: String,
    actionTimetoken: Timetoken,
    messageTimetoken: Timetoken,
    publisher: String,
    channel: String,
    subscription: String?,
    published: NSNumber?
  ) {
    self.actionType = actionType
    self.actionValue = actionValue
    self.actionTimetoken = actionTimetoken
    self.messageTimetoken = messageTimetoken
    self.publisher = publisher
    self.channel = channel
    self.subscription = subscription
    self.published = published
  }
}
