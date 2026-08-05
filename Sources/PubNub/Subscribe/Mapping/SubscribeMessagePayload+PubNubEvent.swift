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
  // swiftlint:disable:next cyclomatic_complexity
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
      return .appContextChanged(objectAction.subscribeEvent)
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
        return .messageActionChanged(.added(messageAction))
      case .removed:
        return .messageActionChanged(.removed(messageAction))
      }
    case .file:
      guard let fileMessage = try? PubNubFileEventBase(from: self) else {
        return .messageReceived(PubNubMessageBase(from: self))
      }
      return .fileChanged(.uploaded(fileMessage))
    case .dataSync:
      guard let dataSyncEvent = asDataSyncEvent() else {
        return .messageReceived(PubNubMessageBase(from: self))
      }
      return .dataSyncChanged(dataSyncEvent)
    case .presence:
      guard let presence = PubNubPresenceChangeBase(from: self) else {
        return .messageReceived(PubNubMessageBase(from: self))
      }
      return .presenceChanged(presence)
    }
  }
}
