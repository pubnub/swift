//
//  PubNubFilesContractTestSteps.swift
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

public class PubNubFilesContractTestSteps: PubNubContractTestCase {
  override public func setup() {
    startCucumberHookEventsListening()

    When("I list files") { _, _ in
      let listFilesExpect = self.expectation(description: "Files list Response")

      self.client.listFiles(channel: "test") { result in
        switch result {
        case let .success((files, next)):
          self.handleResult(result: (files, next))
        case let .failure(error):
          self.handleResult(result: error)
        }
        listFilesExpect.fulfill()
      }

      self.wait(for: [listFilesExpect], timeout: 60.0)
    }

    When("I publish file message") { _, _ in
      let publishFileMessageExpect = self.expectation(description: "Publish file message Response")

      var request = PubNub.PublishFileRequest()
      request.additionalMessage = "test-file"
      let file = PubNubFileBase(channel: "test", fileId: "identifier", filename: "name", size: 100, contentType: nil)
      self.client.publish(file: file, request: request) { result in
        switch result {
        case let .success(timetoken):
          self.handleResult(result: timetoken)
        case let .failure(error):
          self.handleResult(result: error)
        }
        publishFileMessageExpect.fulfill()
      }

      self.wait(for: [publishFileMessageExpect], timeout: 60.0)
    }

    When("I delete file") { _, _ in
      let removeFileExpect = self.expectation(description: "Remove file Response")

      self.client.remove(fileId: "identifier", filename: "name", channel: "test") { result in
        switch result {
        case let .success((channel, fileId)):
          self.handleResult(result: (channel, fileId))
        case let .failure(error):
          self.handleResult(result: error)
        }
        removeFileExpect.fulfill()
      }

      self.wait(for: [removeFileExpect], timeout: 60.0)
    }

    When("I download file") { _, _ in
      let downloadFileExpect = self.expectation(description: "Download file Response")

      let file = PubNubFileBase(channel: "test", fileId: "identifier", filename: "name.txt", size: 258, contentType: nil)
      self.client.download(file: file, toFileURL: Bundle.main.bundleURL) { result in
        switch result {
        case let .success((task, file)):
          self.handleResult(result: (task, file))
        case let .failure(error):
          self.handleResult(result: error)
        }
        downloadFileExpect.fulfill()
      }

      self.wait(for: [downloadFileExpect], timeout: 60.0)
    }

    When("I send file") { _, _ in
      let sendFileExpect = self.expectation(description: "Send file Response")

      guard let data = "test file data".data(using: .utf8) else {
        XCTAssert(false, "Unable prepare file data")
        return
      }

      self.client.send(.data(data, contentType: nil), channel: "test", remoteFilename: "name.txt") { result in
        switch result {
        case let .success(sendResults):
          self.handleResult(result: sendResults)
        case let .failure(error):
          self.handleResult(result: error)
        }
        sendFileExpect.fulfill()
      }

      self.wait(for: [sendFileExpect], timeout: 60.0)
    }
        
    When("^I send a file with '(.+)' space id and '(.+)' message type$") { args, _ in
      let spaceId = args?.first ?? String()
      let messageType = args?.last ?? String()
      
      let sendFileExpect = self.expectation(description: "Send file Response")

      guard let data = "test file data".data(using: .utf8) else {
        XCTAssert(false, "Unable prepare file data")
        return
      }
      
      self.client.fileURLSession = URLSession(
        configuration: .default,
        delegate: self.client.fileSessionManager,
        delegateQueue: .main
      )

      let publishFileRequest = PubNub.PublishFileRequest(
        messageType: .user(type: messageType),
        spaceId: PubNubSpaceId(spaceId)
      )
      
      self.client.send(.data(data, contentType: nil), channel: "test", remoteFilename: "name.txt", publishRequest: publishFileRequest) { result in
        switch result {
        case let .success(sendResults):
          self.handleResult(result: sendResults)
        case let .failure(error):
          self.handleResult(result: error)
        }
        sendFileExpect.fulfill()
      }

      self.wait(for: [sendFileExpect], timeout: 60.0)
    }
    
    When("^I send a file with '(.+)' space id and 'this-is-really-long-message-type-to-be-used-with-publish' message type$") { args, _ in
      let spaceId = args?.first ?? String()
      let messageType = "this-is-really-long-message-type-to-be-used-with-publish"
      
      let sendFileExpect = self.expectation(description: "Send file Response")

      guard let data = "test file data".data(using: .utf8) else {
        XCTAssert(false, "Unable prepare file data")
        return
      }
      
      self.client.fileURLSession = URLSession(
        configuration: .default,
        delegate: self.client.fileSessionManager,
        delegateQueue: .main
      )

      let publishFileRequest = PubNub.PublishFileRequest(
        messageType: .user(type: messageType),
        spaceId: PubNubSpaceId(spaceId)
      )
      
      self.client.send(.data(data, contentType: nil), channel: "test", remoteFilename: "name.txt", publishRequest: publishFileRequest) { result in
        switch result {
        case let .success(sendResults):
          self.handleResult(result: sendResults)
        case let .failure(error):
          self.handleResult(result: error)
        }
        sendFileExpect.fulfill()
      }

      self.wait(for: [sendFileExpect], timeout: 60.0)
    }
    
    When("^I send a file with '(.+)' space id and 'ts' message type$") { args, _ in
      let spaceId = args?.first ?? String()
      let messageType = "ts"
      
      let sendFileExpect = self.expectation(description: "Send file Response")

      guard let data = "test file data".data(using: .utf8) else {
        XCTAssert(false, "Unable prepare file data")
        return
      }
      
      self.client.fileURLSession = URLSession(
        configuration: .default,
        delegate: self.client.fileSessionManager,
        delegateQueue: .main
      )

      let publishFileRequest = PubNub.PublishFileRequest(
        messageType: .user(type: messageType),
        spaceId: PubNubSpaceId(spaceId)
      )
      
      self.client.send(.data(data, contentType: nil), channel: "test", remoteFilename: "name.txt", publishRequest: publishFileRequest) { result in
        switch result {
        case let .success(sendResults):
          self.handleResult(result: sendResults)
        case let .failure(error):
          self.handleResult(result: error)
        }
        sendFileExpect.fulfill()
      }

      self.wait(for: [sendFileExpect], timeout: 60.0)
    }    
  }
}
