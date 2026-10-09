//
//  PAMTokenTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

// swiftlint:disable line_length

class PAMTokenTests: XCTestCase {
  let config = PubNubConfiguration(
    publishKey: "",
    subscribeKey: "",
    userId: "tester"
  )

  static let allPermissionsToken = "qEF2AkF0GmEI03xDdHRsGDxDcmVzpURjaGFuoWljaGFubmVsLTEY70NncnChb2NoYW5uZWxfZ3JvdXAtMQVDdXNyoENzcGOgRHV1aWShZnV1aWQtMRhoQ3BhdKVEY2hhbqFtXmNoYW5uZWwtXFMqJBjvQ2dycKF0XjpjaGFubmVsX2dyb3VwLVxTKiQFQ3VzcqBDc3BjoER1dWlkoWpedXVpZC1cUyokGGhEbWV0YaBEdXVpZHR0ZXN0LWF1dGhvcml6ZWQtdXVpZENzaWdYIPpU-vCe9rkpYs87YUrFNWkyNq8CVvmKwEjVinnDrJJc"

  /// Token carrying DataSync resource categories and the `create` (bit 16) permission. Equivalent grant request body (as passed to grantToken):
  ///
  /// ```
  /// {
  ///   "ttl": 60,
  ///   "authorized_uuid": "test-authorized-uuid",
  ///   "resources": {
  ///     "channels": {
  ///       "channel-1": 239
  ///     },
  ///     "groups": {
  ///       "channel_group-1": 5
  ///     },
  ///     "uuids": {
  ///       "uuid-1": 104
  ///     },
  ///     "datasync:memberships": {
  ///       "membership-1": 255
  ///     }
  ///   },
  ///   "patterns": {
  ///     "channels": {
  ///       "^channel-\S*$": 239
  ///     },
  ///     "groups": {
  ///       "^:channel_group-\S*$": 5
  ///     },
  ///     "uuids": {
  ///       "^uuid-\S*$": 104
  ///     },
  ///     "datasync:entities": {
  ///       ".*": 255
  ///     },
  ///     "datasync:relationships": {
  ///       ".*": 19
  ///     }
  ///   },
  ///   "meta": {
  ///     "pn-projections": {
  ///       "pat": {
  ///         "datasync:entities:.*": "admin"
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  static let dataSyncToken = "qGF2AmF0GmEI03xjdHRsGDxjcmVzpGRjaGFuoWljaGFubmVsLTEY72NncnChb2NoYW5uZWxfZ3JvdXAtMQVkdXVpZKFmdXVpZC0xGGh0ZGF0YXN5bmM6bWVtYmVyc2hpcHOhbG1lbWJlcnNoaXAtMRj_Y3BhdKVkY2hhbqFtXmNoYW5uZWwtXFMqJBjvY2dycKF0XjpjaGFubmVsX2dyb3VwLVxTKiQFZHV1aWShal51dWlkLVxTKiQYaHFkYXRhc3luYzplbnRpdGllc6FiLioY_3ZkYXRhc3luYzpyZWxhdGlvbnNoaXBzoWIuKhNkbWV0YaFucG4tcHJvamVjdGlvbnOhY3BhdKF0ZGF0YXN5bmM6ZW50aXRpZXM6LiplYWRtaW5kdXVpZHR0ZXN0LWF1dGhvcml6ZWQtdXVpZGNzaWdE-lT68A=="

  /// Equivalent grant request body (as passed to grantToken):
  ///
  /// ```
  /// {
  ///   "ttl": 60,
  ///   "authorized_uuid": "ryan-carroll",
  ///   "resources": {
  ///     "datasync:entities": {
  ///       "vehicle.toyota-corolla-7f3a": 99
  ///     },
  ///     "datasync:relationships": {
  ///       "assignment.ryan-carroll": 33
  ///     }
  ///   },
  ///   "meta": {
  ///     "pn-projections": {
  ///       "res": {
  ///         "datasync:entities:vehicle.toyota-corolla-7f3a": "telemetry",
  ///         "datasync:relationships:assignment.ryan-carroll": "telemetry"
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  static let dataSyncCustomToken = "qGF2AmF0GmEI03xjdHRsGDxjcmVzonFkYXRhc3luYzplbnRpdGllc6F4G3ZlaGljbGUudG95b3RhLWNvcm9sbGEtN2YzYRhjdmRhdGFzeW5jOnJlbGF0aW9uc2hpcHOhd2Fzc2lnbm1lbnQucnlhbi1jYXJyb2xsGCFjcGF0oGRtZXRhoW5wbi1wcm9qZWN0aW9uc6FjcmVzongtZGF0YXN5bmM6ZW50aXRpZXM6dmVoaWNsZS50b3lvdGEtY29yb2xsYS03ZjNhaXRlbGVtZXRyeXguZGF0YXN5bmM6cmVsYXRpb25zaGlwczphc3NpZ25tZW50LnJ5YW4tY2Fycm9sbGl0ZWxlbWV0cnlkdXVpZGxyeWFuLWNhcnJvbGxjc2lnRPpU-vA="

  /// Token carrying both category permissions (the `cat` section) and ordinary resource and pattern
  /// permissions. Equivalent grant request body (as passed to grantToken):
  ///
  /// ```
  /// {
  ///   "ttl": 60,
  ///   "authorized_uuid": "test-authorized-uuid",
  ///   "resources": {
  ///     "channels": {
  ///       "channel-1": 32
  ///     },
  ///     "uuids": {
  ///       "uuid-1": 32
  ///     }
  ///   },
  ///   "patterns": {
  ///     "channels": {
  ///       "^channel-\S*$": 32
  ///     }
  ///   },
  ///   "categories": {
  ///     "channels": 32,
  ///     "uuids": 32
  ///   }
  /// }
  /// ```
  static let categoryToken = "qWF2AmF0GmEJDXxjdHRsGDxjcmVzomRjaGFuoWljaGFubmVsLTEYIGR1dWlkoWZ1dWlkLTEYIGNwYXShZGNoYW6hbV5jaGFubmVsLVxTKiQYIGNjYXSiZGNoYW4YIGR1dWlkGCBkbWV0YaBkdXVpZHR0ZXN0LWF1dGhvcml6ZWQtdXVpZGNzaWdE-lT68A=="

  /// Token carrying a single category permission and nothing else. Equivalent grant request body
  /// (as passed to grantToken):
  ///
  /// ```
  /// {
  ///   "ttl": 60,
  ///   "authorized_uuid": "test-authorized-uuid",
  ///   "categories": {
  ///     "uuids": 32
  ///   }
  /// }
  /// ```
  ///
  /// The `res`, `pat`, and `meta` sections are omitted from the CBOR entirely, and `cat` carries only one
  /// of the two categories. This fixture is deliberately minimal to pin down the tolerance of the decoder
  /// for absent sections, rather than to mirror the exact section set a token service emits today.
  static let categoryOnlyToken = "pmF2AmF0GmEJDXxjdHRsGDxjY2F0oWR1dWlkGCBkdXVpZHR0ZXN0LWF1dGhvcml6ZWQtdXVpZGNzaWdE-lT68A=="
}

// MARK: Scanner

extension PAMTokenTests {
  func test_ParseValidToken_ReturnsCorrectPermissions() throws {
    let pubnub = PubNub(configuration: config)
    let token = pubnub.parse(token: PAMTokenTests.allPermissionsToken)

    let resources = try XCTUnwrap(token?.resources)
    let patterns = try XCTUnwrap(token?.patterns)

    XCTAssertEqual(token?.authorizedUUID, "test-authorized-uuid")
    XCTAssertEqual(resources.channels.count, 1)
    XCTAssertEqual(resources.groups.count, 1)
    XCTAssertEqual(resources.uuids.count, 1)
    XCTAssertEqual(patterns.channels.count, 1)
    XCTAssertEqual(patterns.groups.count, 1)
    XCTAssertEqual(patterns.uuids.count, 1)

    XCTAssertEqual(resources.channels["channel-1"], [.read, .write, .manage, .delete, .get, .update, .join])
    XCTAssertEqual(resources.groups["channel_group-1"], [PAMPermission.read, PAMPermission.manage])
    XCTAssertEqual(resources.uuids["uuid-1"], [PAMPermission.delete, PAMPermission.get, PAMPermission.update])
    XCTAssertEqual(patterns.channels["^channel-\\S*$"], [.read, .write, .manage, .delete, .get, .update, .join])
    XCTAssertEqual(patterns.groups["^:channel_group-\\S*$"], [PAMPermission.read, PAMPermission.manage])
    XCTAssertEqual(patterns.uuids["^uuid-\\S*$"], [PAMPermission.delete, PAMPermission.get, PAMPermission.update])

    XCTAssertTrue(resources.dataSyncEntities.isEmpty)
    XCTAssertTrue(resources.dataSyncMemberships.isEmpty)
    XCTAssertTrue(resources.dataSyncRelationships.isEmpty)
    XCTAssertTrue(patterns.dataSyncEntities.isEmpty)
    XCTAssertTrue(patterns.dataSyncMemberships.isEmpty)
    XCTAssertTrue(patterns.dataSyncRelationships.isEmpty)

    XCTAssertEqual(token?.categories.channels, PAMPermission.none)
    XCTAssertEqual(token?.categories.uuids, PAMPermission.none)
  }

  func test_ParseDataSyncToken_ReturnsDataSyncPermissions() throws {
    let pubnub = PubNub(configuration: config)
    let token = pubnub.parse(token: PAMTokenTests.dataSyncToken)

    let resources = try XCTUnwrap(token?.resources)
    let patterns = try XCTUnwrap(token?.patterns)

    XCTAssertEqual(token?.authorizedUUID, "test-authorized-uuid")
    XCTAssertEqual(resources.dataSyncMemberships["membership-1"], PAMPermission.all)
    XCTAssertEqual(patterns.dataSyncEntities[".*"], PAMPermission.all)
    XCTAssertEqual(patterns.dataSyncRelationships[".*"], [PAMPermission.read, PAMPermission.write, PAMPermission.create])
  }

  func test_ParseCustomDataSyncToken_EntitiesRelationshipsAndProjections() throws {
    let pubnub = PubNub(configuration: config)
    let token = pubnub.parse(token: PAMTokenTests.dataSyncCustomToken)

    let resources = try XCTUnwrap(token?.resources)

    XCTAssertEqual(token?.authorizedUUID, "ryan-carroll")
    XCTAssertEqual(resources.dataSyncEntities["vehicle.toyota-corolla-7f3a"], [.read, .write, .get, .update])
    XCTAssertEqual(resources.dataSyncRelationships["assignment.ryan-carroll"], [.read, .get])

    let projections = try XCTUnwrap(token?.meta["pn-projections"])
    XCTAssertEqual(projections["res"]?.count, 2)
    XCTAssertEqual(projections["res"]?["datasync:entities:vehicle.toyota-corolla-7f3a"]?.stringOptional, "telemetry")
    XCTAssertEqual(projections["res"]?["datasync:relationships:assignment.ryan-carroll"]?.stringOptional, "telemetry")
  }

  func test_ParseCategoryToken_ReturnsCategoryAndResourcePermissions() throws {
    let pubnub = PubNub(configuration: config)
    let token = pubnub.parse(token: PAMTokenTests.categoryToken)

    let resources = try XCTUnwrap(token?.resources)
    let patterns = try XCTUnwrap(token?.patterns)
    let categories = try XCTUnwrap(token?.categories)

    XCTAssertEqual(token?.authorizedUUID, "test-authorized-uuid")
    XCTAssertEqual(categories.channels, PAMPermission.get)
    XCTAssertEqual(categories.uuids, PAMPermission.get)

    // A category permission is reported separately from the permissions on named resources and patterns
    XCTAssertEqual(resources.channels["channel-1"], PAMPermission.get)
    XCTAssertEqual(resources.uuids["uuid-1"], PAMPermission.get)
    XCTAssertEqual(patterns.channels["^channel-\\S*$"], PAMPermission.get)
  }

  func test_ParseCategoryOnlyToken_ParsesWithoutResourcesPatternsOrMeta() throws {
    let pubnub = PubNub(configuration: config)
    let token = try XCTUnwrap(pubnub.parse(token: PAMTokenTests.categoryOnlyToken))

    XCTAssertEqual(token.authorizedUUID, "test-authorized-uuid")
    XCTAssertEqual(token.categories.uuids, PAMPermission.get)
    XCTAssertEqual(token.categories.channels, PAMPermission.none)

    XCTAssertTrue(token.resources.channels.isEmpty)
    XCTAssertTrue(token.resources.groups.isEmpty)
    XCTAssertTrue(token.resources.uuids.isEmpty)
    XCTAssertTrue(token.patterns.channels.isEmpty)
    XCTAssertTrue(token.patterns.groups.isEmpty)
    XCTAssertTrue(token.patterns.uuids.isEmpty)
    XCTAssertTrue(token.meta.isEmpty)
  }

  func test_ParseTokenWithoutCategories_ReportsNoCategoryPermissions() throws {
    let pubnub = PubNub(configuration: config)
    let token = try XCTUnwrap(pubnub.parse(token: PAMTokenTests.dataSyncToken))

    XCTAssertEqual(token.categories.channels, PAMPermission.none)
    XCTAssertEqual(token.categories.uuids, PAMPermission.none)

    // The rest of the token is unaffected by the absent `cat` section
    XCTAssertEqual(token.authorizedUUID, "test-authorized-uuid")
    XCTAssertEqual(token.resources.dataSyncMemberships["membership-1"], PAMPermission.all)
    XCTAssertEqual(token.patterns.dataSyncEntities[".*"], PAMPermission.all)
  }

  func test_SetToken_UpdatesConfiguration() {
    let pubnub = PubNub(configuration: config)

    pubnub.set(token: "access-token")

    XCTAssertEqual(pubnub.configuration.authToken, "access-token")
    XCTAssertEqual(pubnub.subscription.configuration.authToken, "access-token")
  }

  func test_ChangeToken_UpdatesToNewValue() {
    let pubnub = PubNub(configuration: config)
    pubnub.set(token: "access-token")
    pubnub.set(token: "access-token-updated")

    XCTAssertEqual(pubnub.configuration.authToken, "access-token-updated")
    XCTAssertEqual(pubnub.subscription.configuration.authToken, "access-token-updated")
  }

  // swiftlint:enable line_length
}
