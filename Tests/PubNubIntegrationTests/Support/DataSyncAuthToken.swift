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

/// The PAM v3 token authorizing the DataSync User, Channel, and Membership integration test suites.
/// Equivalent grant request body (as passed to grantToken):
///
/// ```
/// {
///   patterns: {
///     channels: {
///       '^swift-.*$': { get: true, create: true, update: true, delete: true }
///     },
///     'datasync:users': {
///       '^swift-.*$': { get: true, create: true, update: true, delete: true }
///     },
///     'datasync:memberships': {
///       '^swift-.*$': { get: true, create: true, update: true, delete: true }
///     }
///   }
/// }
/// ```
let dataSyncUserChannelMembershipAuthToken = "p0F2AkF0GmqCzKdDdHRsGajAQ3Jlc6VEY2hhbqBDZ3JwoENzcGOgQ3VzcqBEdXVpZKBDcGF0pkRjaGFuoWpec3dpZnQtLiokGHhDZ3JwoENzcGOgQ3VzcqFqXnN3aWZ0LS4qJBh4RHV1aWSgVGRhdGFzeW5jOm1lbWJlcnNoaXBzoWpec3dpZnQtLiokGHhEbWV0YaBDc2lnWCAPlONCh645cjHUecW0ruZf5EYQ8hbdkdpjSIhNSsXf9w=="

/// The PAM v3 token authorizing the DataSync healthcare Entity and Relationship integration test suites.
/// Equivalent grant request body (as passed to grantToken):
///
/// ```
/// {
///   patterns: {
///     'datasync:entities': {
///       '^swift-.*$': {
///         read: true, write: true, create: true, get: true, manage: true, update: true, join: true, delete: true
///       }
///     },
///     'datasync:relationships': {
///       '^swift-.*$': {
///         read: true, write: true, create: true, get: true,
///         manage: true, update: true, join: true, delete: true
///       }
///     }
///   },
///   meta: {
///     'pn-projections': {
///       pat: {
///         'datasync:entities:swift-.*': 'admin',
///         'datasync:relationships:swift-.*': 'admin'
///       }
///     }
///   }
/// }
/// ```
let dataSyncHealthcareAdminAuthToken = "p0F2AkF0GmqCyQdDdHRsGajAQ3Jlc6VEY2hhbqBDZ3JwoENzcGOgQ3VzcqBEdXVpZKBDcGF0p0RjaGFuoENncnCgQ3NwY6BDdXNyoER1dWlkoFFkYXRhc3luYzplbnRpdGllc6FqXnN3aWZ0LS4qJBj_VmRhdGFzeW5jOnJlbGF0aW9uc2hpcHOhal5zd2lmdC0uKiQY_0RtZXRhoW5wbi1wcm9qZWN0aW9uc6FjcGF0ongaZGF0YXN5bmM6ZW50aXRpZXM6c3dpZnQtLiplYWRtaW54H2RhdGFzeW5jOnJlbGF0aW9uc2hpcHM6c3dpZnQtLiplYWRtaW5Dc2lnWCD1hzu0zZ-Olj4SslxUBwYtX7s51hauk0xq9hJI-4E6Qg=="

/// The PAM v3 token authorizing the DataSync healthcare suites under the `__default__` projection.
/// Equivalent grant request body (as passed to grantToken):
///
/// ```
/// {
///   patterns: {
///     'datasync:entities': {
///       '^swift-.*$': {
///         read: true, write: true, create: true, get: true, manage: true, update: true, join: true, delete: true
///       }
///     },
///     'datasync:relationships': {
///       '^swift-.*$': {
///         read: true, write: true, create: true, get: true, manage: true, update: true, join: true, delete: true
///       }
///     }
///   }
/// }
/// ```
let dataSyncHealthcareDefaultAuthToken = "p0F2AkF0GmqCySJDdHRsGajAQ3Jlc6VEY2hhbqBDZ3JwoENzcGOgQ3VzcqBEdXVpZKBDcGF0p0RjaGFuoENncnCgQ3NwY6BDdXNyoER1dWlkoFFkYXRhc3luYzplbnRpdGllc6FqXnN3aWZ0LS4qJBj_VmRhdGFzeW5jOnJlbGF0aW9uc2hpcHOhal5zd2lmdC0uKiQY_0RtZXRhoENzaWdYIB2nLn9EuwKotjFJAFMvWTANtesIF4QLPhe-9252pNFd"

/// The PAM v3 token authorizing subscribing to the DataSync healthcare Entity and Relationship objects.
/// Equivalent grant request body (as passed to grantToken):
///
/// ```
/// {
///   patterns: {
///     channels: {
///       '^__admin__swift-.*$': { read: true }
///     }
///   }
/// }
/// ```
let dataSyncHealthcareSubscribeToken = "p0F2AkF0GmqCyTlDdHRsGajAQ3Jlc6VEY2hhbqBDZ3JwoENzcGOgQ3VzcqBEdXVpZKBDcGF0pURjaGFuoXNeX19hZG1pbl9fc3dpZnQtLiokAUNncnCgQ3NwY6BDdXNyoER1dWlkoERtZXRhoENzaWdYIFDDkt-XQ_oTTIqn0CLaeprdqBRjcm37yQyIqSvR7kxw"

// swiftlint:enable line_length
