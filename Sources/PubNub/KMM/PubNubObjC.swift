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
  var subscribedChannels: [String] {
    pubnub.subscribedChannels
  }

  var subscribedChannelGroups: [String] {
    pubnub.subscribedChannelGroups
  }
}

// MARK: - Subscribe & Unsubscribe

@objc
public extension PubNubObjC {
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

// MARK: - Time

@objc
public extension PubNubObjC {
  func time(
    onSuccess: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.time {
      switch $0 {
      case .success(let timetoken):
        onSuccess(timetoken)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
}

// MARK: - Presence

@objc
public extension PubNubObjC {
  @objc
  func hereNow(
    channels: [String],
    channelGroups: [String],
    includeState: Bool,
    includeUUIDs: Bool,
    onSuccess: @escaping ((PubNubHereNowResultObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.hereNow(
      on: channels,
      and: channelGroups,
      includeUUIDs: includeUUIDs,
      includeState: includeState
    ) {
      switch $0 {
      case let .success(map):
        onSuccess(
          PubNubHereNowResultObjC(
            totalChannels: map.count,
            totalOccupancy: map.values.reduce(0, { accResult, channel in accResult + channel.occupancy }),
            channels: map.mapValues { value in
              PubNubHereNowChannelDataObjC(
                channelName: value.channel,
                occupancy: value.occupancy,
                occupants: value.occupants.map {
                  PubNubHereNowOccupantDataObjC(
                    uuid: $0,
                    state: value.occupantsState[$0]?.rawValue
                  )
                }
              )
            }
          )
        )
      case let .failure(error):
        onFailure(error)
      }
    }
  }

  @objc
  func whereNow(
    uuid: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping (Error) -> Void
  ) {
    pubnub.whereNow(for: uuid) {
      switch $0 {
      case .success(let map):
        onSuccess(map[uuid] ?? [])
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func getPresenceState(
    channels: [String],
    channelGroups: [String],
    uuid: String,
    onSuccess: @escaping (([String: Any]) -> Void),
    onFailure: @escaping (Error) -> Void
  ) {
    pubnub.getPresenceState(
      for: uuid,
      on: channels,
      and: channelGroups
    ) {
      switch $0 {
      case .success(let response):
        onSuccess(response.stateByChannel.mapValues { $0.rawValue })
      case .failure(let error):
        onFailure(error)
      }
    }
  }
}

// MARK: - Message Actions

@objc
public extension PubNubObjC {
  func addMessageAction(
    channel: String,
    actionType: String,
    actionValue: String,
    messageTimetoken: Timetoken,
    onSuccess: @escaping ((PubNubAddMessageActionResultObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.addMessageAction(
      channel: channel,
      type: actionType,
      value: actionValue,
      messageTimetoken: messageTimetoken
    ) {
      switch $0 {
      case .success(let action):
        onSuccess(
          PubNubAddMessageActionResultObjC(
            type: action.actionType,
            value: action.actionValue,
            messageTimetoken: action.actionTimetoken
          )
        )
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func removeMessageAction(
    channel: String,
    messageTimetoken: Timetoken,
    actionTimetoken: Timetoken,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.removeMessageActions(
      channel: channel,
      message: messageTimetoken,
      action: actionTimetoken
    ) {
      switch $0 {
      case .success(_):
        onSuccess()
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func getMessageActions(
    from channel: String,
    page: PubNubBoundedPageObjC,
    onSuccess: @escaping ((PubNubGetMessageActionResultObjC) -> Void),
    onFailure: @escaping ((Error)) -> Void
  ) {
    pubnub.fetchMessageActions(
      channel: channel,
      page: PubNubBoundedPageBase(
        start: page.start?.uint64Value,
        end: page.end?.uint64Value,
        limit: page.limit?.intValue
      )
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(PubNubGetMessageActionResultObjC(
          actions: res.actions.map { PubNubMessageActionObjC(action: $0) },
          next: PubNubBoundedPageObjC(page: res.next)
        ))
      case .failure(let error):
        onFailure(error)
      }
    }
  }
}

// MARK: - Channel group management

@objc
public extension PubNubObjC {
  @objc
  func addChannels(
    to channelGroup: String,
    channels: [String],
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error)) -> Void
  ) {
    pubnub.add(
      channels: channels,
      to: channelGroup
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(res.channels)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func listChannels(
    for channelGroup: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.listChannels(for: channelGroup) {
      switch $0 {
      case .success(let res):
        onSuccess(res.channels)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func remove(
    channels: [String],
    from channelGroup: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error)) -> Void
  ) {
    pubnub.remove(channels: channels, from: channelGroup) {
      switch $0 {
      case .success(let res):
        onSuccess(res.channels)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func listChannelGroups(
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error)) -> Void
  ) {
    pubnub.listChannelGroups {
      switch $0 {
      case .success(let channelGroups):
        onSuccess(channelGroups)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func delete(
    channelGroup: String,
    onSuccess: @escaping ((String) -> Void),
    onFailure: @escaping ((Error)) -> Void
  ) {
    pubnub.remove(channelGroup: channelGroup) {
      switch $0 {
      case .success(let channelGroup):
        onSuccess(channelGroup)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
}

// MARK: - Token

@objc
public extension PubNubObjC {
  @objc
  func set(token: String) {
    pubnub.set(token: token)
  }
}
