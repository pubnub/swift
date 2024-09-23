//
//  KMPPubNub+Listeners.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//
// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
//
// All public symbols in this file are intended to allow interoperation with Kotlin Multiplatform for other PubNub frameworks.
// While these symbols are public, they are intended strictly for internal usage.
//
// External developers should refrain from directly using these symbols in their code, as their implementation details
// may change in future versions of the framework, potentially leading to breaking changes.

import Foundation

extension KMPPubNub {
  func createEventListener(from listener: KMPEventListener) -> EventListener {
    let swiftListener = EventListener(
      uuid: listener.uuid,
      onMessage: { listener.onMessage?(KMPMessage(message: $0)) },
      onSignal: { listener.onSignal?(KMPMessage(message: $0)) },
      onPresence: { listener.onPresence?(KMPPresenceChange.from(change: $0)) },
      onMessageAction: { listener.onMessageAction?(KMPMessageAction(action: $0)) },
      onFileEvent: { [weak pubnub] in listener.onFile?(KMPFileChangeEvent.from(event: $0, with: pubnub)) },
      onAppContext: { listener.onAppContext?(KMPAppContextEventResult.from(event: $0)) }
    )

    // Establishes an association to infer which Swift listener
    // corresponds to which KMP listener
    listener.underlying = swiftListener

    return swiftListener
  }

  func createStatusListener(from listener: KMPStatusListener) -> StatusListener {
    let swiftStatusListener = StatusListener(onConnectionStateChange: { [weak pubnub] newStatus in
      guard let pubnub = pubnub else {
        return
      }

      let category: KMPConnectionStatusCategory
      let errorIfAny: Error?

      var affectedChannels: [String] = pubnub.subscribedChannels
      var affectedGroups: [String] = pubnub.subscribedChannelGroups

      switch newStatus {
      case .connected:
        category = .connected
        errorIfAny = nil
      case .disconnected:
        category = .disconnected
        errorIfAny = nil
      case let .disconnectedUnexpectedly(error):
        category = .disconnectedUnexpectedly
        errorIfAny = error
      case let .subscriptionChanged(channels, groups):
        category = .subscriptionChanged
        errorIfAny = nil
        affectedChannels = channels
        affectedGroups = groups
      case let .connectionError(error):
        category = .connectionError
        errorIfAny = error
      }

      listener.onStatusChange?(
        KMPConnectionStatus(
          category: category,
          error: errorIfAny,
          currentTimetoken: NSNumber(value: pubnub.previousTimetoken ?? 0),
          affectedChannels: Set(affectedChannels),
          affectedChannelGroups: Set(affectedGroups)
        )
      )
    })

    // Establishes an association to infer which Swift listener
    // corresponds to which KMP listener
    listener.underlying = swiftStatusListener

    return swiftStatusListener
  }
}

@objc
public extension KMPPubNub {
  func addStatusListener(listener: KMPStatusListener) {
    pubnub.addStatusListener(createStatusListener(from: listener))
  }

  func removeStatusListener(listener: KMPStatusListener) {
    if let underlying = listener.underlying {
      pubnub.removeStatusListener(underlying)
    }
  }

  func addEventListener(listener: KMPEventListener) {
    pubnub.addEventListener(createEventListener(from: listener))
  }

  func removeEventListener(listener: KMPEventListener) {
    if let underlying = listener.underlying {
      pubnub.removeEventListener(underlying)
    }
  }

  func removeAllListeners() {
    pubnub.removeAllListeners()
  }
}
