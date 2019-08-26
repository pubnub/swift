//
//  PNError+EquatableTests.swift
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

// swiftlint:disable:next type_body_length
class PNErrorEquatableTests: XCTestCase {
  let underlyingError = PNError.unknown("Uknown", .time)
  let unknownPNError = PNError.unknown("Unknown Error Message", .time)

  func testPNError_Unknown() {
    let testCase = PNError.unknown("Error Message", .time)
    XCTAssertEqual(testCase, PNError.unknown("Error Message", .time))
    XCTAssertNotEqual(testCase, PNError.unknown("Another Message", .time))
  }

  func testPNError_UnknownError() {
    let testCase = PNError.unknownError(URLError(.timedOut), .time)
    XCTAssertEqual(testCase, PNError.unknownError(URLError(.timedOut), .time))
    XCTAssertNotEqual(testCase, PNError.unknownError(URLError(.badURL), .time))
  }

  func testPNError_MissingRequiredParameter() {
    let testCase = PNError.missingRequiredParameter(.time)
    XCTAssertEqual(testCase, PNError.missingRequiredParameter(.time))
    XCTAssertNotEqual(testCase, PNError.messageCountExceededMaximum(.time))
  }

  func testPNError_MessageCountExceededMaximum() {
    let testCase = PNError.messageCountExceededMaximum(.time)
    XCTAssertEqual(testCase, PNError.messageCountExceededMaximum(.time))
    XCTAssertNotEqual(testCase, PNError.missingRequiredParameter(.time))
  }

  func testPNError_InvalidEndpointType() {
    let testCase = PNError.invalidEndpointType(.time)
    XCTAssertEqual(testCase, PNError.invalidEndpointType(.time))
    XCTAssertNotEqual(testCase, PNError.missingRequiredParameter(.time))
  }

  func testPNError_SessionDeinitialized() {
    let testUUID = UUID()
    let testCase = PNError.sessionDeinitialized(sessionID: testUUID)
    XCTAssertEqual(testCase, PNError.sessionDeinitialized(sessionID: testUUID))
    XCTAssertNotEqual(testCase, PNError.sessionDeinitialized(sessionID: UUID()))
  }

  func testPNError_RequestRetryFailed() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testPerviousError = PNError.unknown("New Error", .time)

    let testCase = PNError.requestRetryFailed(.time, testRequest,
                                              dueTo: underlyingError,
                                              withPreviousError: testPerviousError)
    XCTAssertEqual(testCase, PNError.requestRetryFailed(.time, testRequest,
                                                        dueTo: underlyingError,
                                                        withPreviousError: testPerviousError))
    // Mismatch Error
    XCTAssertNotEqual(testCase, PNError.requestRetryFailed(.time, testRequest,
                                                           dueTo: testPerviousError,
                                                           withPreviousError: testPerviousError))
    // Mismatch Previous Error
    XCTAssertNotEqual(testCase, PNError.requestRetryFailed(.time, testRequest,
                                                           dueTo: underlyingError,
                                                           withPreviousError: underlyingError))
  }

  // MARK: RequestCreationFailureReason

  func testPNError_RequestCreationFailure_JSONStringCodingFailure() {
    let reason = PNError.RequestCreationFailureReason
      .jsonStringCodingFailure([], dueTo: underlyingError)
    let testCase = PNError.requestCreationFailure(reason, .time)
    XCTAssertEqual(testCase, PNError.requestCreationFailure(reason, .time))
    XCTAssertNotEqual(testCase, PNError.missingRequiredParameter(.time))
  }

  func testPNError_RequestCreationFailure_MissingPublishKey() {
    let reason = PNError.RequestCreationFailureReason.missingPublishKey
    let testCase = PNError.requestCreationFailure(reason, .time)
    XCTAssertEqual(testCase, PNError.requestCreationFailure(reason, .time))
    XCTAssertNotEqual(testCase, PNError.missingRequiredParameter(.time))
  }

  func testPNError_RequestCreationFailure_MissingSubscribeKey() {
    let reason = PNError.RequestCreationFailureReason.missingSubscribeKey
    let testCase = PNError.requestCreationFailure(reason, .time)
    XCTAssertEqual(testCase, PNError.requestCreationFailure(reason, .time))
    XCTAssertNotEqual(testCase, PNError.missingRequiredParameter(.time))
  }

  func testPNError_RequestCreationFailure_MissingPublishAndSubscribeKey() {
    let reason = PNError.RequestCreationFailureReason.missingPublishAndSubscribeKey
    let testCase = PNError.requestCreationFailure(reason, .time)
    XCTAssertEqual(testCase, PNError.requestCreationFailure(reason, .time))
    XCTAssertNotEqual(testCase, PNError.missingRequiredParameter(.time))
  }

  func testPNError_RequestCreationFailure_Unknown() {
    let reason = PNError.RequestCreationFailureReason.unknown(underlyingError)
    let testCase = PNError.requestCreationFailure(reason, .time)
    XCTAssertEqual(testCase, PNError.requestCreationFailure(reason, .time))
    XCTAssertNotEqual(testCase, PNError.missingRequiredParameter(.time))
  }

  func testPNError_RequestCreationFailure_JSONDataCodingFailure() {
    let reason = PNError.RequestCreationFailureReason
      .jsonDataCodingFailure([], with: underlyingError)
    let testCase = PNError.requestCreationFailure(reason, .time)
    XCTAssertEqual(testCase, PNError.requestCreationFailure(reason, .time))
    XCTAssertNotEqual(testCase, PNError.missingRequiredParameter(.time))
  }

  func testPNError_RequestCreationFailure_RequestMutatorFailure() {
    guard let testURL = URL(string: "http://example.com"),
      let variableURL = URL(string: "http://not-example.com") else {
      return XCTFail("Could not create URLs")
    }

    let testRequest = URLRequest(url: testURL)
    let variableRequest = URLRequest(url: variableURL)
    let testReason = PNError.RequestCreationFailureReason
      .requestMutatorFailure(testRequest, underlyingError)
    let variableReason = PNError.RequestCreationFailureReason
      .requestMutatorFailure(variableRequest, underlyingError)
    let testCase = PNError.requestCreationFailure(testReason, .time)
    XCTAssertEqual(testCase, PNError.requestCreationFailure(testReason, .time))
    XCTAssertNotEqual(testCase, PNError.requestCreationFailure(variableReason, .time))
  }

  func testPNError_RequestCreationFailure_MismatchReasons() {
    XCTAssertNotEqual(PNError.requestCreationFailure(.missingPublishKey, .time),
                      PNError.requestCreationFailure(.missingSubscribeKey, .time))
  }

  // MARK: - RequestTransmissionFailure

  func testPNError_RequestTransmissionFailure_Unknown() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.RequestTransmissionFailureReason.unknown(URLError(.unknown))
    let testCase = PNError.requestTransmissionFailure(reason, .time, testRequest)
    XCTAssertEqual(testCase, PNError.requestTransmissionFailure(reason, .time, testRequest))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_RequestTransmissionFailure_Cancelled() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.RequestTransmissionFailureReason.cancelled(URLError(.cancelled))
    let testCase = PNError.requestTransmissionFailure(reason, .time, testRequest)
    XCTAssertEqual(testCase, PNError.requestTransmissionFailure(reason, .time, testRequest))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_RequestTransmissionFailure_TimedOut() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.RequestTransmissionFailureReason.timedOut(URLError(.timedOut))
    let testCase = PNError.requestTransmissionFailure(reason, .time, testRequest)
    XCTAssertEqual(testCase, PNError.requestTransmissionFailure(reason, .time, testRequest))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_RequestTransmissionFailure_NameResolutionFailure() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.RequestTransmissionFailureReason
      .nameResolutionFailure(URLError(.dnsLookupFailed))
    let testCase = PNError.requestTransmissionFailure(reason, .time, testRequest)
    XCTAssertEqual(testCase, PNError.requestTransmissionFailure(reason, .time, testRequest))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_RequestTransmissionFailure_InvalidURL() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.RequestTransmissionFailureReason.invalidURL(URLError(.badURL))
    let testCase = PNError.requestTransmissionFailure(reason, .time, testRequest)
    XCTAssertEqual(testCase, PNError.requestTransmissionFailure(reason, .time, testRequest))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_RequestTransmissionFailure_ConnectionFailure() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.RequestTransmissionFailureReason
      .connectionFailure(URLError(.cannotConnectToHost))
    let testCase = PNError.requestTransmissionFailure(reason, .time, testRequest)
    XCTAssertEqual(testCase, PNError.requestTransmissionFailure(reason, .time, testRequest))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_RequestTransmissionFailure_ConnectionOverDataFailure() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.RequestTransmissionFailureReason
      .connectionOverDataFailure(URLError(.dataNotAllowed))
    let testCase = PNError.requestTransmissionFailure(reason, .time, testRequest)
    XCTAssertEqual(testCase, PNError.requestTransmissionFailure(reason, .time, testRequest))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_RequestTransmissionFailure_ConnectionLost() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.RequestTransmissionFailureReason
      .connectionLost(URLError(.networkConnectionLost))
    let testCase = PNError.requestTransmissionFailure(reason, .time, testRequest)
    XCTAssertEqual(testCase, PNError.requestTransmissionFailure(reason, .time, testRequest))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_RequestTransmissionFailure_SecureConnectionFailure() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.RequestTransmissionFailureReason
      .secureConnectionFailure(URLError(.secureConnectionFailed))
    let testCase = PNError.requestTransmissionFailure(reason, .time, testRequest)
    XCTAssertEqual(testCase, PNError.requestTransmissionFailure(reason, .time, testRequest))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_RequestTransmissionFailure_SecureTrustFailure() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.RequestTransmissionFailureReason
      .secureTrustFailure(URLError(.serverCertificateUntrusted))
    let testCase = PNError.requestTransmissionFailure(reason, .time, testRequest)
    XCTAssertEqual(testCase, PNError.requestTransmissionFailure(reason, .time, testRequest))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_RequestTransmissionFailure_MismatchReasons() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.RequestTransmissionFailureReason
      .secureTrustFailure(URLError(.serverCertificateUntrusted))
    let mismatchReason = PNError.RequestTransmissionFailureReason
      .secureConnectionFailure(URLError(.secureConnectionFailed))

    let testCase = PNError.requestTransmissionFailure(reason, .time, testRequest)
    let mismatchTestCase = PNError.requestTransmissionFailure(mismatchReason, .time, testRequest)
    XCTAssertNotEqual(testCase, mismatchTestCase)
  }

  // MARK: - ResponseProcessingFailureReason

  func testPNError_ResponseProcessingFailure_ReceiveFailure() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.ResponseProcessingFailureReason.receiveFailure(URLError(.badServerResponse))

    let testCase = PNError.responseProcessingFailure(reason, .time, testRequest, nil)
    XCTAssertEqual(testCase, PNError.responseProcessingFailure(reason, .time, testRequest, nil))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_ResponseProcessingFailure_ResponseDecodingFailure() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.ResponseProcessingFailureReason.responseDecodingFailure(URLError(.cannotParseResponse))

    let testCase = PNError.responseProcessingFailure(reason, .time, testRequest, nil)
    XCTAssertEqual(testCase, PNError.responseProcessingFailure(reason, .time, testRequest, nil))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_ResponseProcessingFailure_DataLengthExceedsMaximum() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.ResponseProcessingFailureReason.dataLengthExceedsMaximum(URLError(.dataLengthExceedsMaximum))

    let testCase = PNError.responseProcessingFailure(reason, .time, testRequest, nil)
    XCTAssertEqual(testCase, PNError.responseProcessingFailure(reason, .time, testRequest, nil))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_ResponseProcessingFailure_MismatchReasons() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)

    let reason = PNError.ResponseProcessingFailureReason
      .dataLengthExceedsMaximum(URLError(.dataLengthExceedsMaximum))
    let mismatchReason = PNError.ResponseProcessingFailureReason
      .responseDecodingFailure(URLError(.cannotParseResponse))

    let testCase = PNError.responseProcessingFailure(reason, .time, testRequest, nil)
    let mismatchTestCase = PNError.responseProcessingFailure(mismatchReason, .time, testRequest, nil)
    XCTAssertNotEqual(testCase, mismatchTestCase)
  }

  // MARK: - EndpointFailureReason

  func testPNError_EndpointFailure_MalformedResponseBody() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.malformedResponseBody
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_JSONDataDecodeFailure() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.jsonDataDecodeFailure(nil, with: underlyingError)
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_InvalidArguments() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.invalidArguments
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_InvalidCharacter() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.invalidCharacter
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_InvalidDeviceToken() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.invalidDeviceToken
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_InvalidSubscribeKey() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.invalidSubscribeKey
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_InvalidPublishKey() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.invalidPublishKey
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_MaxChannelGroupCountExceeded() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.maxChannelGroupCountExceeded
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_MessageHistoryNotEnabled() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.messageHistoryNotEnabled
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_MessageDeletionNotEnabled() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.messageDeletionNotEnabled
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_PushNotEnabled() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.pushNotEnabled
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_RequestContainedInvalidJSON() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.requestContainedInvalidJSON
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_ServiceUnavailable() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.serviceUnavailable
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_CouldNotParseRequest() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.couldNotParseRequest
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_BadRequest() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.badRequest
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_Unauthorized() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.unauthorized
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_Forbidden() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.forbidden
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_ResourceNotFound() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.resourceNotFound
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_RequestURITooLong() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.requestURITooLong
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_UnrecognizedErrorPayload() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let payload = GenericServicePayloadResponse(message: .acknowledge,
                                                service: .balancer,
                                                status: .acknowledge,
                                                error: true,
                                                channels: [:])

    let reason = PNError.EndpointFailureReason.unrecognizedErrorPayload(payload)
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_MalformedFilterExpression() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.malformedFilterExpression
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_InternalServiceError() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.internalServiceError
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_Unknown() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.unknown("Test Error")
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)
    XCTAssertEqual(testCase, PNError.endpointFailure(reason, .time, testRequest, testResponse))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_EndpointFailure_MismatchReason() {
    guard let testURL = URL(string: "http://example.com") else {
      return XCTFail("Could not create URLs")
    }
    let testRequest = URLRequest(url: testURL)
    let testResponse = HTTPURLResponse(url: testURL, mimeType: nil,
                                       expectedContentLength: 500, textEncodingName: nil)

    let reason = PNError.EndpointFailureReason.unknown("Test Error")
    let testCase = PNError.endpointFailure(reason, .time, testRequest, testResponse)

    XCTAssertNotEqual(testCase, PNError.endpointFailure(.badRequest, .time, testRequest, testResponse))
  }

  // MARK: - SessionInvalidationReason

  func testPNError_SessionInvalidated_Explicit() {
    let testCase = PNError.sessionInvalidated(.explicit, sessionID: nil)
    XCTAssertEqual(testCase, PNError.sessionInvalidated(.explicit, sessionID: nil))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_SessionInvalidated_Implicit() {
    let reason = PNError.SessionInvalidationReason.implicit(dueTo: underlyingError)

    let testCase = PNError.sessionInvalidated(reason, sessionID: nil)
    XCTAssertEqual(testCase, PNError.sessionInvalidated(reason, sessionID: nil))
    XCTAssertNotEqual(testCase, unknownPNError)
  }

  func testPNError_SessionInvalidated_MismatchReason() {
    let reason = PNError.SessionInvalidationReason.implicit(dueTo: underlyingError)

    let testCase = PNError.sessionInvalidated(reason, sessionID: nil)
    XCTAssertNotEqual(testCase, PNError.sessionInvalidated(.explicit, sessionID: nil))
  }
}

// swiftlint:disable:this file_length
