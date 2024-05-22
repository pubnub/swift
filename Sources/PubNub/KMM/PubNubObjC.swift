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
  private var listeners: [UUID: EventListener] = [:]
  
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
      meta: meta != nil ? AnyJSON(meta as Any) : nil
    ) {
      switch $0 {
      case .success(let timetoken):
        onSuccess(timetoken)
      case .failure(let error):
        onFailure(error)
      }
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
  
  // MARK: Event Listeners
  
  @objc
  public func addEventListener(listener: EventListenerObjC) {
    let underlyingListener = EventListener(
      onMessage: {
        listener.onMessage?(PubNubMessageObjC(message: $0))
      },
      onSignal: {
        listener.onSignal?(PubNubMessageObjC(message: $0))
      },
      onPresence: {
        listener.onPresence?($0)
      },
      onMessageAction: {
        switch $0 {
        case .added(let messageAction):
          listener.onMessageActionAdded?(PubNubMessageActionObjC(action: messageAction))
        case .removed(let messageAction):
          listener.onMessageActionRemoved?(PubNubMessageActionObjC(action: messageAction))
        }
      },
      onFileEvent: {
        switch $0 {
        case .uploaded(let fileEvent):
          listener.onFile?(fileEvent)
        }
      },
      onAppContext: {
        switch $0 {
        case .channelMetadataRemoved(let metadataId):
          listener.onAppContext?(metadataId)
        case .channelMetadataSet(let changes):
          listener.onAppContext?(changes)
        case .userMetadataSet(let changes):
          listener.onAppContext?(changes)
        case .userMetadataRemoved(let metadataId):
          listener.onAppContext?(metadataId)
        case .membershipMetadataSet(let metadata):
          listener.onAppContext?(metadata)
        case .membershipMetadataRemoved(let metadata):
          listener.onAppContext?(metadata)
        }
      }
    )
    
    listeners[underlyingListener.uuid] = underlyingListener
    pubnub.addEventListener(underlyingListener)
  }
}
