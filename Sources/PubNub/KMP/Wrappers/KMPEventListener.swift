//
//  PubNubEventListenerObjC.swift
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

@objc
public class KMPEventListener: NSObject {
  @objc public let uuid: UUID
  @objc public var onMessage: ((KMPMessage) -> Void)?
  @objc public var onPresence: (([KMPPresenceChange]) -> Void)?
  @objc public var onSignal: ((KMPMessage) -> Void)?
  @objc public var onMessageAction: ((KMPMessageAction) -> Void)?
  @objc public var onAppContext: ((KMPAppContextEventResult) -> Void)?
  @objc public var onFile: ((KMPFileChangeEvent) -> Void)?

  // Stores a reference to the Swift listener that acts as a proxy
  // and forwards all calls to this (KMPEventListener) instance
  weak var underlying: EventListener?

  @objc public init(
    onMessage: ((KMPMessage) -> Void)?,
    onPresence: (([KMPPresenceChange]) -> Void)?,
    onSignal: ((KMPMessage) -> Void)?,
    onMessageAction: ((KMPMessageAction) -> Void)?,
    onAppContext: ((KMPAppContextEventResult) -> Void)?,
    onFile: ((KMPFileChangeEvent) -> Void)?
  ) {
    self.uuid = UUID()
    self.onMessage = onMessage
    self.onPresence = onPresence
    self.onSignal = onSignal
    self.onMessageAction = onMessageAction
    self.onAppContext = onAppContext
    self.onFile = onFile
  }
}
