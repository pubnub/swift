//
//  EventListenerObjC.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@objc
public class EventListenerObjC: NSObject {
  @objc public var onMessage: ((PubNubMessageObjC) -> Void)?
  @objc public var onPresence: (([PubNubPresenceEventResultObjC]) -> Void)?
  @objc public var onSignal: ((PubNubMessageObjC) -> Void)?
  @objc public var onMessageAction: ((PubNubMessageActionObjC) -> Void)?
  @objc public var onAppContext: ((PubNubObjectEventResultObjC) -> Void)?
  @objc public var onFile: ((PubNubFileEventResultObjC) -> Void)?

  @objc public init(
    onMessage: ((PubNubMessageObjC) -> Void)?,
    onPresence: (([PubNubPresenceEventResultObjC]) -> Void)?,
    onSignal: ((PubNubMessageObjC) -> Void)?,
    onMessageAction: ((PubNubMessageActionObjC) -> Void)?,
    onAppContext: ((PubNubObjectEventResultObjC) -> Void)?,
    onFile: ((PubNubFileEventResultObjC) -> Void)?
  ) {
    self.onMessage = onMessage
    self.onPresence = onPresence
    self.onSignal = onSignal
    self.onMessageAction = onMessageAction
    self.onAppContext = onAppContext
    self.onFile = onFile
  }
}
