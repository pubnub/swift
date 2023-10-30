//
//  CryptorUtils.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import CommonCrypto

enum CryptorUtils {
  enum SHA256 {
    static func hash(from data: Data) -> Data {
      var hash = [UInt8](
        repeating: 0,
        count: Int(CC_SHA256_DIGEST_LENGTH)
      )
      data.withUnsafeBytes {
        _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
      }
      return Data(hash)
    }
  }  
  static func hexFrom(_ data: Data) -> String {
    let midpoint = data.count / 2
    return data[..<midpoint].map { String(format: "%02lX", UInt($0)) }.joined()
  }
}
