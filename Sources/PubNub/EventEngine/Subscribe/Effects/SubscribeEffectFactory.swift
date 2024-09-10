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
  private let presenceStateContainer: PubNubPresenceStateContainer

  init(
    session: SessionReplaceable,
    sessionResponseQueue: DispatchQueue = .main,
    messageCache: MessageCache = MessageCache(),
    presenceStateContainer: PubNubPresenceStateContainer
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
    case let .handshakeRequest(channels, groups):
      return HandshakeEffect(
        request: SubscribeRequest(
          configuration: dependencies.value.configuration,
          channels: channels,
          groups: groups,
          channelStates: presenceStateContainer.getStates(forChannels: channels),
          timetoken: 0,
          session: session,
          sessionResponseQueue: sessionResponseQueue
        ), listeners: dependencies.value.subscriptions
      )
    case let .receiveMessages(channels, groups, cursor):
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
        ), listeners: dependencies.value.subscriptions
      )
    case let .emitMessages(messages, cursor):
      return EmitMessagesEffect(
        messages: messages,
        cursor: cursor,
        subscriptions: dependencies.value.subscriptions,
        messageCache: messageCache
      )
    case let .emitStatus(statusChange):
      return EmitStatusEffect(
        statusChange: statusChange,
        subscriptions: dependencies.value.subscriptions
      )
    }
  }

  deinit {
    session.invalidateAndCancel()
  }
}
