//
//  Session+URLErrorTests.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import XCTest
@testable import PubNubSDK

final class SessionURLErrorTests: XCTestCase {
  let testBundle = Bundle(for: PubNubTests.self)

  func testURLError(code: URLError.Code, for resource: String) throws {
    let expectation = self.expectation(description: "URLError \(resource) Expectation")
    let sessions = try MockURLSession.mockSession(for: [resource])
    let pubnub = TestPubNubFactory.make(publishKey: nil, subscribeKey: "", session: sessions.session)

    pubnub.time { result in
      switch result {
      case .success:
        XCTFail("Publish request should fail")
      case let .failure(error):
        XCTAssertNotNil(error.pubNubError)
        XCTAssertEqual(error.pubNubError, PubNubError(URLError(code).pubnubReason ?? .unknown))
      }
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  // Unknown
  func test_Session_URLErrorUnknown_ReturnsMappedPubNubError() throws {
    try testURLError(code: .unknown, for: "unknown")
  }

  // Cancelled
  func test_Session_URLErrorCancelled_ReturnsMappedPubNubError() throws {
    try testURLError(code: .cancelled, for: "cancelled")
  }

  // Timed Out
  func test_Session_URLErrorTimedOut_ReturnsMappedPubNubError() throws {
    try testURLError(code: .timedOut, for: "timedOut")
  }

  // Name Resolution Failure
  func test_Session_URLErrorCannotFindHost_ReturnsMappedPubNubError() throws {
    try testURLError(code: .cannotFindHost, for: "cannotFindHost")
  }

  func test_Session_URLErrorDnsLookupFailed_ReturnsMappedPubNubError() throws {
    try testURLError(code: .dnsLookupFailed, for: "dnsLookupFailed")
  }

  // Invalid URL Issues
  func test_Session_URLErrorBadURL_ReturnsMappedPubNubError() throws {
    try testURLError(code: .badURL, for: "badURL")
  }

  func test_Session_URLErrorUnsupportedURL_ReturnsMappedPubNubError() throws {
    try testURLError(code: .unsupportedURL, for: "unsupportedURL")
  }

  // Connection Issues
  func test_Session_URLErrorCannotConnectToHost_ReturnsMappedPubNubError() throws {
    try testURLError(code: .cannotConnectToHost, for: "cannotConnectToHost")
  }

  func test_Session_URLErrorResourceUnavailable_ReturnsMappedPubNubError() throws {
    try testURLError(code: .resourceUnavailable, for: "resourceUnavailable")
  }

  func test_Session_URLErrorNotConnectedToInternet_ReturnsMappedPubNubError() throws {
    try testURLError(code: .notConnectedToInternet, for: "notConnectedToInternet")
  }

  // SIM Related
  func test_Session_URLErrorInternationalRoamingOff_ReturnsMappedPubNubError() throws {
    try testURLError(code: .internationalRoamingOff, for: "internationalRoamingOff")
  }

  func test_Session_URLErrorCallIsActive_ReturnsMappedPubNubError() throws {
    try testURLError(code: .callIsActive, for: "callIsActive")
  }

  func test_Session_URLErrorDataNotAllowed_ReturnsMappedPubNubError() throws {
    try testURLError(code: .dataNotAllowed, for: "dataNotAllowed")
  }

  // Connection Closed
  func test_Session_URLErrorNetworkConnectionLost_ReturnsMappedPubNubError() throws {
    try testURLError(code: .networkConnectionLost, for: "networkConnectionLost")
  }

  // Secure Connection Failure
  func test_Session_URLErrorSecureConnectionFailed_ReturnsMappedPubNubError() throws {
    try testURLError(code: .secureConnectionFailed, for: "secureConnectionFailed")
  }

  // Certificate Trust Failure
  func test_Session_URLErrorServerCertificateHasBadDate_ReturnsMappedPubNubError() throws {
    try testURLError(code: .serverCertificateHasBadDate, for: "serverCertificateHasBadDate")
  }

  func test_Session_URLErrorServerCertificateUntrusted_ReturnsMappedPubNubError() throws {
    try testURLError(code: .serverCertificateUntrusted, for: "serverCertificateUntrusted")
  }

  func test_Session_URLErrorServerCertificateHasUnknownRoot_ReturnsMappedPubNubError() throws {
    try testURLError(code: .serverCertificateHasUnknownRoot, for: "serverCertificateHasUnknownRoot")
  }

  func test_Session_URLErrorServerCertificateNotYetValid_ReturnsMappedPubNubError() throws {
    try testURLError(code: .serverCertificateNotYetValid, for: "serverCertificateNotYetValid")
  }

  func test_Session_URLErrorClientCertificateRejected_ReturnsMappedPubNubError() throws {
    try testURLError(code: .clientCertificateRejected, for: "clientCertificateRejected")
  }

  func test_Session_URLErrorClientCertificateRequired_ReturnsMappedPubNubError() throws {
    try testURLError(code: .clientCertificateRequired, for: "clientCertificateRequired")
  }

  func test_Session_URLErrorAppTransportSecurity_ReturnsMappedPubNubError() throws {
    if #available(iOS 9.0, macOS 10.11, *) {
      try testURLError(code: .appTransportSecurityRequiresSecureConnection, for: "appTransportSecurityRequiresSecureConnection")
    }
  }

  // Receive Failure
  func test_Session_URLErrorBadServerResponse_ReturnsMappedPubNubError() throws {
    try testURLError(code: .badServerResponse, for: "badServerResponse")
  }

  func test_Session_URLErrorZeroByteResource_ReturnsMappedPubNubError() throws {
    try testURLError(code: .zeroByteResource, for: "zeroByteResource")
  }

  // Response Decoding Failure
  func test_Session_URLErrorCannotDecodeRawData_ReturnsMappedPubNubError() throws {
    try testURLError(code: .cannotDecodeRawData, for: "cannotDecodeRawData")
  }

  func test_Session_URLErrorCannotDecodeContentData_ReturnsMappedPubNubError() throws {
    try testURLError(code: .cannotDecodeContentData, for: "cannotDecodeContentData")
  }

  func test_Session_URLErrorCannotParseResponse_ReturnsMappedPubNubError() throws {
    try testURLError(code: .cannotParseResponse, for: "cannotParseResponse")
  }

  // Data Length Exceeded
  func test_Session_URLErrorDataLengthExceedsMaximum_ReturnsMappedPubNubError() throws {
    try testURLError(code: .dataLengthExceedsMaximum, for: "dataLengthExceedsMaximum")
  }
}
