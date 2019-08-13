//
//  TimeEndpoint.swift
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

struct TimeResponseDecoder: ResponseDecoder {
  func decode(response: Response<Data>) -> Result<Response<TimeResponsePayload>, Error> {
    do {
      let decodedPayload = try Constant.jsonDecoder.decode([Int64].self, from: response.payload)

      guard let timetoken = decodedPayload.first else {
        return .failure(PNError.endpointFailure(.malformedResponseBody,
                                                response.endpoint,
                                                response.request,
                                                response.response))
      }

      let decodedResponse = Response<TimeResponsePayload>(router: response.router,
                                                          request: response.request,
                                                          response: response.response,
                                                          data: response.data,
                                                          payload: TimeResponsePayload(timetoken: timetoken))

      return .success(decodedResponse)
    } catch {
      return .failure(PNError
        .endpointFailure(.jsonDataDecodeFailure(response.data, with: error),
                         response.endpoint,
                         response.request,
                         response.response))
    }
  }
}

// MARK: - Response Body

public struct TimeResponsePayload: Codable, Hashable {
  public let timetoken: Timetoken
}
