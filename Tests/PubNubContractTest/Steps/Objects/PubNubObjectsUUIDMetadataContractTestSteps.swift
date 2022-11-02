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

public class PubNubObjectsUUIDMetadataContractTestSteps: PubNubContractTestCase {
  var setUserIdAsCurrentUser: Bool = false
  var uuidMetadata: PubNubUUIDMetadata?
  
  public override func handleAfterHook() {
    uuidMetadata = nil
    super.handleAfterHook()
  }
  
  override public var configuration: PubNubConfiguration {
    var config = super.configuration
    if setUserIdAsCurrentUser, let metadataId = uuidMetadata?.metadataId {
      config.userId = metadataId
    }
    return config
  }
  
  override public func setup() {
    startCucumberHookEventsListening()
    
    Given("I have a keyset with Objects V2 enabled") { _, _ in
      // Do noting, because client doesn't support token grant.
    }
    
    Given("^the id for '(.*)' persona$") { args, _ in
      let personaName = try XCTUnwrap(args?.first?.lowercased())
      guard let uuidMetadata = self.uuidMetadata(with: personaName) else {
        XCTAssert(false, "Persona file not parsed.")
        return
      }
      
      XCTAssertNotNil(uuidMetadata.metadataId)
      self.uuidMetadata = PubNubUUIDMetadataBase(metadataId: uuidMetadata.metadataId)
    }
    
    Given("^current user is '(.*)' persona$") { args, _ in
      let personaName = try XCTUnwrap(args?.first?.lowercased())
      guard let uuidMetadata = self.uuidMetadata(with: personaName) else {
        XCTAssert(false, "Persona file not parsed.")
        return
      }
      
      self.setUserIdAsCurrentUser = true
      self.uuidMetadata = uuidMetadata
    }
    
    Given("^the data for '(.*)' persona$") { args, _ in
      let personaName = try XCTUnwrap(args?.first?.lowercased())
      guard let uuidMetadata = self.uuidMetadata(with: personaName) else {
        XCTAssert(false, "Persona file not parsed.")
        return
      }
      
      self.uuidMetadata = uuidMetadata
    }
    
    When("^I get the UUID metadata(.*)$") { args, _ in
      let fetchUUIDMetadataExpect = self.expectation(description: "Fetch UUID metadata response")
      let uuid = self.setUserIdAsCurrentUser ? nil : self.uuidMetadata?.metadataId
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
        
        fetchUUIDMetadataExpect.fulfill()
      }
      
      self.wait(for: [fetchUUIDMetadataExpect], timeout: 60.0)
      
      let result = self.lastResult() as? PubNubUUIDMetadata
      XCTAssertNotNil(result, "Fetch UUID metadata didn't returned any response or it had unexpected format")
      
      if (includeCustom) {
        XCTAssertNotNil(result?.custom)
      }
    }
    
    When("I set the UUID metadata") { _, _ in
      let setUUIDExpect = self.expectation(description: "Set UUID metadata response")
      
      self.client.set(uuid: self.uuidMetadata!) { result in
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
      var metadataId = self.uuidMetadata?.metadataId
      
      if args?.count == 1, let flags = args?.first, flags.contains("current user") {
        metadataId = nil
      }
      
      let removeUUIDMetadataExpect = self.expectation(description: "Remove UUID metadata response")
      
      self.client.remove(uuid: metadataId) { result in
        switch result {
        case let .success(removedUUID):
          self.handleResult(result: removedUUID)
        case let .failure(error):
          self.handleResult(result: error)
        }
        
        removeUUIDMetadataExpect.fulfill()
      }
      
      self.wait(for: [removeUUIDMetadataExpect], timeout: 60.0)
      
      let result = self.lastResult() as? String
      XCTAssertNotNil(result, "Remove UUID metadata didn't returned any response or it had unexpected format")
      XCTAssertEqual(result, self.uuidMetadata?.metadataId)
    }
    
    When("^I get all UUID metadata(.*)$") { args, _ in
      let fetchAllUUIDMetadataExpect = self.expectation(description: "Fetch all UUID metadata response")
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
        
        fetchAllUUIDMetadataExpect.fulfill()
      }
      
      self.wait(for: [fetchAllUUIDMetadataExpect], timeout: 60.0)
    }
    
    Match(["And"], "^the UUID metadata for '(.*)' persona(.*)$") { args, _ in
      guard let result = self.lastResult() as? PubNubUUIDMetadata else { return }
      let uuidName = try XCTUnwrap(args?.first?.lowercased())
      guard let uuidMetadata = self.uuidMetadata(with: uuidName) else { return }
      
      XCTAssertEqual(result.metadataId, uuidMetadata.metadataId)
      XCTAssertEqual(result.name, uuidMetadata.name)
      XCTAssertEqual(result.type, uuidMetadata.type)
      XCTAssertEqual(result.status, uuidMetadata.status)
      XCTAssertEqual(result.externalId, uuidMetadata.externalId)
      XCTAssertEqual(result.profileURL, uuidMetadata.profileURL)
      XCTAssertEqual(result.email, uuidMetadata.email)
      XCTAssertEqual(result.updated, uuidMetadata.updated)
      XCTAssertEqual(result.eTag, uuidMetadata.eTag)
      
      if args?.count == 2, let flags = args?.last, flags.contains("contains updated") {
        XCTAssertNotNil(result.updated)
      }
    }
    
    Match(["And"], "^the response contains list with '(.*)' and '(.*)' UUID metadata$") { args, _ in
      let result = self.lastResult() as? ((uuids:[PubNubUUIDMetadata], next: PubNubHashedPage))
      XCTAssertNotNil(result, "Fetch all UUID metadata didn't returned any response or it had unexpected format")
      guard let receivedUUIDs = result?.uuids else { return }
      
      XCTAssertEqual(args?.count, 2, "Not all UUID names specified")
      XCTAssertEqual(receivedUUIDs.count, 2)
      
      var uuids: [PubNubUUIDMetadata] = []
      for userName in args ?? [] {
        guard let uuidMetadata = self.uuidMetadata(with: userName.lowercased()) else {
          XCTAssert(false, "Persona file not parsed.")
          return
        }
        
        uuids.append(uuidMetadata)
      }
      
      for uuidMetadata in uuids {
        XCTAssert(receivedUUIDs.map { $0.metadataId }.contains(uuidMetadata.metadataId),
                  "\(uuidMetadata.metadataId) is missing from received UUIDs list.")
      }
    }
  }
}
