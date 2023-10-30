//
//  SubscriptionSession+Presence.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

extension SubscriptionSession {
  // MARK: - Heartbeat Loop

  func registerHeartbeatTimer() {
    presenceTimer?.invalidate()

    if configuration.heartbeatInterval == 0 {
      return
    }

    let timer = Timer(fireAt: Date(timeIntervalSinceNow: Double(configuration.heartbeatInterval)),
                      interval: 0.0,
                      target: self,
                      selector: #selector(peformHeartbeatLoop),
                      userInfo: nil,
                      repeats: false)

    RunLoop.main.add(timer, forMode: .common)
    presenceTimer = timer
  }

  func stopHeartbeatTimer() {
    presenceTimer?.invalidate()
  }

  /// The amount of seconds until the next attempted presence heartbeat
  var nextPresenceHeartbeat: TimeInterval {
    return presenceTimer?.fireDate.timeIntervalSinceNow ?? 0.0
  }

  @objc func peformHeartbeatLoop() {
    // Get non-presence channels and groups
    let (channels, groups) = internalState.lockedRead { ($0.subscribedChannels, $0.subscribedGroups) }

    if channels.isEmpty, groups.isEmpty {
      return
    }

    // Perform Heartbeat
    let router = PresenceRouter(
      .heartbeat(channels: channels, groups: groups, presenceTimeout: configuration.durationUntilTimeout),
      configuration: configuration
    )

    nonSubscribeSession
      .request(with: router, requestOperator: configuration.automaticRetry)
      .validate()
      .response(on: .main, decoder: GenericServiceResponseDecoder()) { [weak self] result in
        switch result {
        case .success:
          // If the connection is active register a new heartbeat otherwise stop the timer
          self?.connectionStatus.isActive ?? false ? self?.registerHeartbeatTimer() : self?.stopHeartbeatTimer()
        case .failure:
          self?.stopHeartbeatTimer()
        }
      }

    // Get state
    registerHeartbeatTimer()
  }

  // MARK: - Leave

  public func presenceLeave(
    for _: String,
    on channels: [String],
    and groups: [String],
    completion: @escaping (Result<Bool, Error>) -> Void
  ) {
    let router = PresenceRouter(.leave(channels: channels, groups: groups), configuration: configuration)

    longPollingSession
      .request(with: router, requestOperator: configuration.automaticRetry)
      .validate()
      .response(on: .main, decoder: GenericServiceResponseDecoder()) { result in
        switch result {
        case .success:
          completion(.success(true))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
}
