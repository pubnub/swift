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
  func decode(response: Response<Data>, completion: (Result<Response<PublishResponsePayload>, Error>) -> Void) {
    do {
      let decodedPayload = try JSONDecoder().decode([AnyJSON].self, from: response.payload)

      if let errorFlag = decodedPayload.first?.value as? Int, errorFlag == 0 {
//        completion(.failure())
      }

      guard let timeString = decodedPayload.last?.value as? String, let timetoken = Int(timeString) else {
        throw PNError.endpointFailure(.malformedResponseBody,
                                      forRequest: response.request,
                                      onResponse: response.response)
      }

      let decodedResponse = Response<PublishResponsePayload>(router: response.router,
                                                             request: response.request,
                                                             response: response.response,
                                                             data: response.data,
                                                             payload: PublishResponsePayload(timetoken: timetoken))

      completion(.success(decodedResponse))
    } catch {
      completion(.failure(PNError
          .endpointFailure(.jsonDataDecodeFailure(response.data, with: error),
                           forRequest: response.request,
                           onResponse: response.response)))
    }
  }
}

// MARK: - Response Body

public struct PublishResponsePayload: Codable, Hashable {
  let timetoken: Int
}

public struct ErrorResponse: Codable, Hashable {
  var message: String?
  var error: Bool
  var service: String?
  var status: Int
}
