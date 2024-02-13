//
//  SubscribeMessagePayload+PubNubEvent.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

extension SubscribeMessagePayload {
  func asPubNubEvent() -> PubNubEvent {
    switch messageType {
    case .message:
      return .messageReceived(PubNubMessageBase(from: self))
    case .signal:
      return .signalReceived(PubNubMessageBase(from: self))
    case .object:
      guard let objectAction = try? payload.decode(SubscribeObjectMetadataPayload.self) else {
        return .messageReceived(PubNubMessageBase(from: self))
      }
      switch objectAction.subscribeEvent {
      case .channelMetadataRemoved(let metadataId):
        return .appContextEvent(.removedChannel(metadataId: metadataId))
      case .channelMetadataSet(let changes):
        return .appContextEvent(.setChannel(changes))
      case .uuidMetadataSet(let changes):
        return .appContextEvent(.setUUID(changes))
      case .uuidMetadataRemoved(let metadataId):
        return .appContextEvent(.removedUUID(metadataId: metadataId))
      case .membershipMetadataSet(let metadata):
        return .appContextEvent(.setMembership(metadata))
      case .membershipMetadataRemoved(let metadata):
        return .appContextEvent(.removedMembership(metadata))
      default:
        return .messageReceived(PubNubMessageBase(from: self))
      }
    case .messageAction:
      guard
        let messageAction = PubNubMessageActionBase(from: self),
        let actionEventString = payload[rawValue: "event"] as? String,
        let actionEvent = SubscribeMessageActionPayload.Action(rawValue: actionEventString)
      else {
        return .messageReceived(PubNubMessageBase(from: self))
      }
      switch actionEvent {
      case .added:
        return .messageActionEvent(.added(messageAction))
      case .removed:
        return .messageActionEvent(.removed(messageAction))
      }
    case .file:
      guard let fileMessage = try? PubNubFileEventBase(from: self) else {
        return .messageReceived(PubNubMessageBase(from: self))
      }
      return .fileUploadEvent(fileMessage)
    case .presence:
      guard let presence = PubNubPresenceChangeBase(from: self) else {
        return .messageReceived(PubNubMessageBase(from: self))
      }
      return .presenceChange(presence)
    }
  }
}
