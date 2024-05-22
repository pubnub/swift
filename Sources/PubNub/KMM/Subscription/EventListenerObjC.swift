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
  @objc public var onPresence: ((Any) -> Void)?
  @objc public var onSignal: ((PubNubMessageObjC) -> Void)?
  @objc public var onMessageActionAdded: ((PubNubMessageActionObjC) -> Void)?
  @objc public var onMessageActionRemoved: ((PubNubMessageActionObjC) -> Void)?
  @objc public var onAppContext: ((Any) -> Void)?
  @objc public var onFile: ((Any) -> Void)?
  
  @objc public init(
    onMessage: ((PubNubMessageObjC) -> Void)?,
    onPresence: ((Any) -> Void)?,
    onSignal: ((PubNubMessageObjC) -> Void)?,
    onMessageActionAdded: ((PubNubMessageActionObjC) -> Void)?,
    onMessageActionRemoved: ((PubNubMessageActionObjC) -> Void)?,
    onAppContext: ((Any) -> Void)?,
    onFile: ((Any) -> Void)?
  ) {
    self.onMessage = onMessage
    self.onPresence = onPresence
    self.onSignal = onSignal
    self.onMessageActionAdded = onMessageActionAdded
    self.onMessageActionRemoved = onMessageActionRemoved
    self.onAppContext = onAppContext
    self.onFile = onFile
  }
}
