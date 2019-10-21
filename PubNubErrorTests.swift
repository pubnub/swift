//
//  PubNubErrorTests.swift
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

class PubNubErrorTests: XCTestCase {
  let error: PubNubError = PubNubError(reason: .badRequest)
  let reason: PubNubError.Reason = .badRequest

  let optionalError: PubNubError? = PubNubError(reason: .badRequest)
  let optionalReason: PubNubError.Reason? = .badRequest

  // MARK: Equatable

  func testErrorEquatable() {
    XCTAssertEqual(error, error)
  }

  func testErrorReasonEquatable() {
    XCTAssertEqual(reason, reason)
  }

  // MARK: Cross-Type Equatable

  func testErrorEqualToReason() {
    XCTAssertTrue(error == reason)
  }

  func testErrorNotEqualToReason() {
    XCTAssertFalse(error != reason)
  }

  func testErrorEqualToOptionalReason() {
    XCTAssertTrue(error == optionalReason)
  }

  func testErrorNotEqualToOptionalReason() {
    XCTAssertFalse(error != optionalReason)
  }

  func testOptionalErrorEqualToReason() {
    XCTAssertTrue(optionalError == reason)
  }

  func testOptionalErrorNotEqualToReason() {
    XCTAssertFalse(optionalError != reason)
  }

  func testOptionalErrorEqualToOptionalReason() {
    XCTAssertTrue(optionalError == optionalReason)
  }

  func testOptionalErrorNotEqualToOptionalReason() {
    XCTAssertFalse(optionalError != optionalReason)
  }

  func testReasonEqualToReason() {
    XCTAssertTrue(reason == error)
  }

  func testReasonNotEqualToReason() {
    XCTAssertFalse(reason != error)
  }

  func testReasonEqualToOptionalError() {
    XCTAssertTrue(reason == optionalError)
  }

  func testReasonNotEqualToOptionalError() {
    XCTAssertFalse(reason != optionalError)
  }

  func testOptionalReasonEqualToError() {
    XCTAssertTrue(optionalReason == error)
  }

  func testOptionalReasonNotEqualToError() {
    XCTAssertFalse(optionalReason != error)
  }

  func testOptionalReasonEqualToOptionalError() {
    XCTAssertTrue(optionalReason == optionalError)
  }

  func testOptionalReasonNotEqualToOptionalError() {
    XCTAssertFalse(optionalReason != optionalError)
  }
}
