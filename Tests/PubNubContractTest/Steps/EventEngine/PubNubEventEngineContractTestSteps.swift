//
//  PubNubEventEngineContractTestsSteps.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import Cucumberish

@testable import PubNub

class PubNubEventEngineContractTestsSteps: PubNubContractTestCase {
  func extractExpectedResults(from: [AnyHashable: Any]?) -> (events: [String], invocations: [String]) {
    let dataTable = from?["DataTable"] as? Array<Array<String>> ?? []
    let events = dataTable.compactMap { $0.first == "event" ? $0.last : nil }
    let invocations = dataTable.compactMap { $0.first == "invocation" ? $0.last : nil }
    
    return (events: events, invocations: invocations)
  }
}
