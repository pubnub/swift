//
//  MessageCountsEndpointTests.swift
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

final class MessageCountsEndpointTests: XCTestCase {
  var pubnub: PubNub!
  let config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  let testChannel = "TestChannel"
  let testChannelList = ["TestChannel"]
  let testTimetoken: Timetoken = 1
  let testChannelTimetoken: [Timetoken] = [2]

  // MARK: - Message Counts

  func testMessageCounts_Endpoint() {
    let endpoint = Endpoint.messageCounts(channels: testChannelList,
                                          timetoken: testTimetoken,
                                          channelsTimetoken: testChannelTimetoken)

    XCTAssertEqual(endpoint.description, "Message Counts")
    XCTAssertEqual(endpoint.rawValue, .messageCounts)
    XCTAssertEqual(endpoint.operationCategory, .history)
    XCTAssertNil(endpoint.validationError)
  }

  func testMessageCounts_Endpoint_ValidationError() {
    let endpoint = Endpoint.messageCounts(channels: [], timetoken: nil, channelsTimetoken: [])

    XCTAssertNotEqual(endpoint.validationError?.pubNubError, PNError.invalidEndpointType(endpoint))
  }

  func testMessageCounts_Success() {
    let expectation = self.expectation(description: "Message Counts Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["message_counts_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .messageCounts(channels: testChannelList, timetoken: testTimetoken) { result in
        switch result {
        case let .success(channels):
          XCTAssertFalse(channels.isEmpty)
          let channelCounts = channels[self.testChannel]
          XCTAssertNotNil(channelCounts)
          XCTAssertEqual(channelCounts, 2)
        case let .failure(error):
          XCTFail("Message Counts request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testMessageCounts_Success_ChannelsDictionary() {
    let expectation = self.expectation(description: "Message Counts Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["message_counts_success"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .messageCounts(channels: Dictionary(zip(testChannelList, [testTimetoken])) { _, last in last }) { result in
        switch result {
        case let .success(channels):
          XCTAssertFalse(channels.isEmpty)
          let channelCounts = channels[self.testChannel]
          XCTAssertNotNil(channelCounts)
          XCTAssertEqual(channelCounts, 2)
        case let .failure(error):
          XCTFail("Message Counts request failed with error: \(error.localizedDescription)")
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testMessageCounts_Error_InvalidArguments() {
    let expectation = self.expectation(description: "Message Counts Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["message_counts_error_invalid_arguments"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .messageCounts(channels: testChannelList, timetoken: testTimetoken) { result in
        switch result {
        case .success:
          XCTFail("This should fail")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first else {
            return XCTFail("Could not get task")
          }

          let countExceededError = PNError.convert(endpoint: .unknown,
                                                   generalError: .init(message: .invalidArguments,
                                                                       service: .unknown(message: "Unknown"),
                                                                       status: .badRequest,
                                                                       error: true),
                                                   request: task.mockRequest,
                                                   response: task.mockResponse)

          XCTAssertEqual(error.pubNubError, countExceededError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }

  func testMessageCounts_Error_ServiceNotEnabled() {
    let expectation = self.expectation(description: "Message Counts Response Received")

    guard let sessions = try? MockURLSession.mockSession(for: ["message_counts_error_serviceNotEnabled"]) else {
      return XCTFail("Could not create mock url session")
    }

    PubNub(configuration: config, session: sessions.session)
      .messageCounts(channels: testChannelList, timetoken: testTimetoken) { result in
        switch result {
        case .success:
          XCTFail("This should fail")
        case let .failure(error):
          guard let task = sessions.mockSession.tasks.first else {
            return XCTFail("Could not get task")
          }

          let countExceededError = PNError.convert(endpoint: .unknown,
                                                   generalError: .init(message: .messageHistoryNotEnabled,
                                                                       service: .unknown(message: "Unknown"),
                                                                       status: .badRequest,
                                                                       error: true),
                                                   request: task.mockRequest,
                                                   response: task.mockResponse)

          XCTAssertEqual(error.pubNubError, countExceededError)
        }
        expectation.fulfill()
      }

    wait(for: [expectation], timeout: 1.0)
  }
}
