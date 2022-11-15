//
//  PubNubObjectsSpaceContractTestSteps.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
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

public class PubNubObjectsChannelMetadataContractTestSteps: PubNubObjectsContractTests {
  public override func setup() {
    startCucumberHookEventsListening()
    
    When("^I get the channel metadata(.*)$") { args, _ in
      let fetchChannelMetadataExpect = self.expectation(description: "Fetch channel metadata response")
      var includeCustom = false
      
      let channelMetadata = self.channelsMetadata.compactMap { $1 }.first
      guard let channelMetadataId = channelMetadata?.metadataId else {
        XCTAssert(false, "Channel metadata ID unknown.")
        return
      }

      if args?.count == 1, let flags = args?.first {
        includeCustom = flags.contains("with custom")
      }
      
      self.client.fetch(
        channel: channelMetadataId,
        include: includeCustom
      ) { result in
        switch result {
        case let .success(metadata):
          self.handleResult(result: metadata)
        case let .failure(error):
          self.handleResult(result: error)
        }

        fetchChannelMetadataExpect.fulfill()
      }

      self.wait(for: [fetchChannelMetadataExpect], timeout: 60.0)

      let result = self.lastResult() as? PubNubChannelMetadata
      XCTAssertNotNil(result, "Fetch channel metadata didn't returned any response or it had unexpected format")

      if (includeCustom) {
        XCTAssertNotNil(result?.custom)
      }
    }
    
    When("I set the channel metadata") { _, _ in
      let setChannelMetadataExpect = self.expectation(description: "Set channel metadata Response")
      let channelMetadata = self.channelsMetadata.compactMap { $1 }.first

      self.client.set(channel: channelMetadata!) { result in
        switch result {
        case let .success(metadata):
          self.handleResult(result: metadata)
        case let .failure(error):
          self.handleResult(result: error)
        }

        setChannelMetadataExpect.fulfill()
      }

      self.wait(for: [setChannelMetadataExpect], timeout: 60.0)

      let result = self.lastResult() as? PubNubChannelMetadata
      XCTAssertNotNil(result, "Set channel metadata didn't returned any response or it had unexpected format")
    }
    
    When("I remove the channel metadata") { _, _ in
      let removeChannelMetadataExpect = self.expectation(description: "Remove channel metadata response")
      
      let channelMetadata = self.channelsMetadata.compactMap { $1 }.first
      guard let channelMetadataId = channelMetadata?.metadataId else  {
        XCTAssert(false, "Channel metadata ID unknown.")
        return
      }

      self.client.remove(channel: channelMetadataId) { result in
        switch result {
        case let .success(removedChannelMetadataId):
          self.handleResult(result: removedChannelMetadataId)
        case let .failure(error):
          self.handleResult(result: error)
        }

        removeChannelMetadataExpect.fulfill()
      }

      self.wait(for: [removeChannelMetadataExpect], timeout: 60.0)

      let result = self.lastResult() as? String
      XCTAssertNotNil(result, "Remove channel metadata didn't returned any response or it had unexpected format")
      XCTAssertEqual(result, channelMetadata?.metadataId)
    }
    
    When("^I get all channel metadata(.*)$") { args, _ in
      let fetchAllChannelMetadataExpect = self.expectation(description: "Fetch all channel metadata response")
      var includeCustom = PubNub.IncludeFields(custom: false, totalCount: false)
      
      if args?.count == 1, let flags = args?.first {
        includeCustom = PubNub.IncludeFields(custom: flags.contains("with custom"), totalCount: false)
      }
      
      self.client.allChannelMetadata(include: includeCustom) { result in
        switch result {
        case let .success(metadata):
          for spaceMetadata in metadata.channels {
            XCTAssert(
              includeCustom.customFields && spaceMetadata.custom != nil
              || !includeCustom.customFields && spaceMetadata.custom == nil,
              "\(spaceMetadata.custom != nil ? "Missing" : "Unexpected") custom data for \(spaceMetadata.metadataId) channel.")
          }
          
          self.handleResult(result: metadata)
        case let .failure(error):
          self.handleResult(result: error)
        }
        
        fetchAllChannelMetadataExpect.fulfill()
      }
      
      self.wait(for: [fetchAllChannelMetadataExpect], timeout: 60.0)
    }
    
    Match(["And"], "^the channel metadata for '(.*)' channel(.*)$") { args, _ in
      guard let result = self.lastResult() as? PubNubChannelMetadata else { return }
      guard let channelName = args?.first?.lowercased() else { return }
      guard let channelMetadata = self.channelMetadata(with: channelName) else { return }
      
      XCTAssertEqual(result.metadataId, channelMetadata.metadataId)
      XCTAssertEqual(result.name, channelMetadata.name)
      XCTAssertEqual(result.type, channelMetadata.type)
      XCTAssertEqual(result.status, channelMetadata.status)
      XCTAssertEqual(result.channelDescription, channelMetadata.channelDescription)
      XCTAssertEqual(result.updated, channelMetadata.updated)
      XCTAssertEqual(result.eTag, channelMetadata.eTag)
      
      if args?.count == 2, let flags = args?.last, flags.contains("contains updated") {
        XCTAssertNotNil(result.updated)
      }
    }
    
    Match(["And"], "^the response contains list with '(.*)' and '(.*)' channel metadata$") { args, _ in
      let result = self.lastResult() as? ((channels:[PubNubChannelMetadata], next: PubNubHashedPage))
      XCTAssertNotNil(result, "Fetch all channel metadata didn't returned any response or it had unexpected format")
      guard let receivedChannels = result?.channels else { return }
      
      XCTAssertEqual(args?.count, 2, "Not all channel names specified")
      XCTAssertEqual(receivedChannels.count, 2)
      
      var channels: [PubNubChannelMetadata] = []
      for channelName in args ?? [] {
        guard let channelMetadata = self.channelMetadata(with: channelName.lowercased()) else {
          XCTAssert(false, "Channel file not parsed.")
          return
        }
        
        channels.append(channelMetadata)
      }
      
      for channelMetadata in channels {
        XCTAssert(receivedChannels.map { $0.metadataId }.contains(channelMetadata.metadataId),
                  "\(channelMetadata.metadataId) is missing from received channels list.")
      }
    }
  }
}
