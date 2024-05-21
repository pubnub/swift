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
    onSuccess: @escaping ((PubNubFetchMessagesResultObjC)) -> Void,
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
        onSuccess(PubNubFetchMessagesResultObjC(
          messages: response.messagesByChannel.mapValues { $0.map { PubNubMessageObjC(message: $0) }},
          page: PubNubBoundedPageObjC(page: response.next)
        ))
      case .failure(let error):
        onFailure(error)
      }
    }
  }
}

@objc
public class PubNubFetchMessagesResultObjC: NSObject {
  @objc public let messages: [String: [PubNubMessageObjC]]
  @objc public let page: PubNubBoundedPageObjC?
  
  init(messages: [String: [PubNubMessageObjC]], page: PubNubBoundedPageObjC?) {
    self.messages = messages
    self.page = page
  }
}

@objc
public class PubNubBoundedPageObjC: NSObject {
  @objc public let start: NSNumber?
  @objc public let end: NSNumber?
  @objc public let limit: NSNumber?

  @objc public init(start: NSNumber?, end: NSNumber?, limit: NSNumber?) {
    self.start = start
    self.end = end
    self.limit = limit
  }
  
  init(page: PubNubBoundedPage?) {
    if let start = page?.start {
      self.start = NSNumber(value: start)
    } else {
      self.start = nil
    }
    if let end = page?.end {
      self.end = NSNumber(value: end)
    } else {
      self.end = nil
    }
    if let limit = page?.limit {
      self.limit = NSNumber(value: limit)
    } else {
      self.limit = nil
    }
  }
}

@objc
public class PubNubMessageObjC: NSObject {
  init(message: PubNubMessage) {
    self.payload = message.payload
    self.actions = message.actions.map { PubNubMessageActionObjC(action: $0) }
    self.publisher = message.publisher
    self.channel = message.channel
    self.subscription = message.subscription
    self.published = message.published
    self.metadata = message.metadata
    self.messageType = message.messageType.rawValue
    self.error = message.error
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
  
  init(action: PubNubMessageAction) {
    self.actionType = action.actionType
    self.actionValue = action.actionValue
    self.actionTimetoken = action.actionTimetoken
    self.messageTimetoken = action.messageTimetoken
    self.publisher = action.publisher
    self.channel = action.channel
    self.subscription = action.subscription
    self.published = action.published != nil ? NSNumber(value: action.published!) : nil
  }
}
