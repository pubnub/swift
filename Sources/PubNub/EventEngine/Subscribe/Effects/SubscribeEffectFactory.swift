//
//  SubscribeEffectFactory.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class SubscribeEffectFactory: EffectHandlerFactory {
  private let session: SessionReplaceable
  private let sessionResponseQueue: DispatchQueue
  private let messageCache: MessageCache
  private let presenceStateContainer: PresenceStateContainer
  
  init(
    session: SessionReplaceable,
    sessionResponseQueue: DispatchQueue = .global(qos: .default),
    messageCache: MessageCache = MessageCache(),
    presenceStateContainer: PresenceStateContainer
  ) {
    self.session = session
    self.sessionResponseQueue = sessionResponseQueue
    self.messageCache = messageCache
    self.presenceStateContainer = presenceStateContainer
  }
  
  func effect(
    for invocation: Subscribe.Invocation,
    with dependencies: EventEngineDependencies<Subscribe.Dependencies>
  ) -> any EffectHandler<Subscribe.Event> {
    switch invocation {
    case .handshakeRequest(let channels, let groups):
      return HandshakeEffect(
        request: SubscribeRequest(
          configuration: dependencies.value.configuration,
          channels: channels,
          groups: groups,
          channelStates: presenceStateContainer.getStates(forChannels: channels),
          timetoken: 0,
          session: session,
          sessionResponseQueue: sessionResponseQueue
        ), listeners: dependencies.value.listeners
      )
    case .handshakeReconnect(let channels, let groups, let retryAttempt, let reason):
      return HandshakeReconnectEffect(
        request: SubscribeRequest(
          configuration: dependencies.value.configuration,
          channels: channels,
          groups: groups,
          channelStates: presenceStateContainer.getStates(forChannels: channels),
          timetoken: 0,
          session: session,
          sessionResponseQueue: sessionResponseQueue
        ), listeners: dependencies.value.listeners,
        error: reason,
        retryAttempt: retryAttempt
      )
    case .receiveMessages(let channels, let groups, let cursor):
      return ReceivingEffect(
        request: SubscribeRequest(
          configuration: dependencies.value.configuration,
          channels: channels,
          groups: groups,
          channelStates: [:],
          timetoken: cursor.timetoken,
          region: cursor.region,
          session: session,
          sessionResponseQueue: sessionResponseQueue
        ), listeners: dependencies.value.listeners
      )
    case .receiveReconnect(let channels, let groups, let cursor, let retryAttempt, let reason):
      return ReceiveReconnectEffect(
        request: SubscribeRequest(
          configuration: dependencies.value.configuration,
          channels: channels,
          groups: groups,
          channelStates: [:],
          timetoken: cursor.timetoken,
          region: cursor.region,
          session: session,
          sessionResponseQueue: sessionResponseQueue
        ), listeners: dependencies.value.listeners,
        error: reason,
        retryAttempt: retryAttempt
      )
    case .emitMessages(let messages, let cursor):
      return EmitMessagesEffect(
        messages: messages,
        cursor: cursor,
        listeners: dependencies.value.listeners,
        messageCache: messageCache
      )
    case .emitStatus(let statusChange):
      return EmitStatusEffect(
        statusChange: statusChange,
        listeners: dependencies.value.listeners
      )
    }
  }
  
  deinit {
    session.invalidateAndCancel()
  }
}
