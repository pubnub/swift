//
//  DataSyncAPITestCase.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

class DataSyncAPITestCase: XCTestCase {
  let createdAt = Date.dataSyncTestDate(from: "2026-08-06T08:58:09.720323Z")
  let updatedAt = Date.dataSyncTestDate(from: "2026-08-06T08:58:10.329598Z")
  let expiresAt = Date.dataSyncTestDate(from: "2027-08-07T00:00:00Z")
}

extension DataSyncAPITestCase {
  func queryValue(_ session: MockURLSession, named name: String) throws -> String? {
    let request = try XCTUnwrap(session.tasks.first?.originalRequest)
    let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))

    return components.queryItems?.first { $0.name == name }?.value
  }

  func filterQueryValue(_ session: MockURLSession) throws -> String? {
    try queryValue(session, named: "filter")
  }

  func advancedFilterQueryValue(_ session: MockURLSession) throws -> String? {
    try queryValue(session, named: "filter_advanced")
  }

  func sortQueryValue(_ session: MockURLSession) throws -> String? {
    try queryValue(session, named: "sort")
  }
}

private extension Date {
  static func dataSyncTestDate(from string: String) -> Date? {
    try? Constant.jsonDecoder.decode(Date.self, from: Data("\"\(string)\"".utf8))
  }
}
