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

/// The PAM v3 token authorizing the DataSync User, Channel, and Membership integration test suites. Equivalent grant request body (as passed to grantToken):
///
/// ```
/// {
///   "patterns": {
///     "users": {
///       "swift-*": {
///         "read": true,
///         "write": true,
///         "manage": true,
///         "delete": true,
///         "create": true,
///         "get": true,
///         "update": true,
///         "join": true
///       }
///     },
///     "channels": {
///       "swift-*": {
///         "read": true,
///         "write": true,
///         "manage": true,
///         "delete": true,
///         "create": true,
///         "get": true,
///         "update": true,
///         "join": true
///       }
///     },
///     "datasync:memberships": {
///       "swift-.*": {
///         "read": true,
///         "write": true,
///         "manage": true,
///         "delete": true,
///         "create": true,
///         "get": true,
///         "update": true,
///         "join": true
///       }
///     }
///   }
/// }
/// ```
let dataSyncUserChannelMembershipAuthToken = ""
