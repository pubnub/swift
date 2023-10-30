//
//  Session+URLErrorTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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

    let conig = PubNubConfiguration(publishKey: nil, subscribeKey: "", userId: UUID().uuidString)

    pubnub = PubNub(configuration: conig, session: sessions.session)
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
