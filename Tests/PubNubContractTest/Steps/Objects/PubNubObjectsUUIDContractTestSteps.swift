//
//  PubNubObjectsUUIDContractTestSteps.swift
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

import Cucumberish
import Foundation
import PubNub
import XCTest

import Foundation

public class PubNubObjectsUUIDContractTestSteps: PubNubContractTestCase {
  var channelMetadata: PubNubChannelMetadata?
  var setUUIDAsCurrentUser: Bool = false
  var uuidMetadata: PubNubUUIDMetadata?
  
  public override func handleAfterHook() {
    channelMetadata = nil
    uuidMetadata = nil
    super.handleAfterHook()
  }
  
  override public var configuration: PubNubConfiguration {
    var config = super.configuration
    if setUUIDAsCurrentUser, let userId = uuidMetadata?.metadataId {
      config.userId = userId
    }
    return config
  }
  
  override public func setup() {
    startCucumberHookEventsListening()
    
    Given("I have a keyset with Objects V2 enabled") { _, _ in
      // Do noting, because client doesn't support token grant.
    }
    
    Given("^the id for '(.*)' persona$") { args, _ in
      guard args?.count == 1, let personaName = args?.first?.lowercased() else {
        XCTAssert(false, "Persona name has been expected.")
        return
      }
      
      guard let uuid = self.uuidWithName(personaName) else {
        XCTAssert(false, "Persona file not parsed.")
        return
      }
      
      XCTAssertNotNil(uuid.metadataId)
      self.uuidMetadata = uuid
    }
    
    Given("^current user is '(.*)' persona$") { args, _ in
      guard args?.count == 1, let personaName = args?.first?.lowercased() else {
        XCTAssert(false, "Persona name has been expected.")
        return
      }
      
      guard let uuid = self.uuidWithName(personaName) else {
        XCTAssert(false, "Persona file not parsed.")
        return
      }
      
      XCTAssertNotNil(uuid.metadataId)
      self.setUUIDAsCurrentUser = true
      self.uuidMetadata = uuid
    }
    
    Given("^the data for '(.*)' persona$") { args, _ in
      guard args?.count == 1, let personaName = args?.first?.lowercased() else {
        XCTAssert(false, "Persona name has been expected.")
        return
      }
      
      guard let uuid = self.uuidWithName(personaName) else {
        XCTAssert(false, "Persona file not parsed.")
        return
      }
      
      XCTAssertNotNil(uuid.metadataId)
      self.uuidMetadata = uuid
    }
    
    When("^I get the UUID metadata(.*)$") { args, _ in
      let fetchUUIDExpect = self.expectation(description: "Fetch UUID metadata Response")
      let uuid = self.setUUIDAsCurrentUser ? nil : self.uuidMetadata?.metadataId
      var includeCustom = false
      
      if args?.count == 1, let flags = args?.first {
        includeCustom = flags.contains("with custom")
      }
      
      self.client.fetch(
        uuid: uuid,
        include: includeCustom
      ) { result in
        switch result {
        case let .success(metadata):
          self.handleResult(result: metadata)
        case let .failure(error):
          self.handleResult(result: error)
        }
        
        fetchUUIDExpect.fulfill()
      }
      
      self.wait(for: [fetchUUIDExpect], timeout: 60.0)
      
      let result = self.lastResult() as? PubNubUUIDMetadata
      XCTAssertNotNil(result, "Fetch UUID metadata didn't returned any response or it had unexpected format")
      
      if (includeCustom) {
        XCTAssertNotNil(result?.custom)
      }
    }
    
    When("I set the UUID metadata") { _, _ in
      guard let uuid = try? PubNubUUIDMetadataBase(from: self.uuidMetadata!) else {
        XCTAssert(false, "Unable prepare UUID metadata model.")
        return
      }
      
      let setUUIDExpect = self.expectation(description: "Set UUID metadata Response")
      
      self.client.set(uuid: uuid) { result in
        switch result {
        case let .success(metadata):
          self.handleResult(result: metadata)
        case let .failure(error):
          self.handleResult(result: error)
        }
        setUUIDExpect.fulfill()
      }
      
      self.wait(for: [setUUIDExpect], timeout: 60.0)
      
      let result = self.lastResult() as? PubNubUUIDMetadata
      XCTAssertNotNil(result, "Set UUID metadata didn't returned any response or it had unexpected format")
    }
    
    When("^I remove the UUID metadata(.*)$") { args, _ in
      var uuid = self.uuidMetadata?.metadataId
      
      if args?.count == 1, let flags = args?.first, flags.contains("current user") {
        uuid = nil
      }
      
      let removeUUIDExpect = self.expectation(description: "Remove UUID metadata Response")
      
      self.client.remove(uuid: uuid) { result in
        switch result {
        case let .success(userId):
          self.handleResult(result: userId)
        case let .failure(error):
          self.handleResult(result: error)
        }
        
        removeUUIDExpect.fulfill()
      }
      
      self.wait(for: [removeUUIDExpect], timeout: 60.0)
      
      let result = self.lastResult() as? String
      XCTAssertNotNil(result, "Remove UUID metadata didn't returned any response or it had unexpected format")
      XCTAssertEqual(result, self.uuidMetadata?.metadataId)
    }
    
    When("^I get all UUID metadata(.*)$") { args, _ in
      let fetchAllUUIDExpect = self.expectation(description: "Fetch all UUID metadata Response")
      var includeCustom = PubNub.IncludeFields(custom: false, totalCount: false)
      
      if args?.count == 1, let flags = args?.first {
        includeCustom = PubNub.IncludeFields(custom: flags.contains("with custom"), totalCount: false)
      }
      
      self.client.allUUIDMetadata(include: includeCustom) { result in
        switch result {
        case let .success(metadata):
          for uuidMetadata in metadata.uuids {
            XCTAssert(
              includeCustom.customFields && uuidMetadata.custom != nil
              || !includeCustom.customFields && uuidMetadata.custom == nil,
              "\(uuidMetadata.custom != nil ? "Missing" : "Unexpected") custom data for \(uuidMetadata.metadataId) persona.")
          }
          
          self.handleResult(result: metadata)
        case let .failure(error):
          self.handleResult(result: error)
        }
        
        fetchAllUUIDExpect.fulfill()
      }
      
      self.wait(for: [fetchAllUUIDExpect], timeout: 60.0)
    }
    
    Match(["And"], "^the UUID metadata for '(.*)' persona(.*)$") { args, _ in
      guard let result = self.lastResult() as? PubNubUUIDMetadata else { return }
      XCTAssertEqual(result.metadataId, self.uuidMetadata?.metadataId)
      XCTAssertEqual(result.name, self.uuidMetadata?.name)
      XCTAssertEqual(result.type, self.uuidMetadata?.type)
      XCTAssertEqual(result.status, self.uuidMetadata?.status)
      XCTAssertEqual(result.externalId, self.uuidMetadata?.externalId)
      XCTAssertEqual(result.profileURL, self.uuidMetadata?.profileURL)
      XCTAssertEqual(result.email, self.uuidMetadata?.email)
      XCTAssertEqual(result.updated, self.uuidMetadata?.updated)
      XCTAssertEqual(result.eTag, self.uuidMetadata?.eTag)
      
      if args?.count == 2, let flags = args?.last, flags.contains("contains updated") {
        XCTAssertNotNil(result.updated)
      }
    }
    
    Match(["And"], "^the response contains list with '(.*)' and '(.*)' UUID metadata$") { args, _ in
      let result = self.lastResult() as? ((uuids:[PubNubUUIDMetadata], next: PubNubHashedPage))
      XCTAssertNotNil(result, "Fetch all UUID metadata didn't returned any response or it had unexpected format")
      guard let uuids = result?.uuids else { return }
      
      XCTAssertEqual(args?.count, 2, "Not all UUID names specified")
      XCTAssertEqual(uuids.count, 2)
      
      for userName in args ?? [] {
        XCTAssert(uuids.map { $0.name }.contains(userName), "\(userName) is missing from received UUIDs list.")
      }
    }
  }
}
