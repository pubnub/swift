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
public class PubNubObjC: NSObject {
  private let pubnub: PubNub
  private var listeners: [UUID: EventListenerInterface] = [:]

  // MARK: - Init

  @objc
  public init(user: String, subKey: String, pubKey: String) {
    self.pubnub = PubNub(configuration: PubNubConfiguration(publishKey: pubKey, subscribeKey: subKey, userId: user))
    super.init()
  }
}

// MARK: - Event Listeners

@objc
public extension PubNubObjC {
  @objc
  func addEventListener(listener: EventListenerObjC) {
    let underlyingListener = EventListener(
      uuid: UUID(uuidString: listener.uuid)!,
      onMessage: { listener.onMessage?(PubNubMessageObjC(message: $0)) },
      onSignal: { listener.onSignal?(PubNubMessageObjC(message: $0)) },
      onPresence: { listener.onPresence?(PubNubPresenceEventResultObjC.from(change: $0)) },
      onMessageAction: { listener.onMessageAction?(PubNubMessageActionObjC(action: $0)) },
      onFileEvent: { [weak pubnub] in listener.onFile?(PubNubFileEventResultObjC.from(event: $0, with: pubnub)) },
      onAppContext: { listener.onAppContext?(PubNubObjectEventResultObjC.from(event: $0)) }
    )

    listeners[underlyingListener.uuid] = underlyingListener
    pubnub.addEventListener(underlyingListener)
  }
  
  @objc
  func removeEventListener(listener: EventListenerObjC) {
    if let uuid = UUID(uuidString: listener.uuid), let underlyingListener = listeners[uuid] {
      pubnub.removeEventListener(underlyingListener)
      listeners[uuid] = nil
    }
  }
}

// MARK: - Subscribed channels & channel groups

@objc
public extension PubNubObjC {
  @objc
  var subscribedChannels: [String] {
    pubnub.subscribedChannels
  }
  
  @objc
  var subscribedChannelGroups: [String] {
    pubnub.subscribedChannelGroups
  }
}

// MARK: - Subscribe & Unsubscribe

@objc
public extension PubNubObjC {
  @objc
  func subscribe(
    channels: [String],
    channelGroups: [String],
    withPresence: Bool,
    timetoken: Timetoken
  ) {
    pubnub.subscribe(
      to: channels,
      and: channelGroups,
      at: timetoken,
      withPresence: withPresence
    )
  }
    
  @objc
  func unsubscribe(
    from channels: [String],
    channelGroups: [String]
  ) {
    pubnub.unsubscribe(
      from: channels,
      and: channelGroups
    )
  }
}

// MARK: - Publish

@objc
public extension PubNubObjC {
  @objc
  func publish(
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
}

// MARK: - Signal

@objc
public extension PubNubObjC {
  @objc
  func signal(
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
}

// MARK: - Push registration

@objc
public extension PubNubObjC {
  @objc
  func addChannelsToPushNotifications(
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
  func listPushChannels(
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
  func removeChannelsFromPush(
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
  func removeAllChannelsFromPush(
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
}

// MARK: - History

@objc
public extension PubNubObjC {
  @objc
  func fetchMessages(
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
        start: page?.start?.uint64Value,
        end: page?.end?.uint64Value,
        limit: page?.limit?.intValue
      )
    ) {
      switch $0 {
      case .success(let response):
        onSuccess(PubNubFetchMessagesResultObjC(
          messages: response.messagesByChannel.mapValues { $0.map { PubNubMessageObjC(message: $0) } },
          page: PubNubBoundedPageObjC(page: response.next)
        ))
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func deleteMessages(
    from channels: [String],
    start: NSNumber?,
    end: NSNumber?,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    // TODO: Channel list is not supported
    pubnub.deleteMessageHistory(
      from: channels.first!,
      start: start?.uint64Value,
      end: end?.uint64Value
    ) {
      switch $0 {
      case .success:
        onSuccess()
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func messageCounts(
    for channels: [String],
    channelsTimetokens: [Timetoken],
    onSuccess: @escaping ((PubNubMessageCountResultObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    let keys = Set(channels)
    let count = min(keys.count, channelsTimetokens.count)
    let dictionary = Dictionary(uniqueKeysWithValues: zip(keys.prefix(count), channelsTimetokens.prefix(count)))
    
    pubnub.messageCounts(channels: dictionary) {
      switch $0 {
      case .success(let response):
        onSuccess(PubNubMessageCountResultObjC(channels: response.mapValues { UInt64($0) }))
      case .failure(let error):
        onFailure(error)
      }
    }
  }
}
