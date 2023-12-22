//
//  EffectInvocation+Equatable.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

@testable import PubNub

extension EffectInvocation: Equatable where Invocation: Equatable {
  public static func ==(lhs: EffectInvocation<Invocation>, rhs: EffectInvocation<Invocation>) -> Bool {
    switch (lhs, rhs) {
    case (let .managed(lhsInvocation), let .managed(rhsInvocation)):
      return lhsInvocation == rhsInvocation
    case (let .regular(lhsInvocation), let .regular(rhsInvocation)):
      return lhsInvocation == rhsInvocation
    case (let .cancel(lhsId), let .cancel(rhsId)):
      return lhsId.id == rhsId.id
    default:
      return false
    }
  }
}
