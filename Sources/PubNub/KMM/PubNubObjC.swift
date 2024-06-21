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
  private let defaultFileDownloadPath = FileManager.default.temporaryDirectory.appendingPathComponent("pubnub-chat-sdk")
  
  // MARK: - Init
  
  @objc
  public init(user: String, subKey: String, pubKey: String) {
    self.pubnub = PubNub(
      configuration: PubNubConfiguration(
        publishKey: pubKey,
        subscribeKey: subKey,
        userId: user
      )
    )
    super.init()
  }
}

// MARK: - Event Listeners & Status Listeners

extension PubNubObjC {
  func createEventListener(from listener: EventListenerObjC) -> EventListener {
    EventListener(
      uuid: listener.uuid,
      onMessage: { listener.onMessage?(PubNubMessageObjC(message: $0)) },
      onSignal: { listener.onSignal?(PubNubMessageObjC(message: $0)) },
      onPresence: { listener.onPresence?(PubNubPresenceEventResultObjC.from(change: $0)) },
      onMessageAction: { listener.onMessageAction?(PubNubMessageActionObjC(action: $0)) },
      onFileEvent: { [weak pubnub] in listener.onFile?(PubNubFileEventResultObjC.from(event: $0, with: pubnub)) },
      onAppContext: { listener.onAppContext?(PubNubObjectEventResultObjC.from(event: $0)) }
    )
  }
  
  func createStatusListener(from listener: StatusListenerObjC) -> StatusListener {
    StatusListener(onConnectionStateChange: { [weak pubnub] newStatus in
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
  }
}

@objc
public extension PubNubObjC {
  @objc
  func addStatusListener(listener: StatusListenerObjC) {
    pubnub.addStatusListener(createStatusListener(from: listener))
  }
  
  @objc
  func removeStatusListener(listener: StatusListenerObjC) {
    pubnub.removeStatusListener(with: listener.uuid)
  }
  
  @objc
  func addEventListener(listener: EventListenerObjC) {
    pubnub.addEventListener(createEventListener(from: listener))
  }
  
  @objc
  func removeEventListener(listener: EventListenerObjC) {
    pubnub.removeEventListener(with: listener.uuid)
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
  
  @objc
  func unsubscribeAll() {
    pubnub.unsubscribeAll()
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

extension PubNubObjC {
  func pushService(from rawString: String) -> PubNub.PushService? {
    switch rawString {
    case "gcm":
      return .fcm
    case "apns":
      return .apns
    case "mpns":
      return .mpns
    default:
      return nil
    }
  }
}

@objc
public extension PubNubObjC {
  func addChannelsToPushNotifications(
    channels: [String],
    deviceId: Data,
    pushType: String,
    onSuccess: @escaping (([String]) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let pushService = pushService(from: pushType) else {
      onFailure(PubNubError(.invalidArguments, additional: ["Invalid pushType parameter"])); return
    }
    pubnub.addPushChannelRegistrations(channels, for: deviceId, of: pushService) {
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
    guard let pushService = pushService(from: pushType) else {
      onFailure(PubNubError(.invalidArguments, additional: ["Invalid pushType parameter"])); return
    }
    pubnub.listPushChannelRegistrations(for: deviceId, of: pushService) {
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
    guard let pushService = pushService(from: pushType) else {
      onFailure(PubNubError(.invalidArguments, additional: ["Invalid pushType parameter"])); return
    }
    pubnub.removePushChannelRegistrations(channels, for: deviceId, of: pushService) {
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
    guard let pushService = pushService(from: pushType) else {
      onFailure(PubNubError(.invalidArguments, additional: ["Invalid pushType parameter"])); return
    }
    pubnub.removeAllPushChannelRegistrations(for: deviceId, of: pushService) {
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
  
  // TODO: Adjust setPresence method from Swift SDK to take JSONCodable
  
  @objc
  func setPresenceState(
    channels: [String],
    channelGroups: [String],
    state: AnyJSONObjC,
    onSuccess: @escaping ((AnyJSONObjC) -> Void),
    onFailure: @escaping (Error) -> Void
  ) {
    pubnub.setPresence(
      state: [:],
      on: channels,
      and: channelGroups
    ) {
      switch $0 {
      case .success(let codable):
        onSuccess(AnyJSONObjC(codable.rawValue))
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
  private func objectSortProperties(from properties: [PubNubSortPropertyObjC]) -> [PubNub.ObjectSortField] {
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
  
  private func mapToMembershipSortFields(from array: [String]) -> [PubNub.MembershipSortField] {
    // TODO: What about status field?
    array.compactMap {
      switch $0 {
      case "channel.id", "uuid.id":
        return PubNub.MembershipSortField(property: .object(.id))
      case "channel.name", "uuid.name":
        return PubNub.MembershipSortField(property: .object(.name))
      case "channel.updated", "uuid.updated":
        return PubNub.MembershipSortField(property: .object(.updated))
      case "updated":
        return PubNub.MembershipSortField(property: .updated)
      default:
        return nil
      }
    }
  }
}

@objc
public extension PubNubObjC {
  @objc
  func getAllChannelMetadata(
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [PubNubSortPropertyObjC],
    includeCount: Bool,
    includeCustom: Bool,
    onSuccess: @escaping (([PubNubChannelMetadataObjC], NSNumber?, PubNubHashedPageObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.allChannelMetadata(
      include: PubNub.IncludeFields(custom: includeCustom, totalCount: includeCount),
      filter: filter,
      sort: objectSortProperties(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.channels.map { PubNubChannelMetadataObjC(metadata: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next) // TODO: Verify if it's ok for KMP
        )
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
  func setChannelMetadata(
    channel: String,
    name: String?,
    description: String?,
    custom: AnyJSONObjC?,
    includeCustom: Bool,
    type: String?,
    status: String?,
    onSuccess: @escaping ((PubNubChannelMetadataObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.set(
      channel: PubNubChannelMetadataBase(
        metadataId: channel,
        name: name,
        type: type,
        status: status,
        channelDescription: description,
        custom: (custom?.asMap())?.compactMapValues { $0 as? JSONCodableScalar } // TODO: Verify
      ),
      include: includeCustom
    ) {
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
    
  @objc
  func getAllUUIDMetadata(
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [PubNubSortPropertyObjC],
    includeCount: Bool,
    includeCustom: Bool,
    onSuccess: @escaping (([PubNubUUIDMetadataObjC], NSNumber?, PubNubHashedPageObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.allUUIDMetadata(
      include: PubNub.IncludeFields(custom: includeCustom, totalCount: includeCount),
      filter: filter,
      sort: objectSortProperties(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.uuids.map { PubNubUUIDMetadataObjC(metadata: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next) // TODO: Verify if it's ok for KMP
        )
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
    
  @objc
  func setUUIDMetadata(
    uuid: String?, // TODO: Why KMP requires nil here?
    name: String?,
    externalId: String?,
    profileUrl: String?,
    email: String?,
    custom: AnyJSONObjC?,
    includeCustom: Bool,
    type: String?,
    status: String?,
    onSuccess: @escaping ((PubNubUUIDMetadataObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.set(
      uuid: PubNubUUIDMetadataBase(
        metadataId: uuid!,
        name: name,
        type: type,
        status: status,
        externalId: externalId,
        profileURL: profileUrl,
        email: email,
        custom: (custom?.asMap())?.compactMapValues { $0 as? JSONCodableScalar } // TODO: Verify
      ),
      include: includeCustom
    ) {
      switch $0 {
      case .success(let metadata):
        onSuccess(PubNubUUIDMetadataObjC(metadata: metadata))
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func removeUUIDMetadata(
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
  func getMemberships(
    uuid: String?,
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [String],
    includeCount: Bool,
    includeCustom: Bool,
    includeChannelFields: Bool,
    includeChannelCustomFields: Bool,
    onSuccess: @escaping (([PubNubMembershipMetadataObjC], NSNumber?, PubNubHashedPageObjC?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetchMemberships(
      uuid: uuid,
      include: .init(
        customFields: includeCustom,
        channelFields: includeChannelFields,
        channelCustomFields: includeChannelCustomFields,
        totalCount: includeCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { PubNubMembershipMetadataObjC(from: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next) // TODO: Verify if it's ok for KMP
        )
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func setMemberships(
    channels: [PubNubChannelMetadataObjC],
    uuid: String?,
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [String],
    includeCount: Bool,
    includeCustom: Bool,
    includeChannelFields: Bool,
    includeChannelCustomFields: Bool,
    onSuccess: @escaping (([PubNubMembershipMetadataObjC], NSNumber?, PubNubHashedPageObjC?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.setMemberships(
      uuid: uuid,
      channels: channels.map {
        PubNubMembershipMetadataBase(
          uuidMetadataId: uuid!, // TODO: Verify it, perhaps this field will be ignored under the hood so we should put "" here
          channelMetadataId: $0.id
        )
      },
      include: .init(
        customFields: includeCustom,
        channelFields: includeChannelFields,
        channelCustomFields: includeChannelCustomFields,
        totalCount: includeCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { PubNubMembershipMetadataObjC(from: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next) // TODO: Verify if it's ok for KMP
        )
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func removeMemberships(
    channels: [String],
    uuid: String?,
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [String],
    includeCount: Bool,
    includeCustom: Bool,
    includeChannelFields: Bool,
    includeChannelCustomFields: Bool,
    onSuccess: @escaping (([PubNubMembershipMetadataObjC], NSNumber?, PubNubHashedPageObjC?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.removeMemberships(
      uuid: uuid,
      channels: channels.map {
        PubNubMembershipMetadataBase(
          uuidMetadataId: uuid!, // TODO: Verify it, perhaps this field will be ignored under the hood so we should put "" here
          channelMetadataId: $0
        )
      },
      include: .init(
        customFields: includeCustom,
        channelFields: includeChannelFields,
        channelCustomFields: includeChannelCustomFields,
        totalCount: includeCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { PubNubMembershipMetadataObjC(from: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next) // TODO: Verify if it's ok for KMP
        )
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func getChannelMembers(
    channel: String,
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [String],
    includeCount: Bool,
    includeCustom: Bool,
    includeUUIDFields: Bool,
    includeUUIDCustomFields: Bool,
    onSuccess: @escaping (([PubNubMembershipMetadataObjC], NSNumber?, PubNubHashedPageObjC?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.fetchMembers(
      channel: channel,
      include: .init(
        customFields: includeCustom,
        uuidFields: includeUUIDFields,
        uuidCustomFields: includeUUIDCustomFields,
        totalCount: includeCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort), 
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { PubNubMembershipMetadataObjC(from: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next) // TODO: Verify if it's ok for KMP
        )
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func setChannelMembers(
    channel: String,
    uuids: [PubNubUUIDMetadataObjC],
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [String],
    includeCount: Bool,
    includeCustom: Bool,
    includeUUIDFields: Bool,
    includeUUIDCustomFields: Bool,
    onSuccess: @escaping (([PubNubMembershipMetadataObjC], NSNumber?, PubNubHashedPageObjC?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.setMembers(
      channel: channel,
      uuids: uuids.map { PubNubMembershipMetadataBase(uuidMetadataId: $0.id, channelMetadataId: channel) },
      include: .init(
        customFields: includeCustom,
        uuidFields: includeUUIDFields,
        uuidCustomFields: includeUUIDCustomFields,
        totalCount: includeCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { PubNubMembershipMetadataObjC(from: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next) // TODO: Verify if it's ok for KMP
        )
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func removeChannelMembers(
    channel: String,
    uuids: [String],
    limit: NSNumber?,
    page: PubNubHashedPageObjC?,
    filter: String?,
    sort: [String],
    includeCount: Bool,
    includeCustom: Bool,
    includeUUIDFields: Bool,
    includeUUIDCustomFields: Bool,
    onSuccess: @escaping (([PubNubMembershipMetadataObjC], NSNumber?, PubNubHashedPageObjC?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.removeMembers(
      channel: channel,
      uuids: uuids.map { PubNubMembershipMetadataBase(uuidMetadataId: $0, channelMetadataId: channel) },
      include: .init(
        customFields: includeCustom,
        uuidFields: includeUUIDFields,
        uuidCustomFields: includeUUIDCustomFields,
        totalCount: includeCount
      ),
      filter: filter,
      sort: mapToMembershipSortFields(from: sort),
      limit: limit?.intValue,
      page: convertPage(from: page)
    ) {
      switch $0 {
      case .success(let res):
        onSuccess(
          res.memberships.map { PubNubMembershipMetadataObjC(from: $0) },
          res.next?.totalCount?.asNumber,
          PubNubHashedPageObjC(page: res.next) // TODO: Verify if it's ok for KMP
        )
      case .failure(let error):
        onFailure(error)
      }
    }
  }
}

// MARK: - Files

extension PubNubObjC {
  func convertUploadContent(from content: PubNubUploadableObjC) -> PubNub.FileUploadContent? {
    switch content {
    case let content as PubNubDataContentObjC:
      return .data(content.data, contentType: content.contentType)
    case let content as PubNubFileContentObjC:
      return .file(url: content.fileURL)
    case let content as PubNubInputStreamContentObjC:
      return .stream(content.stream, contentType: content.contentType, contentLength: content.contentLength)
    default:
      return nil
    }
  }
}

@objc
public extension PubNubObjC {
  @objc
  func listFiles(
    channel: String,
    limit: NSNumber?,
    next: PubNubHashedPageObjC?,
    onSuccess: @escaping (([PubNubFileObjC], String?) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.listFiles(
      channel: channel,
      limit: limit?.uintValue ?? 100,
      next: next?.end
    ) { [weak pubnub] in
      switch $0 {
      case .success(let res):
        onSuccess(res.files.map {
          PubNubFileObjC(
            from: $0,
            url: pubnub?.generateFileDownloadURL(for: $0)
          )
        }, next?.end)
        debugPrint("")
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func getFileUrl(
    channel: String,
    fileName: String,
    fileId: String,
    onSuccess: @escaping ((String) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    do {
      onSuccess(
        try pubnub.generateFileDownloadURL(
          channel: channel,
          fileId: fileId,
          filename: fileName
        ).absoluteString
      )
    } catch {
      onFailure(error)
    }
  }
  
  @objc
  func deleteFile(
    channel: String,
    fileName: String,
    fileId: String,
    onSuccess: @escaping (() -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    pubnub.remove(fileId: fileId, filename: fileName, channel: channel) {
      switch $0 {
      case .success(_):
        onSuccess()
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  // TODO: Missing contentType and fileSize
  
  @objc
  func publishFileMessage(
    channel: String,
    fileName: String,
    fileId: String,
    message: Any?,
    meta: Any?,
    ttl: NSNumber?,
    shouldStore: NSNumber?,
    onSuccess: @escaping ((Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    let messageCodable: AnyJSON? = if let message {
      AnyJSON(message)
    } else {
      nil
    }
    let metaCodable: AnyJSON? = if let meta {
      AnyJSON(meta)
    } else {
      nil
    }
    pubnub.publish(
      file: PubNubFileBase(
        channel: channel,
        fileId: fileId,
        filename: fileName,
        size: 0,
        contentType: nil
      ),
      request: PubNub.PublishFileRequest(
        additionalMessage: messageCodable,
        store: shouldStore?.boolValue,
        ttl: ttl?.intValue,
        meta: metaCodable
      )
    ) {
      switch $0 {
      case .success(let timetoken):
        onSuccess(timetoken)
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func downloadFile(
    channel: String,
    fileName: String,
    fileId: String,
    onSuccess: @escaping ((PubNubFileObjC) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    let fileBase = PubNubLocalFileBase(
      channel: channel,
      fileId: fileId,
      fileURL: defaultFileDownloadPath.appendingPathComponent(fileName)
    )
    pubnub.download(file: fileBase, toFileURL: fileBase.fileURL) {
      switch $0 {
      case .success(let res):
        onSuccess(PubNubFileObjC(from: res.file, url: res.file.fileURL))
      case .failure(let error):
        onFailure(error)
      }
    }
  }
  
  @objc
  func sendFile(
    channel: String,
    fileName: String,
    content: PubNubUploadableObjC,
    message: Any?,
    meta: Any?,
    ttl: NSNumber?,
    shouldStore: NSNumber?,
    onSuccess: @escaping ((PubNubFileObjC, Timetoken) -> Void),
    onFailure: @escaping ((Error) -> Void)
  ) {
    guard let fileContent = convertUploadContent(from: content) else {
      onFailure(PubNubError(.invalidArguments, additional: ["Cannot create expected PubNub.FileUploadContent"]))
      return
    }
    
    let additionalMessage: AnyJSON? = if let message { AnyJSON(message) } else { nil }
    let meta: AnyJSON? = if let meta { AnyJSON(meta) } else { nil }

    pubnub.send(
      fileContent,
      channel: channel,
      remoteFilename: fileName,
      publishRequest: PubNub.PublishFileRequest(
        additionalMessage: additionalMessage,
        store: shouldStore?.boolValue,
        ttl: ttl?.intValue,
        meta: meta
      )
    ) { [weak pubnub] in
      switch $0 {
      case .success(let res):
        onSuccess(
          PubNubFileObjC(from: res.file, url: pubnub?.generateFileDownloadURL(for: res.file)),
          res.publishedAt
        )
      case .failure(let error):
        onFailure(error)
      }
    }
  }
}

@objc
public extension PubNubObjC {
  @objc
  func disconnect() {
    pubnub.disconnect()
  }
}

// MARK: - Entities

@objc
public extension PubNubObjC {
  @objc
  func channel(with name: String) -> PubNubChannelEntityObjC {
    PubNubChannelEntityObjC(channel: pubnub.channel(name))
  }
  
  @objc
  func channelGroup(with name: String) -> PubNubChannelGroupEntityObjC {
    PubNubChannelGroupEntityObjC(channelGroup: pubnub.channelGroup(name))
  }
  
  @objc
  func userMetadata(with id: String) -> PubNubUserMetadataEntityObjC {
    PubNubUserMetadataEntityObjC(userMetadata: pubnub.userMetadata(id))
  }
  
  @objc
  func channelMetadata(with id: String) -> PubNubChannelMetadataEntityObjC {
    PubNubChannelMetadataEntityObjC(channelMetadata: pubnub.channelMetadata(id))
  }
}
