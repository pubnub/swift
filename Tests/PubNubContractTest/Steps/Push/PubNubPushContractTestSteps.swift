//
//  PubNubPushContractTestSteps.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2021 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Cucumberish
import PubNub


public class PubNubPushContractTestSteps: PubNubContractTestCase {
  public override func setup() {
    self.startCucumberHookEventsListening()
    
    When("^I list (.*) push channels(.*)?$") { args, _ in
      guard args?.count == 2, let pushService = args?.first, let topic = args?.last else {
        XCTAssert(false, "Step match failed")
        return
      }
      
      let listPushExpect = self.expectation(description: "List push channel registrations Response")
      let service = self.pushServiceFromWhen(match: pushService)
      let token = "my-token".data(using: .utf8)!
      
      
      if service == .apns && pushService == "APNS2" {
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
      
      if service == .apns && pushService == "APNS2" {
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
      
      if service == .apns && pushService == "APNS2" {
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
      
      if service == .apns && pushService == "APNS2" {
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
