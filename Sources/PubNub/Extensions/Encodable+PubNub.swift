//
//  Encodable+PubNub.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
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
