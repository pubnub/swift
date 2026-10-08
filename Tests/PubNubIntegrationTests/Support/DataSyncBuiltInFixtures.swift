//
//  DataSyncBuiltInFixtures.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import PubNubSDK
import XCTest

// MARK: - Payloads

struct TestDataSyncUserPayload: JSONCodable, Equatable {
  let fullName: String?
  let email: String?
  let nickname: String?

  init(
    fullName: String? = nil,
    email: String? = nil,
    nickname: String? = nil
  ) {
    self.fullName = fullName
    self.email = email
    self.nickname = nickname
  }
}

struct TestDataSyncChannelPayload: JSONCodable, Equatable {
  let name: String?
  let description: String?

  init(
    name: String? = nil,
    description: String? = nil
  ) {
    self.name = name
    self.description = description
  }
}

struct TestDataSyncMembershipPayload: JSONCodable, Equatable {
  let role: String?
  let invitedBy: String?

  init(
    role: String? = nil,
    invitedBy: String? = nil
  ) {
    self.role = role
    self.invitedBy = invitedBy
  }
}

// MARK: - Setup and teardown

extension XCTestCase {
  func createDataSyncUsers(client: PubNub, ids: [String], classVersion: Int) {
    let setupExpect = expectation(description: "Create Test Users Expectation")
    setupExpect.expectedFulfillmentCount = 1
    setupExpect.assertForOverFulfill = true

    func createNext(_ remaining: [String]) {
      guard let id = remaining.first else {
        setupExpect.fulfill(); return
      }

      client.dataSync.createUser(
        classVersion: classVersion,
        id: id,
        status: "active",
        payload: TestDataSyncUserPayload(fullName: "Swift ITest User", email: "\(id)@example.com")
      ) { result in
        switch result {
        case .success:
          createNext(Array(remaining.dropFirst()))
        case let .failure(error):
          XCTFail("Failed to setup test user \(id): \(error)")
          setupExpect.fulfill()
        }
      }
    }

    createNext(ids)

    wait(for: [setupExpect], timeout: 20.0)
  }

  func createDataSyncChannels(client: PubNub, ids: [String], classVersion: Int) {
    let setupExpect = expectation(description: "Create Test Channels Expectation")
    setupExpect.expectedFulfillmentCount = 1
    setupExpect.assertForOverFulfill = true

    func createNext(_ remaining: [String]) {
      guard let id = remaining.first else {
        setupExpect.fulfill(); return
      }

      client.dataSync.createChannel(
        classVersion: classVersion,
        id: id,
        status: "active",
        payload: TestDataSyncChannelPayload(
          name: id,
          description: "Created by the Swift integration tests"
        )
      ) { result in
        switch result {
        case .success:
          createNext(Array(remaining.dropFirst()))
        case let .failure(error):
          XCTFail("Failed to setup test channel \(id): \(error)")
          setupExpect.fulfill()
        }
      }
    }

    createNext(ids)

    wait(for: [setupExpect], timeout: 20.0)
  }

  func removeDataSyncUsers(client: PubNub, ids: [String]) {
    for id in ids {
      let removeExpect = expectation(description: "Remove Test User \(id) Expectation")
      client.dataSync.removeUser(id: id) { _ in removeExpect.fulfill() }
      wait(for: [removeExpect], timeout: 10.0)
    }
  }

  func removeDataSyncChannels(client: PubNub, ids: [String]) {
    for id in ids {
      let removeExpect = expectation(description: "Remove Test Channel \(id) Expectation")
      client.dataSync.removeChannel(id: id) { _ in removeExpect.fulfill() }
      wait(for: [removeExpect], timeout: 10.0)
    }
  }

  func removeDataSyncMemberships(client: PubNub, ids: [String]) {
    for id in ids {
      let removeExpect = expectation(description: "Remove Test Membership \(id) Expectation")
      client.dataSync.removeMembership(id: id) { _ in removeExpect.fulfill() }
      wait(for: [removeExpect], timeout: 10.0)
    }
  }
}
