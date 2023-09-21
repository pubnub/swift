//
//  CryptorHeader.swift
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

private let sentinel = "PNED"

enum CryptorHeader: Equatable {
  case none
  case v1(cryptorId: CryptorId, data: Data)
      
  func length() -> Int {
    asData().count
  }
  
  func metadataIfAny() -> Data {
    switch self {
    case .none:
      return Data()
    case .v1(_, let data):
      return data
    }
  }
  
  func cryptorId() -> CryptorId {
    switch self {
    case .none:
      return LegacyCryptor.legacyCryptorId
    case .v1(let cryptorId, _):
      return cryptorId
    }
  }
  
  func asData() -> Data {
    guard case .v1(let cryptorId, let data) = self else {
      return Data()
    }
    var finalData = sentinel.data(using: .ascii) ?? Data()
    finalData += Data(bytes: [1], count: 1)
    finalData += Data(bytes: cryptorId, count: cryptorId.count)
    
    if data.count < 255 {
      finalData += Data(bytes: [data.count], count: 1)
      finalData += data
    } else {
      finalData += Data(bytes: [0xFF, data.count & 0xFF, data.count >> 8], count: 3)
      finalData += data
    }
    return finalData
  }
  
  static func from(data: Data) throws -> Self {
    try CryptorHeaderParser(data: data).parse()
  }
}

fileprivate class CryptorHeaderDataScanner {
  private var nextIndex: Int = 0
  private let data: Data
  
  init(data: Data) {
    self.data = data
  }
    
  func nextBytes(_ count: Int) -> Data? {
    let previousValue = nextIndex
    let newValue = nextIndex + count
    
    guard newValue <= data.count else { return nil }
    nextIndex = newValue
    
    return data.subdata(in: previousValue..<newValue)
  }
  
  func nextByte() -> UInt8? {
    nextBytes(1)?.first
  }
  
  func bytesRead() -> Data {
    data.suffix(nextIndex)
  }
}

struct CryptorHeaderParser {
  private let scanner: CryptorHeaderDataScanner
  
  init(data: Data) {
    self.scanner = CryptorHeaderDataScanner(data: data)
  }
  
  func parseAndReturnProcessedBytes() throws -> (header: CryptorHeader, bytesProcessed: Data) {
    return (header: try parse(), bytesProcessed: scanner.bytesRead())
  }
  
  func parse() throws -> CryptorHeader {
    guard let possibleSentinelBytes = scanner.nextBytes(4) else {
      return .none
    }
    guard let sentinelString = String(data: possibleSentinelBytes, encoding: .ascii) else {
      return .none
    }
    guard sentinelString == sentinel else {
      return .none
    }
    guard let headerVersion = scanner.nextByte() else {
      throw PubNubError(.unknownCryptorError, additional: ["Cannot find Crypto header version"])
    }
    guard (1...1).contains(headerVersion) else {
      throw PubNubError(.unknownCryptorError, additional: ["Invalid Crypto header version \(headerVersion)"])
    }
    guard let cryptorId = scanner.nextBytes(4) else {
      throw PubNubError(.unknownCryptorError, additional: ["Cannot find Cryptor identifier"])
    }
    guard let cryptorDataSize = scanner.nextByte() else {
      throw PubNubError(.unknownCryptorError, additional: ["Cannot read Cryptor data size"])
    }
    guard let cryptorDefinedData = scanner.nextBytes(Int(try computeCryptorDataSize(with: cryptorDataSize))) else {
      throw PubNubError(.unknownCryptorError, additional: ["Cannot retrieve Cryptor defined data"])
    }
    return .v1(cryptorId: cryptorId.map { $0 }, data: cryptorDefinedData)
  }
  
  private func computeCryptorDataSize(with sizeIndicator: UInt8) throws -> UInt16 {
    if sizeIndicator < UInt8.max {
      return UInt16(sizeIndicator)
    }
    guard let nextBytes = scanner.nextBytes(2) else {
      throw PubNubError(.unknownCryptorError, additional: ["Cannot read next Cryptor data size bytes"])
    }
    return nextBytes.withUnsafeBytes {
      $0.load(as: UInt16.self)
    }
  }
}
