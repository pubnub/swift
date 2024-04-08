//
//  LeaveEffect.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

class LeaveEffect: EffectHandler {
  private let request: PresenceLeaveRequest

  init(request: PresenceLeaveRequest) {
    self.request = request
  }

  func performTask(completionBlock: @escaping ([Presence.Event]) -> Void) {
    request.execute { result in
      switch result {
      case .success:
        completionBlock([])
      case .failure:
        completionBlock([])
      }
    }
  }

  deinit {
    request.cancel()
  }
}
