//
//  Session+URLError.swift
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

final class SessionURLErrorTests: XCTestCase {
  let testBundle = Bundle(for: PubNubTests.self)
  var pubnub: PubNub!

  func testURLError(code: URLError.Code, for resource: String) {
    let expectation = self.expectation(description: "URLError \(resource) Expectation")

    guard let sessions = try? MockURLSession.mockSession(for: [resource]) else {
      return XCTFail("Could not create mock url session")
    }

    pubnub = PubNub(configuration: .default, session: sessions.session)
    pubnub.time { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError,
                       PubNubError(URLError(code).pubnubReason ?? .unknown))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // Unknown
  func testUnknown() {
    testURLError(code: .unknown, for: "unknown")
  }

  // Cancelled
  func testCancelled() {
    testURLError(code: .cancelled, for: "cancelled")
  }

  // Timed Out
  func testTimedOut() {
    testURLError(code: .timedOut, for: "timedOut")
  }

  // Name Resolution Failure
  func testCannotFindHost() {
    testURLError(code: .cannotFindHost, for: "cannotFindHost")
  }

  func testDnsLookupFailed() {
    testURLError(code: .dnsLookupFailed, for: "dnsLookupFailed")
  }

  // Invalid URL Issues
  func testBadURL() {
    testURLError(code: .badURL, for: "badURL")
  }

  func testUnsupportedURL() {
    testURLError(code: .unsupportedURL, for: "unsupportedURL")
  }

  // Connection Issues
  func testCannotConnectToHost() {
    testURLError(code: .cannotConnectToHost, for: "cannotConnectToHost")
  }

  func testResourceUnavailable() {
    testURLError(code: .resourceUnavailable, for: "resourceUnavailable")
  }

  func testNotConnectedToInternet() {
    testURLError(code: .notConnectedToInternet, for: "notConnectedToInternet")
  }

  // SIM Related
  func testInternationalRoamingOff() {
    testURLError(code: .internationalRoamingOff, for: "internationalRoamingOff")
  }

  func testCallIsActive() {
    testURLError(code: .callIsActive, for: "callIsActive")
  }

  func testDataNotAllowed() {
    testURLError(code: .dataNotAllowed, for: "dataNotAllowed")
  }

  // Connection Closed
  func testNetworkConnectionLost() {
    testURLError(code: .networkConnectionLost, for: "networkConnectionLost")
  }

  // Secure Connection Failure
  func testSecureConnectionFailed() {
    testURLError(code: .secureConnectionFailed, for: "secureConnectionFailed")
  }

  // Certificate Trust Failure
  func testServerCertificateHasBadDate() {
    testURLError(code: .serverCertificateHasBadDate, for: "serverCertificateHasBadDate")
  }

  func testServerCertificateUntrusted() {
    testURLError(code: .serverCertificateUntrusted, for: "serverCertificateUntrusted")
  }

  func testServerCertificateHasUnknownRoot() {
    testURLError(code: .serverCertificateHasUnknownRoot, for: "serverCertificateHasUnknownRoot")
  }

  func testServerCertificateNotYetValid() {
    testURLError(code: .serverCertificateNotYetValid, for: "serverCertificateNotYetValid")
  }

  func testClientCertificateRejected() {
    testURLError(code: .clientCertificateRejected, for: "clientCertificateRejected")
  }

  func testClientCertificateRequired() {
    testURLError(code: .clientCertificateRequired, for: "clientCertificateRequired")
  }

  func testAppTransportSecurityRequiresSecureConnection() {
    if #available(iOS 9.0, macOS 10.11, *) {
      testURLError(code: .appTransportSecurityRequiresSecureConnection,
                   for: "appTransportSecurityRequiresSecureConnection")
    }
  }

  // Receive Failure
  func testBadServerResponse() {
    testURLError(code: .badServerResponse, for: "badServerResponse")
  }

  func testZeroByteResource() {
    testURLError(code: .zeroByteResource, for: "zeroByteResource")
  }

  // Response Decoding Failure
  func testCannotDecodeRawData() {
    testURLError(code: .cannotDecodeRawData, for: "cannotDecodeRawData")
  }

  func testCannotDecodeContentData() {
    testURLError(code: .cannotDecodeContentData, for: "cannotDecodeContentData")
  }

  func testCannotParseResponse() {
    testURLError(code: .cannotParseResponse, for: "cannotParseResponse")
  }

  // Data Length Exceeded
  func testDataLengthExceedsMaximum() {
    testURLError(code: .dataLengthExceedsMaximum, for: "dataLengthExceedsMaximum")
  }
}
