//
//  ErrorDescription.swift
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

import Foundation

public struct ErrorDescription {
  public static let defaultFailureReason: String = {
    "No failure reason was provied."
  }()

  public static let defaultRecoverySuggestion: String = {
    "No recover suggestion was provided."
  }()

  public struct AnyJSONError {
    public static let stringCreationFailure: String = {
      "`String(data:encoding:)` returned nil when converting JSON Data to a `String`"
    }()
  }

  struct DecodingError {
    public static let invalidRootLevelErrorDescription: String = {
      "AnyJSON could not decode invalid root-level JSON object"
    }()

    public static let invalidKeyedContainerErrorDescription: String = {
      "AnyJSON could not decode value inside `KeyedDecodingContainer`"
    }()

    public static let invalidUnkeyedContainerErrorDescription: String = {
      "AnyJSON could not decode value inside `UnkeyedDecodingContainer`"
    }()
  }

  struct EncodingError {
    public static let invalidRootLevelErrorDescription: String = {
      "AnyJSON could not encode invalid root-level JSON object"
    }()

    public static let invalidKeyedContainerErrorDescription: String = {
      "AnyJSON could not encode value inside `KeyedEncodingContainer`"
    }()

    public static let invalidUnkeyedContainerErrorDescription: String = {
      "AnyJSON could not encode value inside `UnkeyedEncodingContainer`"
    }()
  }

  struct EndpointError {
    public static let publishResponseMessageParseFailure: String = {
      "Unable to parse publish payload message"
    }()

    public static let missingResponseData: String = {
      "Missing Response Data"
    }()
  }

  struct PNError {
    public static let unknown: String = {
      "Unknown Error: An unknown error occurred with the supplied message:"
    }()

    public static let unknownError: String = {
      "Unknown Error: An unknown error occurred with the supplied error:"
    }()

    public static let sessionInvalidated: String = {
      "Session Invalidated: This Session's underlying `URLSession` was invalidated: "
    }()

    public static let sessionDeinitialized: String = {
      "Session Deinitialized: This `Session` was deinitialized while tasks were still executing."
    }()

    public static let requestRetryFailed: String = {
      "Request Retry Failed: Request reached max retry count with final error:"
    }()

    public static let requestCreationFailure: String = {
      "Request Creation Failed:"
    }()

    public static let requestTransmissionFailure: String = {
      "Transmission Failure:"
    }()

    public static let responseProcessingFailure: String = {
      "Response Failure:"
    }()

    public static let endpointFailure: String = {
      "Endpoint Error:"
    }()
  }

  struct UnknownErrorReason {
    public static let endpointErrorMissingResponse: String = {
      "EndpointError could not be created due to missing HTTPURLResponse"
    }()

    public static let noAppropriateEndpointError: String = {
      "Could not determine appropriate endpoint error"
    }()
  }

  struct RequestCreationFailureReason {
    public static let jsonStringCodingFailure: String = {
      "The JSON object could not be serialized into a `String`"
    }()

    public static let missingPublishKey: String = {
      "Required PubNub Publish key is missing"
    }()

    public static let missingSubscribeKey: String = {
      "Required PubNub Subscribe key is missing"
    }()

    public static let missingPublishAndSubscribeKey: String = {
      "Required PubNub Publish & Subscribe keys are missing"
    }()

    public static let unknown: String = {
      "An unknown error occured"
    }()

    public static let jsonDataCodingFailure: String = {
      "The JSON object could be serialized into a `Data` object."
    }()

    public static let requestMutatorFailure: String = {
      "The request mutation failed resulting in an error"
    }()
  }

  struct EndpointFailureReason {
    public static let malformedResponseBody: String = {
      "Unable to decode the response body"
    }()

    public static let jsonDataDecodeFailure: String = {
      "An error was thrown attempting to decode the response body"
    }()

    public static let invalidCharacter: String = {
      "The request sent contained one or more reserved characters"
    }()

    public static let invalidDeviceToken: String = {
      "The provided device token is not a valid push token"
    }()

    public static let maxChannelGroupCountExceeded: String = {
      "The maximum number of channel groups has been reached"
    }()

    public static let invalidSubscribeKey: String = {
      "The PubNub Subscribe key used for the request is invalid"
    }()

    public static let invalidPublishKey: String = {
      "The PubNub Publish key used for the request is invalid"
    }()

    public static let requestContainedInvalidJSON: String = {
      "The request contained a malformed JSON payload"
    }()

    public static let serviceUnavailable: String = {
      "The service is currently unavailable"
    }()

    public static let couldNotParseRequest: String = {
      "The PubNub server was unable to parse the request"
    }()

    public static let pushNotEnabled: String = {
      "Use of the mobile push notifications API requires Push Notifications which is not enabled for this subscribe key"
    }()

    public static let badRequest: String = {
      "Bad request on that endpoint"
    }()

    public static let unauthorized: String = {
      "Access was denied due to insufficient authorization"
    }()

    public static let forbidden: String = {
      "Operation forbidden on that endpoint"
    }()

    public static let resourceNotFound: String = {
      "Resource not found at that endpoint"
    }()

    public static let requestURITooLong: String = {
      "URI of the request was too long to be processed"
    }()

    public static let malformedFilterExpression: String = {
      "The supplied filter expression was malformed"
    }()

    public static let internalServiceError: String = {
      "The server encountered an unforseen error while processing the request"
    }()

    public static let unrecognizedErrorPayload: String = {
      "A payload not matching any known reason was received"
    }()

    public static let unknown: String = {
      "Unknown Reason"
    }()
  }

  struct SessionInvalidationReason {
    public static let explicit: String = {
      "Explicitly"
    }()

    public static let implicit: String = {
      "Implicitly"
    }()
  }
}
