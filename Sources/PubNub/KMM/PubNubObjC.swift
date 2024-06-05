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
  private var statusListeners: [UUID: StatusListenerInterface] = [:]
  
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
      uuid: listener.uuid,
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
    if let underlyingListener = listeners[listener.uuid] {
      pubnub.removeEventListener(underlyingListener)
      listeners[listener.uuid] = nil
    }
  }
}

// MARK: - Status Listeners

@objc
public extension PubNubObjC {
  @objc
  func addStatusListener(listener: StatusListenerObjC) {
    let underlyingListener = StatusListener(onConnectionStateChange: { [weak pubnub] newStatus in
      guard let pubnub = pubnub else {
        return
      }
      switch newStatus {
      case .connected:
        listener.onStatusChange?(
          PubNubConnectionStatusObjC(
            category: .connected,
            error: nil,
            currentTimetoken: NSNumber(value: pubnub.previousTimetoken ?? 0),
            affectedChannels: Set(pubnub.subscribedChannels),
            affectedChannelGroups: Set(pubnub.subscribedChannelGroups)
          )
        )
      case .disconnected:
        listener.onStatusChange?(
          PubNubConnectionStatusObjC(
            category: .disconnected,
            error: nil,
            currentTimetoken: NSNumber(value: pubnub.previousTimetoken ?? 0),
            affectedChannels: Set(pubnub.subscribedChannels),
            affectedChannelGroups: Set(pubnub.subscribedChannelGroups)
          )
        )
      case .disconnectedUnexpectedly(let error):
        listener.onStatusChange?(
          PubNubConnectionStatusObjC(
            category: error.reason == .malformedResponseBody ? .malformedResponseCategory : .disconnectedUnexpectedly,
            error: error,
            currentTimetoken: NSNumber(value: pubnub.previousTimetoken ?? 0),
            affectedChannels: Set(pubnub.subscribedChannels),
            affectedChannelGroups: Set(pubnub.subscribedChannelGroups)
          )
        )
      case .connectionError(let error):
        listener.onStatusChange?(
          PubNubConnectionStatusObjC(
            category: error.reason == .malformedResponseBody ? .malformedResponseCategory : .connectionError,
            error: error,
            currentTimetoken: NSNumber(value: pubnub.previousTimetoken ?? 0),
            affectedChannels: Set(pubnub.subscribedChannels),
            affectedChannelGroups: Set(pubnub.subscribedChannelGroups)
          )
        )
      default:
        break
      }
    })
    
    statusListeners[underlyingListener.uuid] = underlyingListener
    pubnub.addStatusListener(underlyingListener)
  }
  
  @objc
  func removeStatusListener(listener: StatusListenerObjC) {
    if let underlyingListener = statusListeners[listener.uuid] {
      pubnub.removeStatusListener(underlyingListener)
      statusListeners[listener.uuid] = nil
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
  
  // TODO: Allow deleting messages from more than one channel
  
  func deleteMessages(
    from channels: [String],
    start: NSNumber?,
    end: NSNumber?,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let channel = channels.first else {
      onFailure(PubNubError(
        .invalidArguments,
        additional: ["Empty channel list for deleteMessages"]
      ))
      return
    }
    pubnub.deleteMessageHistory(
      from: channel,
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

// MARK: - App Context

extension PubNubObjC {
  private func sortProperties(
    from properties: [PubNubSortPropertyObjC]
  ) -> [PubNub.ObjectSortField] {
    properties.compactMap {
      if let property = PubNub.ObjectSortProperty(rawValue: $0.key) {
        return PubNub.ObjectSortField(property: property, ascending: $0.direction == "asc")
      } else {
        return nil
      }
    }
  }
  
  private func convertPage(from page: PubNubHashedPageObjC?) -> PubNubHashedPage {
    PubNub.Page(start: page?.start, end: page?.end, totalCount: page?.totalCount?.intValue)
  }
}

@objc
public extension PubNubObjC {
  // TODO: Resolve status and totalCount for response (PubNubGetChannelMetadataResultObjC)
  @objc
  func getAllChannelMetadata(
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [PubNubSortPropertyObjC],
    includeCount: Bool,
    includeCustom: Bool,
    onSuccess: @escaping ((PubNubGetChannelMetadataResultObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.allChannelMetadata(
      include: PubNub.IncludeFields(custom: includeCustom, totalCount: includeCount),
      filter: filter,
      sort: sortProperties(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(PubNubGetChannelMetadataResultObjC(
          status: 200,
          data: res.channels.map { PubNubChannelMetadataObjC(metadata: $0) },
          totalCount: NSNumber(integerLiteral: res.channels.count),
          next: PubNubHashedPageObjC(page: res.next)
        ))
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func getChannelMetadata(
    channel: String,
    includeCustom: Bool,
    onSuccess: @escaping ((PubNubChannelMetadataObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetch(channel: channel, include: includeCustom) {
      switch $0 {
      case .success(let metadata):
        onSuccess(PubNubChannelMetadataObjC(metadata: metadata))
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func removeChannelMetadata(
    channel: String,
    onSuccess: @escaping ((String) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.remove(channel: channel) {
      switch $0 {
      case .success(let channel):
        onSuccess(channel)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  // TODO: Resolve status and totalCount for response (PubNubGetUUIDMetadaResultObjC)
  @objc
  func getAllUUIDMetadata(
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [PubNubSortPropertyObjC],
    includeCount: Bool,
    includeCustom: Bool,
    onSuccess: @escaping ((PubNubGetUUIDMetadaResultObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.allUUIDMetadata(
      include: PubNub.IncludeFields(custom: includeCustom, totalCount: includeCount),
      filter: filter,
      sort: sortProperties(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(PubNubGetUUIDMetadaResultObjC(
          status: 200,
          data: res.uuids.map { PubNubUUIDMetadataObjC(metadata: $0) },
          totalCount: NSNumber(integerLiteral: res.uuids.count),
          next: PubNubHashedPageObjC(page: res.next)
        ))
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc func removeUUIDMetadata(
    uuid: String?,
    onSuccess: @escaping ((String) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.remove(uuid: uuid) {
      switch $0 {
      case .success(let result):
        onSuccess(result)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func getUUIDMetadata(
    uuid: String?,
    includeCustom: Bool,
    onSuccess: @escaping ((PubNubUUIDMetadataObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetch(uuid: uuid, include: includeCustom) {
      switch $0 {
      case .success(let metadata):
        onSuccess(PubNubUUIDMetadataObjC(metadata: metadata))
      case .failure(let error):
        onFailure(error)
      }
    }
  }
}
