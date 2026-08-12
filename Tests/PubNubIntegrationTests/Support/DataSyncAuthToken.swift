//
//  DataSyncAuthToken.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

// swiftlint:disable line_length

/// The PAM v3 token authorizing the DataSync User, Channel, and Membership integration test suites. Equivalent grant request body (as passed to grantToken):
///
/// ```
/// {
///   "ttl": 43200,
///   "patterns": {
///     "channels": {
///       ".*": 255
///     },
///     "uuids": {
///       ".*": 255
///     },
///     "datasync:entities": {
///       ".*": 255
///     },
///     "datasync:relationships": {
///       ".*": 255
///     },
///     "datasync:memberships": {
///       ".*": 255
///     }
///   }
/// }
/// ```
let dataSyncUserChannelMembershipAuthToken = "p0F2AkF0Gmp8N1VDdHRsGajAQ3Jlc6VEY2hhbqBDZ3JwoENzcGOgQ3VzcqBEdXVpZKBDcGF0qERjaGFuoWIuKhj_Q2dycKBDc3BjoEN1c3KhYi4qGP9EdXVpZKBRZGF0YXN5bmM6ZW50aXRpZXOhYi4qGP9WZGF0YXN5bmM6cmVsYXRpb25zaGlwc6FiLioY_1RkYXRhc3luYzptZW1iZXJzaGlwc6FiLioY_0RtZXRhoENzaWdYIK2uAVh-yNWWKvCHzwf9oNressAex_8Z14pn7uOW94tu"

// swiftlint:enable line_length
