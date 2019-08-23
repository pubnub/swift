//
//  InstanceIdOperatorTests.swift
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

class InstanceIdOperatorTests: XCTestCase {
  var pubnub: PubNub!
  var config = PubNubConfiguration(publishKey: "FakeTestString", subscribeKey: "FakeTestString")

  func testUseInstanceID_Success() {
    var expectations = [XCTestExpectation]()

    let sessionListener = SessionListener(queue: DispatchQueue(label: "Session Listener",
                                                               qos: .userInitiated,
                                                               attributes: .concurrent))

    guard let sessions = try? MockURLSession.mockSession(for: ["time_success"],
                                                         with: sessionListener) else {
      return XCTFail("Could not create mock url session")
    }

    let sessionExpector = SessionExpector(session: sessionListener)
    sessionExpector.expectDidMutateRequest { _, initialURLRequest, mutatedURLRequest in
      guard let mutatedURL = mutatedURLRequest.url, let initialURL = initialURLRequest.url else {
        return XCTFail("Could not create URL during request mutation")
      }

      XCTAssertFalse(initialURL.absoluteString.contains(InstanceIdOperator.instanceIDKey))
      XCTAssertTrue(mutatedURL.absoluteString.contains(InstanceIdOperator.instanceIDKey))
    }

    let totalExpectation = expectation(description: "Time Response Recieved")
    config.useInstanceId = true
    pubnub = PubNub(configuration: config, session: sessions.session)

    XCTAssertTrue(pubnub.configuration.useInstanceId)

    pubnub.time { _ in
      totalExpectation.fulfill()
    }
    expectations.append(totalExpectation)

    XCTAssertEqual(sessionExpector.expectations.count, 1)
    expectations.append(contentsOf: sessionExpector.expectations)

    wait(for: expectations, timeout: 1.0)
  }
}
