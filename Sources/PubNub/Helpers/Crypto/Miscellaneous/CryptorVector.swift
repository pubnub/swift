//
//  CryptorVector.swift
//
//  Copyright (c) PubNub Inc.
//  All rights reserved.
//
//  This source code is licensed under the license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import CommonCrypto

enum CryptorVector {
  case fixed
  case random(bytesCount: Int)
  
  func data() throws -> Data {
    switch self {
    case .fixed:
      return try staticInitializationVector()
    case .random(let byteCount):
      return try randomInitializationVector(with: byteCount)
    }
  }
  
  func isFixed() -> Bool {
    if case .fixed = self {
      return true
    } else {
      return false
    }
  }
  
  func isRandom() -> Bool {
    if case .random(_) = self {
      return true
    } else {
      return false
    }
  }
  
  private func staticInitializationVector() throws -> Data {
    guard let initializationVector = "0123456789012345".data(using: .utf8) else {
      throw CryptoError.rngFailure
    }
    return initializationVector
  }
  
  private func randomInitializationVector(with byteCount: Int) throws -> Data {
    var bytes: [UInt8] = Array(repeating: UInt8(0), count: byteCount)
    let status = CCRandomGenerateBytes(&bytes, byteCount)

    if status == kCCSuccess {
      return Data(bytes: bytes, count: byteCount)
    } else {
      throw CryptoError(from: status)
    }
  }
}
