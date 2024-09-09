//
//  PubNubObjC+Listeners.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// All public symbols in this file that are annotated with @objc are intended to allow interoperation
/// with Kotlin Multiplatform for other PubNub frameworks.
///
/// While these symbols are public, they are intended strictly for internal usage.

/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

extension PubNubObjC {
  func createEventListener(from listener: PubNubEventListenerObjC) -> EventListener {
    EventListener(
      uuid: listener.uuid,
      onMessage: { listener.onMessage?(PubNubMessageObjC(message: $0)) },
      onSignal: { listener.onSignal?(PubNubMessageObjC(message: $0)) },
      onPresence: { listener.onPresence?(PubNubPresenceChangeObjC.from(change: $0)) },
      onMessageAction: { listener.onMessageAction?(PubNubMessageActionObjC(action: $0)) },
      onFileEvent: { [weak pubnub] in listener.onFile?(PubNubFileChangeEventObjC.from(event: $0, with: pubnub)) },
      onAppContext: { listener.onAppContext?(PubNubAppContextEventObjC.from(event: $0)) }
    )
  }

  // TODO: Missing case for .subscriptionChanged

  func createStatusListener(from listener: PubNubStatusListenerObjC) -> StatusListener {
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
  func addStatusListener(listener: PubNubStatusListenerObjC) {
    pubnub.addStatusListener(createStatusListener(from: listener))
  }

  func removeStatusListener(listener: PubNubStatusListenerObjC) {
    pubnub.removeStatusListener(with: listener.uuid)
  }

  func addEventListener(listener: PubNubEventListenerObjC) {
    pubnub.addEventListener(createEventListener(from: listener))
  }

  func removeEventListener(listener: PubNubEventListenerObjC) {
    pubnub.removeEventListener(with: listener.uuid)
  }

  func removeAllListeners() {
    pubnub.removeAllListeners()
  }
}
