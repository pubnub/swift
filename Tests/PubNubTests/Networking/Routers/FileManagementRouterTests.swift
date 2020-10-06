//
//  FileManagementRouterTests.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
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

@testable import PubNub
import XCTest

final class FileManagementRouterTests: XCTestCase {
  let config = PubNubConfiguration(publishKey: "FakePub", subscribeKey: "FakeSub")

  let testChannel = "TestChannel"
  let testFilename = "TestFile"
}

// List Endpoint

extension FileManagementRouterTests {
  func test_List_Success_Empty() {
    let expectation = self.expectation(description: "List Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["file_list_success_empty"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .listFiles(channel: testChannel) { [weak self] result in
        switch result {
        case let .success((channel, files, next)):
          XCTAssertEqual(self?.testChannel, channel)
          XCTAssertTrue(files.isEmpty)
          XCTAssertNil(next)
        case let .failure(error):
          XCTFail("List failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }
}

// Send Endpoint

extension FileManagementRouterTests {
  func test_Send_Success_Empty() {
    let expectation = self.expectation(description: "Send Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["file_generateURL_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .send(channel: testChannel, filename: testFilename, fileURL: URL(fileURLWithPath: ".")) { result in
        switch result {
        case let .success(fileRequest):
          XCTAssertEqual(fileRequest.method, .post)
        case let .failure(error):
          XCTFail("Send failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }
}
