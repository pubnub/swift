//
//  Data+PubNub.swift
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

extension Encodable {
  func encode(from container: inout SingleValueEncodingContainer) throws {
    try container.encode(self)
  }

  func encode(from container: inout UnkeyedEncodingContainer) throws {
    try container.encode(self)
  }

  func encode<T>(from container: inout KeyedEncodingContainer<T>, using key: T) throws where T: CodingKey {
    try container.encode(self, forKey: key)
  }

  var encodableJSONData: Result<Data, Error> {
    do {
      return try .success(Constant.jsonEncoder.encode(self))
    } catch {
      return .failure(error)
    }
  }

  var encodableJSONString: Result<String, Error> {
    return encodableJSONData.flatMap { data -> Result<String, Error> in
      if let string = String(data: data, encoding: .utf8) {
        return .success(string)
      }
      return .failure(AnyJSONError.stringCreationFailure(nil))
    }
  }

  func encodableJSONRawType<T>() -> Result<T, Error> where T: Decodable {
    return encodableJSONData.flatMap { data -> Result<T, Error> in
      do {
        return try .success(Constant.jsonDecoder.decode(T.self, from: data))
      } catch {
        return .failure(error)
      }
    }
  }
}
