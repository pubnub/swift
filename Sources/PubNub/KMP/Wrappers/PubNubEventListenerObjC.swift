//
//  PubNubEventListenerObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

/// IMPORTANT NOTE FOR DEVELOPERS USING THIS SDK
///
/// All public symbols in this file that are annotated with @objc are intended to allow interoperation
/// with Kotlin Multiplatform for other PubNub frameworks.
///
/// While these symbols are public, they are intended strictly for internal usage.

/// External developers should refrain from directly using these symbols in their code, as their implementation details
/// may change in future versions of the framework, potentially leading to breaking changes.

@objc
public class PubNubEventListenerObjC: NSObject {
  @objc public let uuid: UUID
  @objc public var onMessage: ((PubNubMessageObjC) -> Void)?
  @objc public var onPresence: (([PubNubPresenceChangeObjC]) -> Void)?
  @objc public var onSignal: ((PubNubMessageObjC) -> Void)?
  @objc public var onMessageAction: ((PubNubMessageActionObjC) -> Void)?
  @objc public var onAppContext: ((PubNubAppContextEventObjC) -> Void)?
  @objc public var onFile: ((PubNubFileChangeEventObjC) -> Void)?

  @objc public init(
    onMessage: ((PubNubMessageObjC) -> Void)?,
    onPresence: (([PubNubPresenceChangeObjC]) -> Void)?,
    onSignal: ((PubNubMessageObjC) -> Void)?,
    onMessageAction: ((PubNubMessageActionObjC) -> Void)?,
    onAppContext: ((PubNubAppContextEventObjC) -> Void)?,
    onFile: ((PubNubFileChangeEventObjC) -> Void)?
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
