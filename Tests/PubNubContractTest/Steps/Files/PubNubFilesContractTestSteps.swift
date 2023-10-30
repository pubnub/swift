//
//  PubNubFilesContractTestSteps.swift
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
  }
}
