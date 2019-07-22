//
//  SubscribeEndpoint.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  http://www.pubnub.com/
//  http://www.pubnub.com/terms
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

struct SubscribeResponseDecoder: ResponseDecoder {
  func decode(response: Response<Data>, completion: (Result<Response<SubscriptionResponsePayload>, Error>) -> Void) {
    do {
      let decodedPayload = try JSONDecoder().decode(SubscriptionResponsePayload.self, from: response.payload)

      let decodedResponse = Response<SubscriptionResponsePayload>(router: response.router,
                                                                  request: response.request,
                                                                  response: response.response,
                                                                  data: response.data,
                                                                  payload: decodedPayload)

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

struct SubscriptionResponsePayload: Codable, Hashable {
  // Root Level
  let token: TimetokenResponse
  let messages: [MessageResponse]

  enum CodingKeys: String, CodingKey {
    case token = "t"
    case messages = "m"
  }
}

struct TimetokenResponse: Codable, Hashable {
  let tokenString: String
  let region: Int

  enum CodingKeys: String, CodingKey {
    case tokenString = "t"
    case region = "r"
  }
}

extension TimetokenResponse {
  var timetoken: Int? {
    return Int(tokenString)
  }
}

struct MessageResponse: Codable, Hashable {
  let shard: String
  let subscriptionMatch: String?
  let channel: String
  let payload: AnyJSON
  let flags: Int
  let issuer: String
  let subscribeKey: String
  let originTimetoken: TimetokenResponse?
  let publishTimetoken: TimetokenResponse
  let metadata: AnyJSON?

  enum CodingKeys: String, CodingKey {
    case shard = "a"
    case subscriptionMatch = "b"
    case channel = "c"
    case payload = "d"
    case flags = "f"
    case issuer = "i"
    case subscribeKey = "k"
    case originTimetoken = "o"
    case publishTimetoken = "p"
    case metadata = "u"
  }
}
