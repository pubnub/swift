//
//  PublishEndpoint.swift
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

// MARK: - Response Decoder

struct PublishResponseDecoder: ResponseDecoder {
  func decode(response: Response<Data>) -> Result<Response<PublishResponsePayload>, Error> {
    do {
      // Publish Response pattern:  [Int, String, String]
      let decodedPayload = try Constant.jsonDecoder.decode(AnyJSON.self, from: response.payload).arrayOptional

      guard let timeString = decodedPayload?.last as? String, let timetoken = Int64(timeString) else {
        return .failure(PNError.endpointFailure(.malformedResponseBody,
                                                response.endpoint,
                                                response.request,
                                                response.response))
      }

      let decodedResponse = Response<PublishResponsePayload>(router: response.router,
                                                             request: response.request,
                                                             response: response.response,
                                                             data: response.data,
                                                             payload: PublishResponsePayload(timetoken: timetoken))

      return .success(decodedResponse)
    } catch {
      return .failure(PNError
        .endpointFailure(.jsonDataDecodeFailure(response.data, with: error),
                         response.endpoint,
                         response.request,
                         response.response))
    }
  }

  func decodeError(endpoint: Endpoint, request: URLRequest, response: HTTPURLResponse, for data: Data?) -> PNError? {
    guard let data = data else {
      return PNError.endpointFailure(.unknown(ErrorDescription.EndpointError.missingResponseData),
                                     endpoint,
                                     request,
                                     response)
    }

    // Publish Response pattern:  [Int, String, String]
    let decodedPayload = try? Constant.jsonDecoder.decode(AnyJSON.self, from: data).arrayOptional

    if let errorFlag = decodedPayload?.first as? Int, errorFlag == 0 {
      let errorPayload: GenericServicePayloadResponse
      if let message = decodedPayload?[1] as? String {
        errorPayload = GenericServicePayloadResponse(message: .init(rawValue: message),
                                                     service: .publish,
                                                     status: .init(rawValue: response.statusCode),
                                                     error: true)

      } else {
        errorPayload = GenericServicePayloadResponse(
          message: .unknown(message: ErrorDescription.EndpointError.publishResponseMessageParseFailure),
          service: .presence,
          status: .init(rawValue: response.statusCode),
          error: true
        )
      }

      return PNError.convert(endpoint: endpoint, generalError: errorPayload, request: request, response: response)
    }

    // Check if we were provided a default error from the server
    if let defaultError = decodeDefaultError(endpoint: endpoint, request: request, response: response, for: data) {
      return defaultError
    }

    return nil
  }
}

// MARK: - Response Body

public struct PublishResponsePayload: Codable, Hashable {
  public let timetoken: Timetoken
}

public struct ErrorResponse: Codable, Hashable {
  public let message: String?
  public let error: Bool
  public let service: String?
  public let status: Int
}
