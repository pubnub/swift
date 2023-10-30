//
//  PubNubPushContractTestSteps.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Cucumberish
import Foundation
import PubNub

public class PubNubPushContractTestSteps: PubNubContractTestCase {
  override public func setup() {
    startCucumberHookEventsListening()

    When("^I list (.*) push channels(.*)?$") { args, _ in
      guard args?.count == 2, let pushService = args?.first, let topic = args?.last else {
        XCTAssert(false, "Step match failed")
        return
      }

      let listPushExpect = self.expectation(description: "List push channel registrations Response")
      let service = self.pushServiceFromWhen(match: pushService)
      let token = "my-token".data(using: .utf8)!

      if service == .apns, pushService == "APNS2" {
        let topic = topic.contains("with topic") ? "com.contract.test" : ""
        self.client.listAPNSPushChannelRegistrations(for: token, on: topic) { result in
          switch result {
          case let .success(channels):
            self.handleResult(result: channels)
          case let .failure(error):
            self.handleResult(result: error)
          }
          listPushExpect.fulfill()
        }
      } else {
        self.client.listPushChannelRegistrations(for: token, of: service) { result in
          switch result {
          case let .success(channels):
            self.handleResult(result: channels)
          case let .failure(error):
            self.handleResult(result: error)
          }
          listPushExpect.fulfill()
        }
      }

      self.wait(for: [listPushExpect], timeout: 60.0)
    }

    When("^I add (.*) push channels(.*)?$") { args, _ in
      guard args?.count == 2, let pushService = args?.first, let topic = args?.last else {
        XCTAssert(false, "Step match failed")
        return
      }

      let addPushExpect = self.expectation(description: "Add push channel registrations Response")
      let service = self.pushServiceFromWhen(match: pushService)
      let token = "my-token".data(using: .utf8)!
      let channels = ["channel1", "channel2"]

      if service == .apns, pushService == "APNS2" {
        let topic = topic.contains("with topic") ? "com.contract.test" : ""
        self.client.addAPNSDevicesOnChannels(channels, device: token, on: topic) { result in
          switch result {
          case let .success(channels):
            self.handleResult(result: channels)
          case let .failure(error):
            self.handleResult(result: error)
          }
          addPushExpect.fulfill()
        }
      } else {
        self.client.addPushChannelRegistrations(channels, for: token, of: service) { result in
          switch result {
          case let .success(channels):
            self.handleResult(result: channels)
          case let .failure(error):
            self.handleResult(result: error)
          }
          addPushExpect.fulfill()
        }
      }

      self.wait(for: [addPushExpect], timeout: 60.0)
    }

    When("^I remove (.*) push channels(.*)?$") { args, _ in
      guard args?.count == 2, let pushService = args?.first, let topic = args?.last else {
        XCTAssert(false, "Step match failed")
        return
      }

      let removePushExpect = self.expectation(description: "Remove push channel registrations Response")
      let service = self.pushServiceFromWhen(match: pushService)
      let token = "my-token".data(using: .utf8)!
      let channels = ["channel1", "channel2"]

      if service == .apns, pushService == "APNS2" {
        let topic = topic.contains("with topic") ? "com.contract.test" : ""
        self.client.removeAPNSDevicesOnChannels(channels, device: token, on: topic) { result in
          switch result {
          case let .success(channels):
            self.handleResult(result: channels)
          case let .failure(error):
            self.handleResult(result: error)
          }
          removePushExpect.fulfill()
        }
      } else {
        self.client.removePushChannelRegistrations(channels, for: token) { result in
          switch result {
          case let .success(channels):
            self.handleResult(result: channels)
          case let .failure(error):
            self.handleResult(result: error)
          }
          removePushExpect.fulfill()
        }
      }

      self.wait(for: [removePushExpect], timeout: 60.0)
    }

    When("^I remove (.*) device(.*)?$") { args, _ in
      guard args?.count == 2, let pushService = args?.first, let topic = args?.last else {
        XCTAssert(false, "Step match failed")
        return
      }

      let removeAllPushExpect = self.expectation(description: "Remove all push channel registrations Response")
      let service = self.pushServiceFromWhen(match: pushService)
      let token = "my-token".data(using: .utf8)!

      if service == .apns, pushService == "APNS2" {
        let topic = topic.contains("with topic") ? "com.contract.test" : ""
        self.client.removeAllAPNSPushDevice(for: token, on: topic) { result in
          switch result {
          case .success:
            self.handleResult(result: "Void")
          case let .failure(error):
            self.handleResult(result: error)
          }
          removeAllPushExpect.fulfill()
        }
      } else {
        self.client.removeAllPushChannelRegistrations(for: token) { result in
          switch result {
          case .success:
            self.handleResult(result: "Void")
          case let .failure(error):
            self.handleResult(result: error)
          }
          removeAllPushExpect.fulfill()
        }
      }

      self.wait(for: [removeAllPushExpect], timeout: 60.0)
    }
  }

  fileprivate func pushServiceFromWhen(match: String) -> PubNub.PushService {
    ["GCM", "FMC"].contains(match) ? .gcm : .apns
  }
}
