//
//  CryptoIVVector.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2023 PubNub Inc.
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
