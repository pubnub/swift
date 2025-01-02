//
//  KMPAppContextIncludeFields.swift
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

@objc public class KMPAppContextIncludeFields: NSObject {
  @objc public let includeCustom: Bool
  @objc public let includeStatus: Bool
  @objc public let includeType: Bool
  @objc public let includeTotalCount: Bool

  @objc init(
    includeCustom: Bool = true,
    includeStatus: Bool = true,
    includeType: Bool = true,
    includeTotalCount: Bool = true
  ) {
    self.includeCustom = includeCustom
    self.includeStatus = includeStatus
    self.includeType = includeType
    self.includeTotalCount = includeTotalCount
  }
}

@objc public class KMPUserIncludeFields: KMPAppContextIncludeFields {
  override public init(
    includeCustom: Bool = true,
    includeStatus: Bool = true,
    includeType: Bool = true,
    includeTotalCount: Bool = true
  ) {
    super.init(
      includeCustom: includeCustom,
      includeStatus: includeStatus,
      includeType: includeType,
      includeTotalCount: includeTotalCount
    )
  }
}

@objc public class KMPChannelIncludeFields: KMPAppContextIncludeFields {
  override public init(
    includeCustom: Bool = true,
    includeStatus: Bool = true,
    includeType: Bool = true,
    includeTotalCount: Bool = true
  ) {
    super.init(
      includeCustom: includeCustom,
      includeStatus: includeStatus,
      includeType: includeType,
      includeTotalCount: includeTotalCount
    )
  }
}

@objc public class KMPMemberIncludeFields: KMPAppContextIncludeFields {
  @objc public let includeUser: Bool
  @objc public let includeUserCustom: Bool
  @objc public let includeUserType: Bool
  @objc public let includeUserStatus: Bool

  @objc
  public init(
    includeCustom: Bool = true,
    includeStatus: Bool = true,
    includeType: Bool = true,
    includeTotalCount: Bool = false,
    includeUser: Bool = false,
    includeUserCustom: Bool = false,
    includeUserType: Bool = false,
    includeUserStatus: Bool = false
  ) {
    self.includeUser = includeUser
    self.includeUserCustom = includeUserCustom
    self.includeUserType = includeUserType
    self.includeUserStatus = includeUserStatus

    super.init(
      includeCustom: includeCustom,
      includeStatus: includeStatus,
      includeType: includeType,
      includeTotalCount: includeTotalCount
    )
  }
}

@objc public class KMPMembershipIncludeFields: KMPAppContextIncludeFields {
  @objc public let includeChannel: Bool
  @objc public let includeChannelCustom: Bool
  @objc public let includeChannelType: Bool
  @objc public let includeChannelStatus: Bool

  @objc
  public init(
    includeCustom: Bool = true,
    includeStatus: Bool = true,
    includeType: Bool = true,
    includeTotalCount: Bool = false,
    includeChannel: Bool = false,
    includeChannelCustom: Bool = false,
    includeChannelType: Bool = false,
    includeChannelStatus: Bool = false
  ) {
    self.includeChannel = includeChannel
    self.includeChannelCustom = includeChannelCustom
    self.includeChannelType = includeChannelType
    self.includeChannelStatus = includeChannelStatus

    super.init(
      includeCustom: includeCustom,
      includeStatus: includeStatus,
      includeType: includeType,
      includeTotalCount: includeTotalCount
    )
  }
}
